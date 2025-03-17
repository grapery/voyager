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
                VStack(spacing: 10) {
                    storyHeader
                    storyStats
                    Divider()
                    //storyDetails
                    aiGenerationDetails
                    Divider()
                    charactersList
                    participantsList
                }
                .padding()
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
        .onAppear {
            Task {
                await viewModel.fetchStoryDetails()
            }
        }
    }
    
    private var storyHeader: some View {
        VStack(alignment: .center) {
            KFImage(URL(string: viewModel.story?.storyInfo.avatar ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            
            if isEditing {
                TextField("故事名称", text: Binding(
                    get: { story.storyInfo.name },
                    set: { story.storyInfo.name = $0 }
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
            Stat(title: "Likes", value: viewModel.likes)
            Stat(title: "Followers", value: viewModel.followers)
            Stat(title: "Shares", value: viewModel.shares)
        }
    }

    private var configurationSection: some View {
        VStack(alignment: .leading) {
            Text("配置信息")
                .font(.headline)
            if isEditing {
                TextEditor(text: Binding(
                    get: { story.storyInfo.params.background },
                    set: { story.storyInfo.params.background = $0 }
                ))
                .frame(height: 150)
                .border(Color.gray.opacity(0.2))
                .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                Text(story.storyInfo.params.background)
            }
            HStack {
                ForEach(["角色", "游戏", "画图", "工具"], id: \.self) { tag in
                    Text(tag)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                }
            }
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
//            Group{
//                Toggle("是否AI生成描述", isOn: Binding(
//                    get: { viewModel.story?.storyInfo.isAiGen ?? false },
//                    set: { viewModel.story?.storyInfo.isAiGen = $0 }
//                ))
//                .disabled(!isEditing)
//                .padding(.vertical)
//            }
        }
    }
    
    private var aiGenerationDetails: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("故事设置")
                .font(.headline)
                .padding(.top)
            
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
                    SettingRow(title: "故事简介", content: viewModel.story?.storyInfo.desc ?? "")
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
                    SettingRow(title: "故事背景", content: viewModel.story?.storyInfo.params.background ?? "")
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
                    SettingRow(title: "正面提示词", content: viewModel.story?.storyInfo.params.negativePrompt ?? "")
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
                    SettingRow(title: "负面提示词", content: viewModel.story?.storyInfo.params.negativePrompt ?? "")
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    private var charactersList: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("故事角色")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: AllCharactersView(viewModel: viewModel)) {
                    Text("查看\(viewModel.characters!.count)名角色 >")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(viewModel.characters!.enumerated()), id: \.offset) { _, character in
                        VStack {
                            if character.role.characterAvatar.isEmpty {
                                KFImage(URL(string: defaultAvator))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            }else{
                                KFImage(URL(string: character.role.characterAvatar))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            }
                            
                            Text(character.role.characterName)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                    
                    Button(action: {
                        showNewStoryRole = true
                    }) {
                        VStack {
                            Image(systemName: "plus")
                                .frame(width: 50, height: 50)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                            Text("添加人物角色")
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal)
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
        VStack(alignment: .leading) {
            HStack {
                Text("参与故事创建")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: AllParticipantsView(viewModel: viewModel)) {
                    Text("查看\(viewModel.participants.count)名群成员 >")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(viewModel.participants, id: \.userID) { participant in
                        VStack {
                            if participant.avatar.isEmpty {
                                KFImage(URL(string: defaultAvator))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            }else{
                                KFImage(URL(string: participant.avatar))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            }
                            
                            Text(participant.name)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                    Button(action: {
                        // 邀请新成员
                    }) {
                        VStack {
                            Image(systemName: "plus")
                                .frame(width: 50, height: 50)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                            Text("邀请人员参与")
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }
    
    private func formatDate(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return DateFormatter.shortDate.string(from: date)
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
            KFImage(URL(string: avatar))
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
        LazyVStack(spacing: 8) {
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
                            KFImage(URL(string: participant.avatar))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        }else{
                            KFImage(URL(string: defaultAvator))
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

struct SettingRow: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color.theme.primaryText)
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(Color.theme.secondaryText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(8)
    }
}

