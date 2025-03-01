//
//  StoryView.swift
//  voyager
//
//  Created by grapestree on 2024/9/24.
//

import SwiftUI
import Kingfisher
import Combine
import AVKit

struct StoryView: View {
    @StateObject var viewModel: StoryViewModel
    @State private var isEditing: Bool = false
    @State public var storyId: Int64
    @State private var selectedTab: Int64 = 0
    @State public var story: Story
    
    var userId: Int64
    
    // 新增的状态变量
    @State private var generatedStory: Common_RenderStoryDetail?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    
    @State private var isShowingNewStoryBoard = false
    @State private var isShowingCommentView = false
    @State private var isForkingStory = false
    @State private var isLiked = false
    
    @State private var selectedBoard: StoryBoard?
    @State private var isShowingBoardDetail = false
    
    init(story: Story, userId: Int64) {
        self.story = story
        self.userId = userId
        self.storyId = story.storyInfo.id
        _viewModel = StateObject(wrappedValue: StoryViewModel(story: story, userId: userId))
    }
    
    
    
    var body: some View {
        VStack(spacing: 0) {
            // Story Info Header
            VStack(alignment: .leading, spacing: 12) {
                // 用户信息部分
                NavigationLink(destination: StoryDetailView(storyId: self.storyId, story: self.viewModel.story!, userId: self.userId)) {
                    HStack(spacing: 12) {
                        KFImage(URL(string: self.viewModel.story?.storyInfo.avatar ?? ""))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(self.viewModel.story?.storyInfo.name ?? "")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            if let createdAt = self.viewModel.story?.storyInfo.ctime {
                                Text(formatDate(timestamp: createdAt))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                }
                
                // 故事简介部分
                VStack(alignment: .leading, spacing: 8) {
                    Text(self.viewModel.story?.storyInfo.origin ?? "")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
                
                // 交互按钮栏
                HStack(spacing: 24) {
                    StoryInteractionButton(
                        count: "10",
                        icon: "heart",
                        color: .red
                    ) {
                        // 处理点赞事件
                        print("Like button tapped")
                        Task{
                            let err = await self.viewModel.likeStory(storyId: self.storyId,userId: self.userId)
                        }
                    }
                    
                    StoryInteractionButton(
                        count: "1",
                        icon: "bell",
                        color: .blue
                    ) {
                        // 处理关注事件
                        print("Follow button tapped")
                        Task{
                            let err = await self.viewModel.watchStory(storyId: self.storyId,userId: self.userId)
                        }
                    }
                    
                    StoryInteractionButton(
                        count: "分享",
                        icon: "square.and.arrow.up",
                        color: .green
                    ) {
                        // 处理分享事件
                        print("Share button tapped")
                        Task{
                            let err = await self.viewModel.likeStory(storyId: self.storyId,userId: self.userId)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(Color(.systemBackground))
            Divider()
            StoryTabView(selectedTab: $selectedTab)
                .padding(.top, 2) // 减少顶部间距
            
            GeometryReader { geometry in
                    VStack(spacing: 0) {
                        if selectedTab == 0 {
                            // 故事线视图
                            storyLineView
                        }else if selectedTab == 1{
                            // 故事生成视图
                            StoryGenView(generatedStory: $generatedStory,
                                         isGenerating: $isGenerating,
                                         errorMessage: $errorMessage,
                                         viewModel: viewModel,
                                         selectedTab: $selectedTab)
                        }else if selectedTab == 2 {
                            storyRolesListView.onAppear{
                                Task{
                                    await self.viewModel.getStoryRoles(storyId: self.storyId, userId: self.userId)
                                }
                            }
                        }
                    }
                    .frame(minHeight: geometry.size.height)
            }
            .padding(.top, 0) // 移除 GeometryReader 的顶部间距
        }
        .navigationTitle("故事")
        .task {
            if viewModel.storyboards == nil {
                await viewModel.fetchStory(withBoards: true)
                print("task fetchStory :",viewModel.storyboards as Any)
            }
        }
    }

    private var storyRolesListView: some View {
        VStack {
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(2.0)
                            .padding()
                        Text("加载中......")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
            } else if let roles = viewModel.storyRoles {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(roles, id: \.role.roleID) { role in
                            RoleCard(role: role)
                        }
                    }
                    .padding()
                }
            } else {
                Text("暂无角色")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    private var storyLineView: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if let boards = viewModel.storyboards {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(boards, id: \.id) { board in
                            StoryBoardCellView(
                                board: board,
                                userId: userId,
                                groupId: self.viewModel.story?.storyInfo.groupID ?? 0,
                                storyId: storyId,
                                viewModel: self.viewModel
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(Color(.systemBackground))
    }
    
    private func generateStory() {
        isGenerating = true
        errorMessage = nil
        Task { @MainActor in
            let result = await self.viewModel.genStory(storyId: self.storyId, userId: self.userId)
            
            if let error = result.1 {
                self.errorMessage = error.localizedDescription
                self.generatedStory = nil
            } else {
                self.generatedStory = result.0
                self.errorMessage = nil
            }
            
            self.isGenerating = false
        }
    }
    
    private func getGenerateStory() {
        errorMessage = nil
        //DispatchQueue.global().asyncAfter(deadline: .now() + 30) {
            Task { @MainActor in
                let result = await self.viewModel.getGenStory(storyId: self.storyId, userId: self.userId)
                if let error = result.1 {
                    self.errorMessage = error.localizedDescription
                    self.generatedStory = nil
                } else {
                    self.generatedStory = result.0
                    self.errorMessage = nil
                }
            }
        //}
    }
    
    private func formatDate(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return DateFormatter.shortDate.string(from: date)
    }
}


extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

struct StoryTabView: View {
    @Binding var selectedTab: Int64
    let tabs = ["故事板", "故事线","故事人物"]
    
    var body: some View {
        HStack {
            Spacer() // 添加起始 Spacer
            
            Button(action: { selectedTab = 0 }) {
                Image(systemName: "photo.stack")
                    .foregroundColor(selectedTab == 0 ? .black : .gray)
            }
            
            Spacer() // 中间 Spacer
            
            Button(action: { selectedTab = 1 }) {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundColor(selectedTab == 1 ? .black : .gray)
            }
            
            Spacer() // 中间 Spacer
            
            Button(action: { selectedTab = 2 }) {
                Image(systemName: "person.crop.rectangle.stack")
                    .foregroundColor(selectedTab == 2 ? .black : .gray)
            }
            
            Spacer() // 添加结束 Spacer
        }
        .padding(.horizontal)
    }
}

// 添加 CommentSheet 视图
struct CommentSheet: View {
    @Binding var isPresented: Bool
    @Binding var commentText: String
    var onSubmit: () -> Void
    
    // 添加键盘相关状态
    @FocusState private var isFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack {
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                }
                Spacer()
                Text("讨论")
                    .font(.headline)
                Spacer()
                Button(action: {
                    onSubmit()
                    isPresented = false
                }) {
                    Text("发布")
                        .foregroundColor(commentText.isEmpty ? .gray : .blue)
                }
                .disabled(commentText.isEmpty)
            }
            .padding()
            
            Divider()
            
            // 评论输入区域
            TextField("说点什么...", text: $commentText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding()
                .focused($isFocused)
                .onAppear {
                    isFocused = true // 自动弹出键盘
                }
            
            Spacer()
            
            // 底部工具栏
            HStack(spacing: 20) {
                Spacer()
                Button(action: {}) {
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
                Spacer()
                Button(action: {}) {
                    Image(systemName: "at")
                        .foregroundColor(.gray)
                }
                Spacer()
                Button(action: {}) {
                    Image(systemName: "face.smiling")
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
        }
        .background(Color(.systemBackground))
        // 添加手势关闭键盘
        .gesture(
            TapGesture()
                .onEnded { _ in
                    isFocused = false
                }
        )
        // 调整视图位置以适应键盘
        .animation(.easeOut(duration: 0.16), value: keyboardHeight)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}



// 新增的交互按钮组件
struct StoryInteractionButton: View {
    let count: String
    let icon: String
    let color: Color
    var action: () -> Void  // 添加点击回调闭包
    @State private var isPressed = false  // 添加按压状态
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
                // 延迟重置按压状态
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
            action()  // 执行点击回调
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(count)
                    .font(.system(size: 14))
            }
            .foregroundColor(color)
            .scaleEffect(isPressed ? 0.9 : 1.0)  // 添加按压效果
        }
    }
}

// 新增的操作按钮组件
struct StoryActionButton: View {
    let icon: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isPressed = true
            }
            // 添加轻微延迟以展示按压效果
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                action()
                withAnimation {
                    isPressed = false
                }
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(Color(.systemGray6))
                .cornerRadius(22)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
    }
}

// 角色卡片视图
struct RoleCard: View {
    let role: StoryRole
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 角色头像和名称
            HStack(spacing: 12) {
                KFImage(URL(string: role.role.characterAvatar))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.role.characterName)
                        .font(.headline)
                    Text("ID: \(role.role.roleID)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            // 角色描述
            Text(role.role.characterDescription)
                .font(.body)
                .lineLimit(3)
            
//            // 角色标签
//            if !role.roleInfo.tags.isEmpty {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 8) {
//                        ForEach(role.roleInfo.tags, id: \.self) { tag in
//                            Text(tag)
//                                .font(.caption)
//                                .padding(.horizontal, 8)
//                                .padding(.vertical, 4)
//                                .background(Color.blue.opacity(0.1))
//                                .foregroundColor(.blue)
//                                .cornerRadius(12)
//                        }
//                    }
//                }
//            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}


