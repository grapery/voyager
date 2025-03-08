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
                        // 处理添加操作
                    }
                )
                
                // 使用通用搜索栏
                CommonSearchBar(
                    searchText: $searchText,
                    placeholder: "搜索动态"
                )
                
                // 页面内容
                TabView(selection: $selectedIndex) {
                    // 最新动态页面
                    ScrollView {
                        LatestUpdatesView(
                            searchText: $searchText,
                            selectedTab: $selectedTab,
                            tabs: tabs,
                            userId: viewModel.user.userID
                        )
                        .tag(0)
                    }
                    
                    // 发现页面
                    ScrollView {
                        DiscoveryView(viewModel: self.viewModel, messageText: "")
                        .tag(1)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Color(hex: "1C1C1E"))
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
                    .foregroundColor(selectedIndex == 0 ? .white : .gray)
            }
            
            Button(action: { 
                withAnimation {
                    selectedIndex = 1
                }
            }) {
                Text("发现")
                    .font(.system(size: 17))
                    .foregroundColor(selectedIndex == 1 ? .white : .gray)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.primaryBackgroud)
    }
}

// 搜索栏
private struct FeedSearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            TextField("搜索", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(8)
            
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.trailing, 8)
        }
        .background(Color.primaryBackgroud)
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
                            .foregroundColor(selectedTab == tab.type ? .black : .gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedTab == tab.type ? Color.primaryGreenBackgroud : Color.primaryBackgroud)
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
    
    private var storyBoard: Common_StoryBoard {
        storyBoardActive.storyboard
    }
    
    private var hasParticipants: Bool {
        !storyBoardActive.users.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 左侧绿色装饰条
            HStack(spacing: 0) {
                
                VStack(alignment: .leading, spacing: 8) {
                    // 标题和头像
                    HStack {
                        Text(storyBoard.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        KFImage(URL(string: storyBoardActive.creator.userAvatar.isEmpty ? defaultAvator : storyBoardActive.creator.userAvatar))
                            .resizable()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    }
                    
                    // 内容
                    Text(storyBoard.content)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(3)
                    
                    // 场景数量（如果有）
                    if !storyBoard.sences.list.isEmpty {
                        HStack {
                            Image(systemName: "photo.stack")
                                .foregroundColor(.gray)
                                .font(.system(size: 12))
                            Text("共\(storyBoard.sences.list.count)个场景")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 2)
                    }
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    // 底部统计
                    HStack {
                        // 评论数
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left")
                            Text("\(storyBoardActive.totalCommentCount)")
                        }
                        .foregroundColor(.gray)
                        
                        
                        // 点赞数
                        HStack(spacing: 4) {
                            Image(systemName: storyBoardActive.isliked ? "heart.fill" : "heart")
                            Text("\(storyBoardActive.totalLikeCount)")
                        }
                        .foregroundColor(storyBoardActive.isliked ? .red : .gray)
                        
                        // 参与者头像
                        if hasParticipants {
                            HStack(spacing: -8) {
                                ForEach(storyBoardActive.users.prefix(3), id: \.userID) { participant in
                                    KFImage(URL(string: participant.userAvatar.isEmpty ? defaultAvator : participant.userAvatar))
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primaryBackgroud, lineWidth: 2)
                                        )
                                }
                                
                                if storyBoardActive.users.count > 3 {
                                    Text("+\(storyBoardActive.users.count - 3)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                        .padding(.leading, 4) 
                                }
                            }
                            .padding(.leading, 8)
                        }
                    }
                    .font(.system(size: 14))
                }
                .padding(12)
            }
        }
        .background(Color.primaryBackgroud)
        .cornerRadius(8)
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


// 最新动态视图
private struct LatestUpdatesView: View {
    @Binding var searchText: String
    @Binding var selectedTab: FeedType
    let tabs: [(type: FeedType, title: String)]
    let userId: Int64
    @StateObject private var viewModel: FeedListViewModel
    @State private var isRefreshing = false
    
    init(searchText: Binding<String>, selectedTab: Binding<FeedType>, tabs: [(type: FeedType, title: String)], userId: Int64) {
        self._searchText = searchText
        self._selectedTab = selectedTab
        self.tabs = tabs
        self.userId = userId
        self._viewModel = StateObject(wrappedValue: FeedListViewModel(userId: userId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 分类标签
            CategoryTabs(selectedTab: $selectedTab, tabs: tabs)
                .padding(.vertical, 8)
                .onChange(of: selectedTab) { newTab in
                    Task {
                        // 切换标签时刷新数据
                        await viewModel.refreshData(type: newTab)
                    }
                }
            
            // 内容列表
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
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.storyBoardActives, id: \.storyboard.storyBoardID) { active in
                            FeedItemCard(storyBoardActive: active)
                                .onAppear {
                                    // 当显示最后一个项目时加载更多
                                    if active.storyboard.storyBoardID == viewModel.storyBoardActives.last?.storyboard.storyBoardID {
                                        Task {
                                            await viewModel.loadMoreData(type: selectedTab)
                                        }
                                    }
                                }
                        }
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Color(hex: "1C1C1E"))
        .task {
            // 初始加载数据
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
        .background(Color(hex: "1C1C1E"))
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
        .background(Color(hex: "FAFDF2"))
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
                    .background(Color.primaryBackgroud)
                    .cornerRadius(16)
                    .foregroundColor(.white)
                
                Spacer()
            } else {
                Spacer()
                
                Text(message.msg.message)
                    .padding(12)
                    .background(Color.primaryGreenBackgroud)
                    .cornerRadius(16)
                    .foregroundColor(.black)
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
