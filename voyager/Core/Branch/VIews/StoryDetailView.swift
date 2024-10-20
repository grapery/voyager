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
    
    init(storyId: Int64,story: Story) {
        self.storyId = storyId
        self.story = story
        self._viewModel = StateObject(wrappedValue: StoryDetailViewModel(storyId: storyId,story:story))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                storyHeader
                storyStats
                Spacer()
                storyDetails
                if viewModel.story?.storyInfo.isAiGen ?? false {
                    aiGenerationDetails
                }
                Spacer()
                Section{
                    charactersList
                }
                Spacer()
                Section{
                    participantsList
                }
                
            }
            .padding()
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
            Task{
                await viewModel.fetchStoryDetails()
            }
        }
    }
    
    private var storyHeader: some View {
        VStack{
            HStack {
                KFImage(URL(string: viewModel.story?.storyInfo.avatar ?? ""))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
//                    .overlay(
//                        Text("2")
//                            .font(.caption)
//                            .foregroundColor(.white)
//                            .padding(5)
//                            .background(Color.blue)
//                            .clipShape(Circle())
//                            .offset(x: 30, y: 30)
//                    )
                VStack(alignment: .leading) {
                    Text("名称")
                        .font(.headline)
                    if isEditing {
                        TextField("", text: Binding(
                            get: { story.storyInfo.name },
                            set: { story.storyInfo.name = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        Text(viewModel.story?.storyInfo.name ?? "")
                            .font(.title)
                            .fontWeight(.bold)
                        if let createdAt = viewModel.story?.storyInfo.ctime {
                            Text("创建于: \(formatDate(timestamp: createdAt))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            VStack(alignment: .leading) {
                Text("简介")
                    .font(.headline)
                    .fontWeight(.bold)
                if isEditing {
                    TextField("", text: Binding(
                        get: { story.storyInfo.desc },
                        set: { story.storyInfo.desc = $0 }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    Text(story.storyInfo.desc)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
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
        VStack(alignment: .leading) {
            Text("故事细节")
                .font(.headline)
            
            if isEditing {
                TextField("故事名称", text: Binding(
                    get: { viewModel.story?.storyInfo.name ?? "" },
                    set: { viewModel.story?.storyInfo.name = $0 }
                ))
                .border(Color.gray.opacity(0.2))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                VStack(alignment: .leading) {
                    Text("故事描述")
                        .font(.headline)
                    ScrollView {
                        TextEditor(text: Binding(
                            get: { viewModel.story?.storyInfo.params.storyDescription ?? "" },
                            set: { viewModel.story?.storyInfo.params.storyDescription = $0 }
                        ))
                        .frame(minHeight: 100) // 设置最小高度
                        .border(Color.gray.opacity(0.2))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                TextField("参考原图", text: Binding(
                    get: { viewModel.story?.storyInfo.params.refImage ?? "" },
                    set: { viewModel.story?.storyInfo.params.refImage = $0 }
                ))
                .border(Color.gray.opacity(0.2))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                VStack(alignment: .leading) {
                    Text("故事背景")
                        .font(.headline)
                    ScrollView {
                        TextEditor(text: Binding(
                            get: { viewModel.story?.storyInfo.params.background ?? "" },
                            set: { viewModel.story?.storyInfo.params.background = $0 }
                        ))
                        .border(Color.gray.opacity(0.2))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("故事描述")
                        .font(.headline)
                    ScrollView {
                        TextEditor(text: Binding(
                            get: { viewModel.story?.storyInfo.params.negativePrompt ?? "" },
                            set: { viewModel.story?.storyInfo.params.negativePrompt = $0 }
                        ))
                        .frame(minHeight: 100) // 设置最小高度
                        .border(Color.gray.opacity(0.2))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                VStack(alignment: .leading) {
                    Text("故事描述")
                        .font(.headline)
                    ScrollView {
                        TextEditor(text: Binding(
                            get: { viewModel.story?.storyInfo.params.negativePrompt ?? "" },
                            set: { viewModel.story?.storyInfo.params.negativePrompt = $0 }
                        ))
                        .frame(minHeight: 100) // 设置最小高度
                        .border(Color.gray.opacity(0.2))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            } else {
                Text(viewModel.story?.storyInfo.name ?? "")
                    .border(Color.gray.opacity(0.2))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text(viewModel.story?.storyInfo.origin ?? "")
                    .border(Color.gray.opacity(0.2))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Toggle("是否AI生成描述", isOn: Binding(
                get: { viewModel.story?.storyInfo.isAiGen ?? false },
                set: { viewModel.story?.storyInfo.isAiGen = $0 }
            ))
            .disabled(!isEditing)
        }
    }
    
    private var aiGenerationDetails: some View {
        VStack(alignment: .leading) {
            Text("AI Generation Details")
                .font(.headline)
            
            if isEditing {
                VStack(alignment: .leading, spacing: 10) {
                    Text("故事描述")
                        .font(.headline)
                    
                    ScrollView {
                        TextEditor(text: Binding(
                            get: { viewModel.story?.storyInfo.params.storyDescription ?? ""},
                            set: { viewModel.story?.storyInfo.params.storyDescription = $0 }
                        ))
                        .frame(minHeight: 100) // 设置最小高度
                        .border(Color.gray.opacity(0.2))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("参考原图")
                        .font(.headline)
                    ScrollView {
                        TextEditor(text: Binding(
                            get: { viewModel.story?.storyInfo.params.refImage ?? ""},
                            set: { viewModel.story?.storyInfo.params.refImage = $0 }
                        ))
                        .frame(minHeight: 100) // 设置最小高度
                        .border(Color.gray.opacity(0.2))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("故事背景")
                        .font(.headline)
                    ScrollView {
                        TextEditor(text: Binding(
                            get: { viewModel.story?.storyInfo.params.refImage ?? ""},
                            set: { viewModel.story?.storyInfo.params.refImage = $0 }
                        ))
                        .frame(minHeight: 100) // 设置最小高度
                        .border(Color.gray.opacity(0.2))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("负面提示词")
                        .font(.headline)
                        
                    ScrollView {
                        TextEditor(text: Binding(
                            get: { viewModel.story?.storyInfo.params.refImage ?? ""},
                            set: { viewModel.story?.storyInfo.params.refImage = $0 }
                        ))
                        .frame(minHeight: 100) // 设置最小高度
                        .border(Color.gray.opacity(0.2))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("正面提示词")
                        .font(.headline)
                    ScrollView {
                        TextEditor(text: Binding(
                            get: { viewModel.story?.storyInfo.params.refImage ?? ""},
                            set: { viewModel.story?.storyInfo.params.refImage = $0 }
                        ))
                        .frame(minHeight: 100) // 设置最小高度
                        .border(Color.gray.opacity(0.2))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            } else {
                Section{
                    Text(viewModel.story?.storyInfo.params.storyDescription ?? "")
                        .font(.body)
                    Spacer()
                    Text("参考的图像: \(viewModel.story?.storyInfo.params.refImage ?? "")")
                        .font(.body)
                    Spacer()
                    Text("故事背景: \(viewModel.story?.storyInfo.params.background ?? "")")
                        .font(.body)
                    Spacer()
                    Text("负面提示词: \(viewModel.story?.storyInfo.params.negativePrompt ?? "")")
                        .font(.body)
                    Spacer()
                    Text("正面提示词: \(viewModel.story?.storyInfo.params.negativePrompt ?? "")")
                        .font(.body)
                    Spacer()
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
                            Text("创建新的角色")
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

