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
    
    init(storyId: Int64, story: Story) {
        self.storyId = storyId
        self.story = story
        self._viewModel = StateObject(wrappedValue: StoryDetailViewModel(storyId: storyId, story: story))
    }
    
    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
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
                .padding(14)
                .background(Color(.systemGray5))
                .cornerRadius(14)
                .padding(.horizontal, 30)
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
        VStack(alignment: .leading, spacing: 15) {
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
            Group {
                if isEditing {
                    DisclosureGroup("故事��述") {
                        ScrollView {
                            TextEditor(text: Binding(
                                get: { viewModel.story?.storyInfo.desc ?? "" },
                                set: { viewModel.story?.storyInfo.desc = $0 }
                            ))
                            .font(.subheadline)
                            .padding(14)
                            .background(Color(.systemGray5))
                            .cornerRadius(14)
                            .frame(minHeight: 150) // Set minimum height for large text
                        }
                    }
                    
                    DisclosureGroup("故事背景") {
                        ScrollView {
                            TextEditor(text: Binding(
                                get: { viewModel.story?.storyInfo.params.background ?? "" },
                                set: { viewModel.story?.storyInfo.params.background = $0 }
                            ))
                            .font(.subheadline)
                            .padding(14)
                            .background(Color(.systemGray5))
                            .cornerRadius(14)
                            .frame(minHeight: 150) // Set minimum height for large text
                        }
                    }
                    
                    DisclosureGroup("正面提示词") {
                        ScrollView {
                            TextEditor(text: Binding(
                                get: { viewModel.story?.storyInfo.params.negativePrompt ?? "" },
                                set: { viewModel.story?.storyInfo.params.negativePrompt = $0 }
                            ))
                            .font(.subheadline)
                            .padding(14)
                            .background(Color(.systemGray5))
                            .cornerRadius(14)
                            .frame(minHeight: 150) // Set minimum height for large text
                        }
                    }
                    
                    DisclosureGroup("负面提示词") {
                        ScrollView {
                            TextEditor(text: Binding(
                                get: { viewModel.story?.storyInfo.params.negativePrompt ?? "" },
                                set: { viewModel.story?.storyInfo.params.negativePrompt = $0 }
                            ))
                            .font(.subheadline)
                            .padding(14)
                            .background(Color(.systemGray5))
                            .cornerRadius(14)
                            .frame(minHeight: 150) // Set minimum height for large text
                        }
                    }
                } else {
                    DisclosureGroup("故事描述") {
                        Text(viewModel.story?.storyInfo.desc ?? "")
                            .padding(14)
                            .background(Color(.systemGray5))
                            .cornerRadius(14)
                    }

                    DisclosureGroup("故事背景") {
                        Text(viewModel.story?.storyInfo.params.background ?? "")
                            .padding(14)
                            .background(Color(.systemGray5))
                            .cornerRadius(14)
                    }
                    
                    DisclosureGroup("正面提示词") {
                        Text(viewModel.story?.storyInfo.params.negativePrompt ?? "")
                            .padding(14)
                            .background(Color(.systemGray5))
                            .cornerRadius(14)
                    }
                    
                    DisclosureGroup("负面提示词") {
                        Text(viewModel.story?.storyInfo.params.negativePrompt ?? "")
                            .padding(14)
                            .background(Color(.systemGray5))
                            .cornerRadius(14)
                    }
                }
            }
        }
    }
    
    private var charactersList: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("故事角色")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: AllCharactersView(viewModel: viewModel)) {
                    Text("查看\(viewModel.characters.count)名角色 >")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(viewModel.characters, id: \.userID) { character in
                        VStack {
                            KFImage(URL(string: character.avatar))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                            Text(character.name)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                    Button(action: {
                        // 添加新角色的操作
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
                            KFImage(URL(string: participant.avatar))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
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

class StoryDetailViewModel: ObservableObject {
    @Published var story: Story?
    private let storyId: Int64
    @Published var characters: [User] = []
    @Published var participants: [User] = []
    var likes: Int = 10
    var followers: Int = 10
    var shares: Int = 10
    private let apiClient = APIClient.shared
    init(storyId: Int64,story: Story) {
        self.storyId = storyId
        self.story = story
    }
    
    func fetchStoryDetails() async{
        // TODO: Implement API call to fetch story details
        
    }
    
    func saveStory() {
        // TODO: Implement API call to save story changes
    }
    
    func createStoryRole(){
        // TODO: Implement API call to create new roel for story
    }
    
    func editStoryRole(){
        // TODO: Implement API call to edit role in story
    }
    
    func delStoryRole(){
        // TODO: Implement API call to delete role instory
    }
}

// 假设的全部角色视图
struct AllCharactersView: View {
    @ObservedObject var viewModel: StoryDetailViewModel
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                ForEach(viewModel.characters, id: \.userID) { character in
                    VStack {
                        KFImage(URL(string: character.avatar))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        
                        Text(character.name)
                            .font(.caption)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("所有角色")
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
                        KFImage(URL(string: participant.avatar))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        
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

