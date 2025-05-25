//
//  StoryDetailView.swift
//  voyager
//
//  Created by grapestree on 2024/10/6.
//

import SwiftUI
import Kingfisher

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
            Color(.systemGray6).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 8) {
                    storyHeader
                    storyStats
                    Divider()
                    //storyDetails
                    aiGenerationDetails
                    Divider()
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
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
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
                    .foregroundColor(.secondary)
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
        VStack(alignment: .leading, spacing: 8) {
            VStack(spacing: 8) {
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
                        Text(viewModel.story?.storyInfo.desc ?? "")
                            .font(.subheadline)
                            .foregroundColor(Color.theme.secondaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
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
                        Text(viewModel.story?.storyInfo.params.background ?? "")
                            .font(.subheadline)
                            .foregroundColor(Color.theme.secondaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                NavigationLink(destination: StorySettingDetailView(
                    title: "正面提示词",
                    content: Binding(
                        get: { viewModel.story?.storyInfo.params.negativePrompt ?? "" },
                        set: { viewModel.story?.storyInfo.params.negativePrompt = $0 }
                    ),
                    onSave: { newContent in
                        viewModel.story?.storyInfo.params.negativePrompt = newContent
                        viewModel.saveStory()
                    }
                )) {
                    SettingRow(title: "正面提示词") {
                        Text(viewModel.story?.storyInfo.params.negativePrompt ?? "")
                            .font(.subheadline)
                            .foregroundColor(Color.theme.secondaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                NavigationLink(destination: StorySettingDetailView(
                    title: "负面提示词",
                    content: Binding(
                        get: { viewModel.story?.storyInfo.params.negativePrompt ?? "" },
                        set: { viewModel.story?.storyInfo.params.negativePrompt = $0 }
                    ),
                    onSave: { newContent in
                        viewModel.story?.storyInfo.params.negativePrompt = newContent
                        viewModel.saveStory()
                    }
                )) {
                    SettingRow(title: "负面提示词") {
                        Text(viewModel.story?.storyInfo.params.negativePrompt ?? "")
                            .font(.subheadline)
                            .foregroundColor(Color.theme.secondaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                // 用新版 SettingRow 组件实现"故事风格"和"场景数量"
                SettingRow(title: "故事风格") {
                    StylePicker(selectedStyle: Binding(
                        get: { viewModel.story?.storyInfo.params.style ?? "写实风格" },
                        set: { viewModel.story?.storyInfo.params.style = $0 }
                    ))
                }
                SettingRow(title: "场景数量") {
                    SceneStepper(count: Binding(
                        get: { Int(viewModel.sceneCount) },
                        set: { viewModel.sceneCount = Int(Int32($0)) }
                    ))
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(8)
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
                .foregroundColor(.secondary)
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
            // 原有的文本编辑器
            TextEditor(text: isEditing ? $content : .constant(content))
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(Color(.systemBackground))
                .cornerRadius(9)
                .disabled(!isEditing)
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .padding()
            
            // AI 渲染控制区域
            VStack(spacing: 12) {
                Toggle("使用 AI 优化内容", isOn: $isAIRendering)
                    .disabled(!isEditing)
                    .padding(.horizontal)
                
                if isAIRendering {
                    Button(action: {
                        // TODO: 调用 AI 渲染 API
                        // 这里是示例代码，需要替换为实际的 AI 渲染逻辑
                        aiGeneratedContent = "AI渲染: \(content)"
                    }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("开始 AI 优化")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(!isEditing)
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
        }
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
            content
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

    var body: some View {
        Menu {
            ForEach(styles, id: \.self) { style in
                Button {
                    selectedStyle = style
                } label: {
                    HStack {
                        if selectedStyle == style {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                        Text(style)
                    }
                }
            }
        } label: {
            HStack {
                Text(selectedStyle)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .frame(width: 160, alignment: .leading)
        }
        .frame(width: 160, alignment: .leading)
    }
}

struct SceneStepper: View {
    @Binding var count: Int
    let minValue: Int = 1
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
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(count > minValue ? Color.purple.opacity(0.08) : Color.white)
                    Image(systemName: "triangle.fill")
                        .rotationEffect(.degrees(180))
                        .foregroundColor(lastTapped == "down" ? .purple : .gray)
                        .font(.system(size: 18, weight: .bold))
                }
                .frame(width: 56, height: 40)
            }
            .buttonStyle(PlainButtonStyle())

            // 中间文本
            Text("\(count) 个场景")
                .font(.system(size: 16, weight: .medium))
                .frame(minWidth: 60, maxWidth: .infinity, minHeight: 40, maxHeight: 40)
                .background(Color.white)
                .animation(.default, value: count)
                .overlay(
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(Color.gray.opacity(0.2)),
                    alignment: .leading
                )
                .overlay(
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(Color.gray.opacity(0.2)),
                    alignment: .trailing
                )

            // 右按钮（增加）
            Button(action: {
                if count < maxValue {
                    count += 1
                    lastTapped = "up"
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(count < maxValue ? Color.purple.opacity(0.08) : Color.white)
                    Image(systemName: "triangle.fill")
                        .rotationEffect(.degrees(0))
                        .foregroundColor(lastTapped == "up" ? .purple : .gray)
                        .font(.system(size: 18, weight: .bold))
                }
                .frame(width: 56, height: 40)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
        .frame(height: 40)
    }
}

