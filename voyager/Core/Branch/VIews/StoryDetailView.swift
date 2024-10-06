//
//  StoryDetailView.swift
//  voyager
//
//  Created by grapestree on 2024/10/6.
//

import SwiftUI
import Kingfisher

struct StoryDetailView: View {
    var storyId: Int64
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
        HStack {
            KFImage(URL(string: viewModel.story?.storyInfo.avatar ?? ""))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
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
    
    private var storyStats: some View {
        HStack {
            Stat(title: "Likes", value: viewModel.likes)
            Stat(title: "Followers", value: viewModel.followers)
            Stat(title: "Shares", value: viewModel.shares)
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
                VStack(alignment: .leading) {
                    Text("故事描述")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ScrollView {
                        TextEditor(text: Binding(
                            get: { viewModel.story?.storyInfo.params.storyDescription ?? "" },
                            set: { viewModel.story?.storyInfo.params.storyDescription = $0 }
                        ))
                        .frame(height: 200) // 设置固定高度
                        .padding()
                        .background(Color(UIColor.systemGray6)) // 设置背景颜色
                        .cornerRadius(2) // 圆角
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.gray, lineWidth: 1) // 添加边框
                        )
                    }
                }
                
                TextField("Reference Image URL", text: Binding(
                    get: { viewModel.story?.storyInfo.params.refImage ?? "" },
                    set: { viewModel.story?.storyInfo.params.refImage = $0 }
                ))
                VStack(alignment: .leading) {
                    Text("故事背景")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ScrollView {
                        TextEditor(text: Binding(
                        get: { viewModel.story?.storyInfo.params.background ?? "" },
                        set: { viewModel.story?.storyInfo.params.background = $0 }
                    ))
                    .frame(minHeight: 200) // 设置最小高度
                    .padding()
                    .background(Color(UIColor.systemGray6)) // 设置背景颜色
                    .cornerRadius(2) // 圆角
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.gray, lineWidth: 1) // 添加边框
                        )
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("故事描述")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ScrollView {
                        TextEditor(text: Binding(
                            get: { viewModel.story?.storyInfo.params.negativePrompt ?? "" },
                            set: { viewModel.story?.storyInfo.params.negativePrompt = $0 }
                        ))
                        .frame(minHeight: 200) // 设置最小高度
                        .padding()
                        .background(Color(UIColor.systemGray6)) // 设置背景颜色
                        .cornerRadius(2) // 圆角
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.gray, lineWidth: 1) // 添加边框
                        )
                    }
                }
                VStack(alignment: .leading) {
                    Text("故事描述")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ScrollView {
                        TextEditor(text: Binding(
                            get: { viewModel.story?.storyInfo.params.negativePrompt ?? "" },
                            set: { viewModel.story?.storyInfo.params.negativePrompt = $0 }
                        ))
                        .frame(minHeight: 200) // 设置最小高度
                        .padding()
                        .background(Color(UIColor.systemGray6)) // 设置背景颜色
                        .cornerRadius(2) // 圆角
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.gray, lineWidth: 1) // 添加边框
                        )
                    }
                }
            } else {
                Text(viewModel.story?.storyInfo.name ?? "")
                Text(viewModel.story?.storyInfo.origin ?? "")
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
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    ScrollView {
                        TextEditor(text: Binding(
                            get: { viewModel.story?.storyInfo.params.storyDescription ?? ""},
                            set: { viewModel.story?.storyInfo.params.storyDescription = $0 }
                        ))
                        .frame(height: 200) // 设置固定高度
                        .padding()
                        .background(Color(UIColor.systemGray6)) // 设置背景颜色
                        .cornerRadius(8) // 圆角
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.gray, lineWidth: 1) // 添加边框
                        )
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("参考的图像")
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    ScrollView {
                        TextEditor(text: Binding(
                            get: { viewModel.story?.storyInfo.params.refImage ?? ""},
                            set: { viewModel.story?.storyInfo.params.refImage = $0 }
                        ))
                        .frame(height: 200) // 设置固定高度
                        .padding()
                        .background(Color(UIColor.systemGray6)) // 设置背景颜色
                        .cornerRadius(8) // 圆角
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.gray, lineWidth: 1) // 添加边框
                        )
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("故事背景")
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    ScrollView {
                        TextEditor(text: Binding(
                            get: { viewModel.story?.storyInfo.params.refImage ?? ""},
                            set: { viewModel.story?.storyInfo.params.refImage = $0 }
                        ))
                        .frame(height: 200) // 设置固定高度
                        .padding()
                        .background(Color(UIColor.systemGray6)) // 设置背景颜色
                        .cornerRadius(8) // 圆角
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.gray, lineWidth: 1) // 添加边框
                        )
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("负面提示词")
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    ScrollView {
                        TextEditor(text: Binding(
                            get: { viewModel.story?.storyInfo.params.refImage ?? ""},
                            set: { viewModel.story?.storyInfo.params.refImage = $0 }
                        ))
                        .frame(height: 200) // 设置固定高度
                        .padding()
                        .background(Color(UIColor.systemGray6)) // 设置背景颜色
                        .cornerRadius(8) // 圆角
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.gray, lineWidth: 1) // 添加边框
                        )
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("正面提示词")
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    ScrollView {
                        TextEditor(text: Binding(
                            get: { viewModel.story?.storyInfo.params.refImage ?? ""},
                            set: { viewModel.story?.storyInfo.params.refImage = $0 }
                        ))
                        .frame(height: 200) // 设置固定高度
                        .padding()
                        .background(Color(UIColor.systemGray6)) // 设置背景颜色
                        .cornerRadius(8) // 圆角
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.gray, lineWidth: 1) // 添加边框
                        )
                    }
                }
            } else {
                Section{
                    Text(viewModel.story?.storyInfo.params.storyDescription ?? "")
                    Spacer()
                    Text("参考的图像: \(viewModel.story?.storyInfo.params.refImage ?? "")")
                    Spacer()
                    Text("故事背景: \(viewModel.story?.storyInfo.params.background ?? "")")
                    Spacer()
                    Text("负面提示词: \(viewModel.story?.storyInfo.params.negativePrompt ?? "")")
                    Spacer()
                    Text("正面提示词: \(viewModel.story?.storyInfo.params.negativePrompt ?? "")")
                    Spacer()
                }
            }
        }
    }
    
    public var charactersList: some View {
        VStack(alignment: .leading) {
            Text("故事的角色列表")
                .font(.headline)
            
            ForEach(viewModel.characters,id: \.userID) { character in
                Text(character.name)
            }
        }
    }
    
    private var participantsList: some View {
        VStack(alignment: .leading) {
            Text("故事的贡献者")
                .font(.headline)
            ForEach(viewModel.participants,id: \.userID) { participant in
                Text(participant.name)
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
}
