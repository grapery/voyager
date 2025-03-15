//
//  FeedView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI
import Kingfisher

enum FeedType{
    case Groups
    case Story
    case StoryRole
}
    
// 获取用户的关注以及用户参与的故事，以及用户关注或者参与的小组的故事动态。不可以用户关注用户，只可以关注小组或者故事,以及故事的角色
struct FeedView: View {
    @StateObject var viewModel: FeedViewModel
    @State private var selectedTab: FeedType = .Story
    @State private var searchText = ""
    @State private var selectedIndex: Int = 0
    @State private var isRefreshing = false
    
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: FeedViewModel(user: user))
    }
    
    // 定义标签页数组
    let tabs: [(type: FeedType, title: String)] = [
        (.Story, "故事"),
        (.StoryRole, "角色")
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 使用通用导航栏
                CommonNavigationBar(
                    title: "动态",
                    onAddTapped: {
                        selectedIndex = 0
                    }
                )
                
                // 页面内容
                TabView(selection: $selectedIndex) {
                    // 最新动态页面
                    ScrollView {
                        // 使用通用搜索栏
                        CommonSearchBar(
                            searchText: $searchText,
                            placeholder: "发生了什么......."
                        )
                        LatestUpdatesView(
                            searchText: $searchText,
                            selectedTab: $selectedTab,
                            tabs: tabs,
                            viewModel: viewModel
                        )
                        .tag(0)
                    }
                    
                    // 发现页面
                    ScrollView {
                        DiscoveryView(viewModel: viewModel, messageText: "最近那边发生了什么事情？")
                        .tag(1)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Color.theme.background)
        }
    }
}

// 顶部导航栏
private struct TopNavigationBar: View {
    @Binding var selectedIndex: Int
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: { 
                withAnimation {
                    selectedIndex = 0
                }
            }) {
                Text("最新动态")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(selectedIndex == 0 ? Color.theme.primaryText : Color.theme.tertiaryText)
            }
            
            Button(action: { 
                withAnimation {
                    selectedIndex = 1
                }
            }) {
                Text("发现")
                    .font(.system(size: 17))
                    .foregroundColor(selectedIndex == 1 ? Color.theme.primaryText : Color.theme.tertiaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.theme.secondaryBackground)
    }
}

// 搜索栏
private struct FeedSearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            TextField("搜索", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(Color.theme.inputText)
                .padding(8)
            
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.theme.tertiaryText)
                .padding(.trailing, 8)
        }
        .background(Color.theme.inputBackground)
        .cornerRadius(20)
    }
}

// 分类标签
private struct CategoryTabs: View {
    @Binding var selectedTab: FeedType
    let tabs: [(type: FeedType, title: String)]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(tabs, id: \.type) { tab in
                    Button(action: { selectedTab = tab.type }) {
                        Text(tab.title)
                            .font(.system(size: 14))
                            .foregroundColor(selectedTab == tab.type ? Color.theme.primaryText : Color.theme.tertiaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedTab == tab.type ? Color.theme.accent.opacity(0.1) : Color.theme.secondaryBackground)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// Feed 内容卡片
private struct FeedItemCard: View {
    let storyBoardActive: Common_StoryBoardActive
    let userId: Int64
    @ObservedObject var viewModel: FeedViewModel
    @State private var showComments = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部信息：创建者和故事信息
            HStack(spacing: 8) {
                // 故事缩略图和名称
                HStack(spacing: 4) {
                    KFImage(URL(string: storyBoardActive.summary.storyAvatar))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.theme.border, lineWidth: 0.5))
                    
                    Text(storyBoardActive.summary.storyTitle)
                        .font(.system(size: 14))
                        .foregroundColor(Color.theme.accent)
                    Text("@")
                        .foregroundColor(Color.theme.tertiaryText)
                    // 创建者头像
                    KFImage(URL(string: storyBoardActive.creator.userAvatar))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.theme.border, lineWidth: 0.5))
                    
                    Text(storyBoardActive.creator.userName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.theme.primaryText)
                }
                
                Spacer()
                
                // 发布时间
                Text(formatTimeAgo(timestamp: storyBoardActive.storyboard.ctime))
                    .font(.system(size: 12))
                    .foregroundColor(Color.theme.tertiaryText)
            }
            .padding(.horizontal)
            
            // 故事板内容
            VStack(alignment: .leading, spacing: 8) {
                Text(storyBoardActive.storyboard.content)
                    .font(.system(size: 15))
                    .foregroundColor(Color.theme.primaryText)
                    .lineLimit(3)
                
//                if !storyBoardActive.images.isEmpty {
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        HStack(spacing: 8) {
//                            ForEach(storyBoardActive.storyboard.sences.list, id: \.self) { imageUrl in
//                                KFImage(URL(string: imageUrl))
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fill)
//                                    .frame(width: 120, height: 120)
//                                    .cornerRadius(8)
//                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.theme.border, lineWidth: 0.5))
//                            }
//                        }
//                    }
//                }
            }
            .padding(.horizontal)
            
            // 交互按钮
            HStack(spacing: 24) {
                // 评论按钮
                Button(action: {
                    showComments = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 16))
                        Text("\(storyBoardActive.totalCommentCount)")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(Color.theme.tertiaryText)
                }
                
                // 点赞按钮
                Button(action: {
                    Task {
                        if storyBoardActive.isliked {
                            await viewModel.unlikeStoryBoard(storyBoardId: storyBoardActive.storyboard.storyBoardID)
                        } else {
                            await viewModel.likeStoryBoard(storyBoardId: storyBoardActive.storyboard.storyBoardID)
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: storyBoardActive.isliked ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                        Text("\(storyBoardActive.totalLikeCount)")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(storyBoardActive.isliked ? Color.theme.accent : Color.theme.tertiaryText)
                }
                
                Spacer()
                
                // 分享按钮
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(Color.theme.tertiaryText)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color.theme.secondaryBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.theme.border, lineWidth: 0.5)
        )
        .shadow(color: Color.theme.primaryText.opacity(0.05), radius: 4, y: 2)
        .sheet(isPresented: $showComments) {
            CommentsView(
                storyBoardId: storyBoardActive.storyboard.storyBoardID,
                userId: userId,
                viewModel: viewModel
            )
        }
    }
}

// 评论视图
struct CommentsView: View {
    let storyBoardId: Int64
    let userId: Int64
    @ObservedObject var viewModel: FeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var commentText = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack {
                // 评论列表
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.comments) { comment in
                            CommentCell(comment: comment)
                        }
                    }
                    .padding()
                }
                
                // 评论输入框
                HStack {
                    TextField("添加评论...", text: $commentText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button(action: {
                        Task {
                            await sendComment()
                        }
                    }) {
                        Text("发送")
                            .foregroundColor(.blue)
                    }
                    .padding(.trailing)
                    .disabled(commentText.isEmpty || isLoading)
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .shadow(radius: 2)
            }
            .navigationTitle("评论")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("关闭") {
                dismiss()
            })
            .onAppear {
                Task {
                    await viewModel.fetchComments(storyBoardId: storyBoardId)
                }
            }
        }
    }
    
    private func sendComment() async {
        guard !commentText.isEmpty else { return }
        isLoading = true
        await viewModel.addComment(storyBoardId: storyBoardId, content: commentText)
        commentText = ""
        isLoading = false
    }
}

// 评论单元格
struct CommentCell: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            KFImage(URL(string: comment.commentUser.avatar))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(comment.commentUser.name)
                    .font(.system(size: 14, weight: .medium))
                
                Text(comment.realComment.content)
                    .font(.system(size: 14))
                
                Text(formatTimeAgo(timestamp: comment.realComment.ctime))
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

// 优化搜索栏组件
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 8)
            
            TextField("请输入您的问题...", text: $text)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .padding(.trailing, 8)
                }
            }
        }
        .frame(height: 36)
        .background(Color.primaryBackgroud)
        .cornerRadius(18)
    }
}

// 最新动态主视图
private struct LatestUpdatesView: View {
    @Binding var searchText: String
    @Binding var selectedTab: FeedType
    let tabs: [(type: FeedType, title: String)]
    @ObservedObject var viewModel: FeedViewModel
    @State private var isRefreshing = false
    
    init(searchText: Binding<String>, selectedTab: Binding<FeedType>, tabs: [(type: FeedType, title: String)], viewModel: FeedViewModel) {
        self._searchText = searchText
        self._selectedTab = selectedTab
        self.tabs = tabs
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CategoryTabsSection(selectedTab: $selectedTab, tabs: tabs, viewModel: viewModel)
            FeedContentSection(
                selectedTab: $selectedTab,
                isRefreshing: $isRefreshing,
                viewModel: viewModel
            )
        }
        .background(Color.theme.background)
        .task {
            if viewModel.storyBoardActives.isEmpty {
                await viewModel.refreshData(type: selectedTab)
            }
        }
        .alert("加载失败", isPresented: $viewModel.hasError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// 分类标签区域
private struct CategoryTabsSection: View {
    @Binding var selectedTab: FeedType
    let tabs: [(type: FeedType, title: String)]
    @ObservedObject var viewModel: FeedViewModel
    
    var body: some View {
        CategoryTabs(selectedTab: $selectedTab, tabs: tabs)
            .padding(.vertical, 8)
            .onChange(of: selectedTab) { newTab in
                Task {
                    await viewModel.refreshData(type: newTab)
                }
            }
    }
}

// 内容列表区域
private struct FeedContentSection: View {
    @Binding var selectedTab: FeedType
    @Binding var isRefreshing: Bool
    @ObservedObject var viewModel: FeedViewModel
    
    var body: some View {
        ScrollView {
            RefreshableScrollView(
                isRefreshing: $isRefreshing,
                onRefresh: {
                    Task {
                        await viewModel.refreshData(type: selectedTab)
                        isRefreshing = false
                    }
                }
            ) {
                FeedItemList(
                    viewModel: viewModel,
                    selectedTab: $selectedTab
                )
            }
        }
    }
}

// 动态列表
private struct FeedItemList: View {
    @ObservedObject var viewModel: FeedViewModel
    @Binding var selectedTab: FeedType
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.storyBoardActives, id: \.storyboard.storyBoardID) { active in
                FeedItemCard(
                    storyBoardActive: active,
                    userId: viewModel.user.userID,
                    viewModel: viewModel
                )
                .onAppear {
                    checkAndLoadMore(active)
                }
            }
            
            if viewModel.isLoading {
                LoadingIndicator()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func checkAndLoadMore(_ active: Common_StoryBoardActive) {
        if active.storyboard.storyBoardID == viewModel.storyBoardActives.last?.storyboard.storyBoardID {
            Task {
                await viewModel.loadMoreData(type: selectedTab)
            }
        }
    }
}

// 加载指示器
private struct LoadingIndicator: View {
    var body: some View {
        ProgressView()
            .padding()
    }
}

// 发现视图
private struct DiscoveryView: View {
    @ObservedObject var viewModel: FeedViewModel
    @State private var messageText: String = ""
    @State private var messages: [ChatMessage]
    
    init(viewModel: FeedViewModel, messageText: String) {
        self.viewModel = viewModel
        self.messageText = ""
        self.messages = [ChatMessage]()
    }
    var body: some View {
        VStack(spacing: 0) {
            // 聊天内容区域
            ScrollView {
                LazyVStack(spacing: 16) {
                    // AI助手头部信息
                    AIChatHeader()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    
                    // 聊天消息列表
                    ForEach(messages) { message in
                        ChatBubble(message: message)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 12)
            }
            
            // 底部输入框
            ChatInputBar(text: $messageText) {
                sendMessage()
            }
        }
        .onAppear(){
            var msg1 = Common_ChatMessage()
            msg1.message = "欢迎您来到AI世界，请问您有什么想要了解的事情呢？"
            msg1.sender = 42
            msg1.roleID = 42
            msg1.userID = 1
            var msg2 = Common_ChatMessage()
            msg2.message = "你叫什么名字？"
            msg2.sender = 1
            msg2.roleID = 42
            msg2.userID = 1
            self.messages.append(ChatMessage(id: 1, msg: msg1,status: .MessageSendSuccess))
            self.messages.append(ChatMessage(id: 1, msg: msg2,status: .MessageSendSuccess))
        }
        .background(Color.theme.background)
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        messageText = ""
    }

    private func getChatHistory(){
        // 获取聊天历史
    }
}

// AI助手头部信息
private struct AIChatHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            // 左侧绿色装饰条
            Rectangle()
                .fill(Color.primaryGreenBackgroud.opacity(0.3))
                .frame(width: 4)
            
            // AI头像
            Image("ai_avatar")
                .resizable()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text("AI故事助手")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("欢迎大家来一起创作好玩的故事吧！")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color.theme.background)
        .cornerRadius(8)
    }
}

// 聊天气泡
private struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.msg.sender == message.msg.roleID{
                KFImage(URL(string: defaultAvator))
                    .resizable()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                
                Text(message.msg.message)
                    .padding(12)
                    .background(Color.theme.secondaryBackground)
                    .cornerRadius(16)
                    .foregroundColor(Color.theme.primaryText)
                
                Spacer()
            } else {
                Spacer()
                
                Text(message.msg.message)
                    .padding(12)
                    .background(Color.theme.accent)
                    .cornerRadius(16)
                    .foregroundColor(Color.theme.buttonText)
            }
        }
    }
}

// 底部输入框
private struct ChatInputBar: View {
    @Binding var text: String
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 输入框
            TextField("请输入您的问题...", text: $text)
                .padding(12)
                .background(Color.white)
                .cornerRadius(20)
            
            // 发送按钮
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(Color.primaryGreenBackgroud)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.primaryBackgroud)
    }
}
