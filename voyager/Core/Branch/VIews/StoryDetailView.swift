//
//  StoryDetailView.swift
//  voyager
//
//  Created by grapestree on 2024/10/6.
//

import SwiftUI
import Kingfisher

struct RoundedCorners: Shape {
    var radius: CGFloat = 20.0
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct StoryDetailView: View {
    @State var storyId: Int64
    @StateObject private var viewModel: StoryDetailViewModel
    @State private var isEditing: Bool = false
    @State public var story: Story
    @State private var showNewStoryRole = false
    @State var userId: Int64
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isUpdatingAvatar = false
    
    init(storyId: Int64, story: Story,userId: Int64) {
        self.storyId = storyId
        self.story = story
        self.userId = userId
        self._viewModel = StateObject(wrappedValue: StoryDetailViewModel(story: story, storyId: storyId, userId: userId))
    }
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 8) {
                    storyHeader
                    storyStats
                    Divider().background(Color.theme.divider)
                    //storyDetails
                    aiGenerationDetails
                    Divider().background(Color.theme.divider)
                    charactersList
                    participantsList
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("故事详情")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "保存" : "编辑") {
                    if isEditing {
                        viewModel.saveStory()
                    }
                    isEditing.toggle()
                }
                .font(.footnote)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            SingleImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                Task {
                    await uploadAvatar(image)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchStoryDetails()
            }
        }
    }
    
    private var storyHeader: some View {
        VStack(alignment: .center) {
            Button(action: {
                showImagePicker = true
            }) {
                KFImage(URL(string: convertImagetoSenceImage(url: viewModel.story?.storyInfo.avatar ?? "", scene: .content)))
                    .cacheMemoryOnly()
                    .fade(duration: 0.25)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.theme.border, lineWidth: 1)
                    )
                    .overlay(
                        isUpdatingAvatar ? 
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(width: 80, height: 80)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                        : nil
                    )
            }
            .disabled(isUpdatingAvatar)
            
            if isEditing {
                TextField("故事名称", text: Binding(
                    get: { story.storyInfo.title },
                    set: { story.storyInfo.title = $0 }
                ))
                .font(.subheadline)
                .padding(10)
                .background(Color(.systemGray5))
                .cornerRadius(5)
                .padding(.horizontal, 10)
            } else {
                Text(viewModel.story?.storyInfo.name ?? "")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            if let createdAt = viewModel.story?.storyInfo.ctime {
                Text("创建于: \(formatDate(timestamp: createdAt))")
                    .font(.subheadline)
                    .foregroundColor(Color.theme.secondaryText)
            }
        }
    }
    
    private var storyStats: some View {
        HStack {
            Stat(title: "likes", value: viewModel.likes)
            Stat(title: "followers", value: viewModel.followers)
            Stat(title: "boards", value: viewModel.boardsCount)
            Stat(title: "roles", value: viewModel.roleNum)
            Stat(title: "members", value: viewModel.members)
        }
    }
    
    private var storyDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group{
                if isEditing {
                    Text("故事描述")
                        .font(.headline)
                    TextField("故事描述", text: Binding(
                        get: { viewModel.story?.storyInfo.desc ?? "" },
                        set: { viewModel.story?.storyInfo.desc = $0 }
                    ))
                    .font(.subheadline)
                    .padding(14)
                    .background(Color(.systemGray5))
                    .cornerRadius(14)
                    
                    Text("故事背景")
                        .font(.headline)
                    TextField("故事背景", text: Binding(
                        get: { viewModel.story?.storyInfo.params.background ?? "" },
                        set: { viewModel.story?.storyInfo.params.background = $0 }
                    ))
                    .font(.subheadline)
                    .padding(14)
                    .background(Color(.systemGray5))
                    .cornerRadius(14)
                } else {
                    Text("故事描述")
                        .font(.headline)
                    Text(viewModel.story?.storyInfo.desc ?? "")
                        .padding(14)
                        .background(Color(.systemGray5))
                        .cornerRadius(14)
                    
                    Text("故事背景")
                        .font(.headline)
                    Text(viewModel.story?.storyInfo.params.background ?? "")
                        .padding(14)
                        .background(Color(.systemGray5))
                        .cornerRadius(14)
                }
            }
            Group{
                Toggle("是否AI生成描述", isOn: Binding(
                    get: { viewModel.story?.storyInfo.isAiGen ?? false },
                    set: { viewModel.story?.storyInfo.isAiGen = $0 }
                ))
                .disabled(!isEditing)
                .padding(.vertical)
            }
        }
    }
    
    private var aiGenerationDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 16) {
                NavigationLink(destination: StorySettingDetailView(
                    title: "故事简介",
                    content: Binding(
                        get: { viewModel.story?.storyInfo.desc ?? "" },
                        set: { viewModel.story?.storyInfo.desc = $0 }
                    ),
                    onSave: { newContent in
                        viewModel.story?.storyInfo.desc = newContent
                        viewModel.saveStory()
                    }
                )) {
                    SettingRow(title: "故事简介") {
                        let desc = viewModel.story?.storyInfo.desc ?? ""
                        Text(desc.isEmpty ? " " : desc)
                            .font(.footnote)
                            .foregroundColor(Color.theme.secondaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .padding(10)
                            .frame(minHeight: 24, alignment: .leading)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                    .foregroundColor(Color.theme.border)
                            )
                    }
                }
                NavigationLink(destination: StorySettingDetailView(
                    title: "故事背景",
                    content: Binding(
                        get: { viewModel.story?.storyInfo.params.background ?? "" },
                        set: { viewModel.story?.storyInfo.params.background = $0 }
                    ),
                    onSave: { newContent in
                        viewModel.story?.storyInfo.params.background = newContent
                        viewModel.saveStory()
                    }
                )) {
                    SettingRow(title: "故事背景") {
                        let bg = viewModel.story?.storyInfo.params.background ?? ""
                        Text(bg.isEmpty ? " " : bg)
                            .font(.footnote)
                            .foregroundColor(Color.theme.secondaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .padding(10)
                            .frame(minHeight: 24, alignment: .leading)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                    .foregroundColor(Color.theme.border)
                            )
                    }
                }
                SettingRow(title: "故事风格") {
                    StylePicker(selectedStyle: Binding(
                        get: { viewModel.storyStyle },
                        set: { viewModel.storyStyle = $0 }
                    ))
                    .frame(maxWidth: 320)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                SettingRow(title: "场景数量") {
                    SceneStepper(count: Binding(
                        get: { Int(viewModel.sceneCount) },
                        set: { viewModel.sceneCount = Int(Int32($0)) }
                    ))
                    .frame(maxWidth: 320)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .background(Color.theme.secondaryBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.theme.border, lineWidth: 1)
            )
        }
    }
    
    private var charactersList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("故事角色")
                    .font(.headline)
                    .foregroundColor(Color.theme.primaryText)
                Spacer()
                NavigationLink(destination: AllCharactersView(viewModel: viewModel)) {
                    Text("查看\(viewModel.characters!.count)名角色 >")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.tertiaryText)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(Array(viewModel.characters!.enumerated()), id: \.offset) { _, character in
                        VStack(spacing: 4) {
                            if character.role.characterAvatar.isEmpty {
                                KFImage(URL(string: convertImagetoSenceImage(url: character.role.characterAvatar, scene: .small)))
                                    .cacheMemoryOnly()
                                    .fade(duration: 0.25)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.theme.border, lineWidth: 0.5))
                            } else {
                                KFImage(URL(string: convertImagetoSenceImage(url: character.role.characterAvatar, scene: .small)))
                                    .cacheMemoryOnly()
                                    .fade(duration: 0.25)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.theme.border, lineWidth: 0.5))
                            }
                            
                            Text(character.role.characterName)
                                .font(.caption)
                                .foregroundColor(Color.theme.secondaryText)
                                .lineLimit(1)
                        }
                    }
                    
                    Button(action: {
                        showNewStoryRole = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "plus")
                                .foregroundColor(Color.theme.accent)
                                .frame(width: 50, height: 50)
                                .background(Color.theme.tertiaryBackground)
                                .clipShape(Circle())
                            Text("添加人物角色")
                                .font(.caption)
                                .foregroundColor(Color.theme.tertiaryText)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .sheet(isPresented: $showNewStoryRole) {
                NewStoryRole(
                    storyId: (viewModel.story?.storyInfo.id)!,
                    userId: self.userId,
                    viewModel: viewModel
                )
            }
        }
    }

    private var participantsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("参与创作")
                    .font(.headline)
                    .foregroundColor(Color.theme.primaryText)
                Spacer()
                NavigationLink(destination: AllParticipantsView(viewModel: viewModel)) {
                    Text("\(viewModel.participants.count)小组成员 >")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.tertiaryText)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(viewModel.participants, id: \.userID) { participant in
                        VStack(spacing: 4) {
                            if participant.avatar.isEmpty {
                                KFImage(URL(string: convertImagetoSenceImage(url: participant.avatar, scene: .small)))
                                    .cacheMemoryOnly()
                                    .fade(duration: 0.25)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.theme.border, lineWidth: 0.5))
                            } else {
                                KFImage(URL(string: convertImagetoSenceImage(url: participant.avatar, scene: .small)))
                                    .cacheMemoryOnly()
                                    .fade(duration: 0.25)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.theme.border, lineWidth: 0.5))
                            }
                            
                            Text(participant.name)
                                .font(.caption)
                                .foregroundColor(Color.theme.secondaryText)
                                .lineLimit(1)
                        }
                    }
                    Button(action: {
                        // 邀请新成员
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "plus")
                                .foregroundColor(Color.theme.accent)
                                .frame(width: 50, height: 50)
                                .background(Color.theme.tertiaryBackground)
                                .clipShape(Circle())
                            Text("邀请人员参与")
                                .font(.caption)
                                .foregroundColor(Color.theme.tertiaryText)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private func formatDate(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return DateFormatter.shortDate.string(from: date)
    }
    
    private func uploadAvatar(_ image: UIImage) async {
        isUpdatingAvatar = true
        defer { isUpdatingAvatar = false }
        
        do {
            // 更新故事头像
            let newUrl = try await viewModel.uploadImage(image)
            
        } catch {
            await MainActor.run {
                selectedImage = nil
            }
        }
    }
}

struct Stat: View {
    let title: String
    let value: Int
    
    var body: some View {
        VStack {
            Text("\(value)")
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(Color.theme.secondaryText)
        }
    }
}

struct StoryUser: View {
    let avatar: String
    let name: String
    
    var body: some View {
        VStack {
            KFImage(URL(string: convertImagetoSenceImage(url: avatar, scene: .small)))
                .cacheMemoryOnly()
                .fade(duration: 0.25)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(name)
                    .font(.title)
                    .fontWeight(.bold)
            }
        }
    }
}

// 假设的全部角色视图
struct AllCharactersView: View {
    @ObservedObject var viewModel: StoryDetailViewModel
    @State private var showNewStoryRole = false
    @State private var selectedCharacter: StoryRole?
    
    var body: some View {
        ScrollView {
            characterGrid
        }
        .navigationTitle("所有角色")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                addButton
            }
        }
        .sheet(isPresented: $showNewStoryRole) {
            NewStoryRole(
                storyId: (viewModel.story?.storyInfo.id)!,
                userId: viewModel.userId,
                viewModel: viewModel
            )
        }
        .navigationDestination(for: StoryRole.self) { character in
            StoryRoleDetailView(
                roleId: character.role.roleID,
                userId: character.role.creatorID,
                role: character
            )
        }
    }
    
    private var characterGrid: some View {
        LazyVStack(spacing: 4) {
            ForEach(viewModel.characters ?? [], id: \.role.roleID) { character in
                CharacterCell(character: character, viewModel: self.viewModel)
                    .padding(.horizontal)
                    .onTapGesture {
                        selectedCharacter = character
                    }
            }
        }
    }
    
    private var addButton: some View {
        Button(action: {
            showNewStoryRole = true
        }) {
            Image(systemName: "plus.circle")
        }
    }
}

// 假设的全部参与者视图
struct AllParticipantsView: View {
    @ObservedObject var viewModel: StoryDetailViewModel
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                ForEach(viewModel.participants, id: \.userID) { participant in
                    VStack {
                        if !participant.avatar.isEmpty{
                            KFImage(URL(string: convertImagetoSenceImage(url: participant.avatar, scene: .small)))
                                .cacheMemoryOnly()
                                .fade(duration: 0.25)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        }else{
                            KFImage(URL(string: convertImagetoSenceImage(url: participant.avatar, scene: .small)))
                                .cacheMemoryOnly()
                                .fade(duration: 0.25)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        }
                        
                        Text(participant.name)
                            .font(.caption)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("所有参与者")
    }
}

struct StorySettingDetailView: View {
    let title: String
    @Binding var content: String
    @State private var isEditing: Bool = false
    @State private var isAIRendering: Bool = false
    @State private var aiGeneratedContent: String = ""
    var onSave: (String) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 文本编辑区
            TextEditor(text: isEditing ? $content : .constant(content))
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 64, maxHeight: 96, alignment: .top)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .disabled(!isEditing)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.theme.border, lineWidth: 1)
                )
                .padding(.top, 32)
                .padding(.horizontal)

            // AI 渲染控制区域
            HStack(alignment: .center, spacing: 8) {
                Text("使用 AI 优化内容")
                    .font(.body)
                Toggle("", isOn: $isAIRendering)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                    .scaleEffect(0.75)
                    .frame(height: 24)
                    .padding(.trailing, 4)
            }
            .padding(.horizontal)

            if isAIRendering {
                Button(action: {
                    aiGeneratedContent = "AI渲染: \(content)"
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "wand.and.stars")
                        Text("AI渲染")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .frame(width: 200, height: 36)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                .disabled(!isEditing)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)
                
                if !aiGeneratedContent.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI 优化结果:")
                            .font(.headline)
                        Text(aiGeneratedContent)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        Button(action: {
                            content = aiGeneratedContent
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("应用 AI 优化结果")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "保存" : "编辑") {
                    if isEditing {
                        onSave(content)
                    }
                    isEditing.toggle()
                    if !isEditing {
                        isAIRendering = false
                        aiGeneratedContent = ""
                    }
                }
                .foregroundColor(isEditing ? .blue : .gray)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("取消") {
                    isAIRendering = false
                    isEditing = false
                }
                .foregroundColor(isEditing ? .blue : .gray)
            }
        }
    }
}

struct SettingRow<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color.theme.primaryText)
                .padding(.bottom, 4)
            content
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(8)
    }
}

// ====== 新增自定义控件 ======
struct StylePicker: View {
    @Binding var selectedStyle: String
    let styles = ["写实风格", "动漫风格", "油画风格", "水彩风格", "素描风格"]

    func imageName(for style: String) -> String? {
        switch style {
        case "写实风格": return "style_realistic"
        case "动漫风格": return "style_anime"
        case "油画风格": return "style_oil"
        case "水彩风格": return "style_watercolor"
        case "素描风格": return "style_sketch"
        default: return nil
        }
    }

    var currentIndex: Int {
        styles.firstIndex(of: selectedStyle) ?? 0
    }

    var body: some View {
        VStack(spacing: 8) {
            // 只画一层 Capsule 线框
            HStack(spacing: 0) {
                // 左按钮
                Button(action: {
                    let newIndex = (currentIndex - 1 + styles.count) % styles.count
                    selectedStyle = styles[newIndex]
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color.theme.accent)
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 32, height: 32)
                        .contentShape(Circle())
                }
                // 中间风格名
                Text(selectedStyle)
                    .font(.caption)
                    .frame(minWidth: 60, maxWidth: .infinity, minHeight: 32, maxHeight: 32)
                    .multilineTextAlignment(.center)
                // 右按钮
                Button(action: {
                    let newIndex = (currentIndex + 1) % styles.count
                    selectedStyle = styles[newIndex]
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color.theme.accent)
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 32, height: 32)
                        .contentShape(Circle())
                }
            }
            .frame(height: 32)
            .background(Color.clear)
            .overlay(
                Capsule()
                    .stroke(Color.theme.border, lineWidth: 1)
            )
            // 样例图片区域
            if let imageName = imageName(for: selectedStyle), UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(height: 56)
                    .cornerRadius(8)
                    .padding(.top, 2)
            } else {
                Image(systemName: "photo.fill.on.rectangle.fill")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(height: 56)
                    .foregroundColor(Color.theme.tertiaryText.opacity(0.5))
                    .padding(.top, 2)
            }
        }
    }
}

struct SceneStepper: View {
    @Binding var count: Int
    let minValue: Int = 0 // 允许0个场景
    let maxValue: Int = 8
    @State private var lastTapped: String? = nil // "up" or "down"

    var body: some View {
        HStack(spacing: 0) {
            // 左按钮（减少）
            Button(action: {
                if count > minValue {
                    count -= 1
                    lastTapped = "down"
                }
            }) {
                Image(systemName: "triangle.fill")
                    .rotationEffect(.degrees(180))
                    .foregroundColor(count > minValue ? Color.theme.accent : Color.theme.tertiaryText)
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 32, height: 32)
                    .contentShape(Circle())
            }
            // 中间文本
            Text("\(count) 个场景")
                .font(.caption)
                .frame(minWidth: 60, maxWidth: .infinity, minHeight: 32, maxHeight: 32)
                .multilineTextAlignment(.center)
            // 右按钮（增加）
            Button(action: {
                if count < maxValue {
                    count += 1
                    lastTapped = "up"
                }
            }) {
                Image(systemName: "triangle.fill")
                    .rotationEffect(.degrees(0))
                    .foregroundColor(count < maxValue ? Color.theme.accent : Color.theme.tertiaryText)
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 32, height: 32)
                    .contentShape(Circle())
            }
        }
        .frame(height: 32)
        .background(Color.clear)
        .overlay(
            Capsule()
                .stroke(Color.theme.border, lineWidth: 1)
        )
    }
}

