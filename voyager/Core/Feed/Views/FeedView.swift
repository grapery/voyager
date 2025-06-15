//
//  FeedView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI
import Kingfisher
import ActivityIndicatorView

enum FeedType{
    case Groups
    case Story
    case StoryRole
}
    
// 获取用户的关注以及用户参与的故事，以及用户关注或者参与的小组的故事动态。不可以用户关注用户，只可以关注小组或者故事,以及故事的角色
struct FeedView: View {
    @StateObject var viewModel: FeedViewModel
    @State private var selectedIndex: Int = 0
    @State private var searchText = ""
    @State private var errorTitle: String = ""
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @Binding var showTabBar: Bool
    @State private var hasInitialized = false
    
    init(user: User, showTabBar: Binding<Bool>) {
        self._viewModel = StateObject(wrappedValue: FeedViewModel(user: user))
        self._showTabBar = showTabBar
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack(spacing: 32) {
                    Button(action: { selectedIndex = 0 }) {
                        Text("动态")
                            .font(.system(size: 17))
                            .foregroundColor(selectedIndex == 0 ? Color.theme.primaryText : Color.theme.tertiaryText)
                            .fontWeight(selectedIndex == 0 ? .semibold : .regular)
                    }
                    
                    Button(action: { selectedIndex = 1 }) {
                        Text("热点")
                            .font(.system(size: 17))
                            .foregroundColor(selectedIndex == 1 ? Color.theme.primaryText : Color.theme.tertiaryText)
                            .fontWeight(selectedIndex == 1 ? .semibold : .regular)
                    }
                    
                    Button(action: { selectedIndex = 2 }) {
                        Text("发现")
                            .font(.system(size: 17))
                            .foregroundColor(selectedIndex == 2 ? Color.theme.primaryText : Color.theme.tertiaryText)
                            .fontWeight(selectedIndex == 2 ? .semibold : .regular)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                
                // 搜索栏
                CommonSearchBar(
                    searchText: $searchText,
                    placeholder: "发生了什么......."
                )
                .padding(.vertical, 4)
                
                ZStack {
                    
                        TabView(selection: $selectedIndex) {
                            // 动态页面
                            StoryActivesView(
                                viewModel: viewModel
                            )
                            .tag(0)
                            .onAppear {
                                print("StoryActivesView apear")
                                print("StoryActivesView apear ",viewModel.storyBoardActives.count)
                            }
                            
                            // 热点页面
                            TrendingContentView(viewModel: viewModel)
                                .tag(1)
                            
                            // 发现页面
                            DiscoveryView(viewModel: viewModel, messageText: "最近那边发生了什么事情？", showTabBar: $showTabBar)
                                .tag(2)
                        }
                        .onAppear {
                            print("TabView apear")
                            print("TabView apear ",viewModel.storyBoardActives.count)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        
                    }
                
            }
            .onAppear {
                print("FeedView apear")
                print("FeedView apear ",viewModel.storyBoardActives.count)
            }
            .background(Color.theme.background)
            .navigationDestination(for: Story.self) { story in
                StoryView(story: story, userId: viewModel.user.userID)
            }
        }
        .alert(errorTitle, isPresented: $showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

struct StoryActivesView: View {
    let selectedTab: FeedType = .Story
    let tabs: [(type: FeedType, title: String)] = [(type: FeedType.Story, title: "故事")]
    @ObservedObject var viewModel: FeedViewModel
    @State private var scrollPosition: Int? = nil

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(viewModel.storyBoardActives.enumerated()), id: \.element.storyboard.storyBoardID) { index, active in
                            FeedItemCard(
                                storyBoardActive: active,
                                userId: viewModel.user.userID,
                                viewModel: viewModel
                            )
                            .id(active.storyboard.storyBoardID)
                            .onAppear {
                                // 只做加载更多，不做 scrollTo
                                if index == viewModel.storyBoardActives.count - 2 {
                                    print("loading   next page:", index)
                                    if viewModel.hasMoreData && !viewModel.isLoadingMore {
                                        viewModel.isLoadingMore = true
                                        Task {
                                            await viewModel.loadMoreData(type: .Story)
                                            viewModel.isLoadingMore = false
                                        }
                                    }
                                }
                            }
                        }
                        // 没有更多数据提示
                        if !viewModel.hasMoreData && !viewModel.storyBoardActives.isEmpty {
                            Text("没有更多了")
                                .font(.system(size: 12))
                                .foregroundColor(Color.theme.primaryText).colorInvert()
                                .padding()
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }
                .refreshable {
                    viewModel.feedViewState.isRefreshing = true
                    Task {
                        print("refreshable call")
                        await viewModel.refreshData(type: selectedTab)
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        viewModel.feedViewState.isRefreshing = false
                    }
                }
//                .onChange(of: viewModel.storyBoardActives.count) { newCount in
//                    if let lastId = viewModel.storyBoardActives.last?.storyboard.storyBoardID {
//                        print("lastId : ",lastId)
//                        withAnimation {
//                            proxy.scrollTo(lastId, anchor: .bottom)
//                        }
//                    }
//                }
            }
        }
        .background(Color.theme.background)
        .onAppear {
            if !viewModel.feedViewState.hasInitialized {
                print("Initializing feed data for tab: \(selectedTab)")
                Task {
                    await viewModel.loadMoreData(type: selectedTab)
                    viewModel.feedViewState.hasInitialized = true
                }
            }
        }
        .alert("加载失败", isPresented: $viewModel.hasError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// 修改 LazyView 包装器
private struct LazyView<Content: View>: View {
    private let build: () -> Content
    
    init(_ build: @escaping () -> Content) {
        self.build = build
    }
    
    var body: some View {
        build()
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

// MARK: - 数据扩展
extension Common_StoryBoardActive {
    func toSceneMediaContents() -> [SceneMediaContent] {
        var tempSceneContents: [SceneMediaContent] = []
        let scenes = self.storyboard.sences.list
        for scene in scenes {
            let genResult = scene.genResult
            if let data = genResult.data(using: .utf8),
               let urls = try? JSONDecoder().decode([String].self, from: data) {
                var mediaItems: [MediaItem] = []
                for urlString in urls {
                    if let url = URL(string: urlString) {
                        let item = MediaItem(
                            id: UUID().uuidString,
                            type: urlString.hasSuffix(".mp4") ? .video : .image,
                            url: url,
                            thumbnail: urlString.hasSuffix(".mp4") ? URL(string: urlString) : nil
                        )
                        mediaItems.append(item)
                    }
                }
                let sceneContent = SceneMediaContent(
                    id: UUID().uuidString,
                    sceneTitle: scene.content,
                    mediaItems: mediaItems
                )
                tempSceneContents.append(sceneContent)
            }
        }
        return tempSceneContents
    }
}

// MARK: - 子视图
private struct FeedCardHeader: View {
    let storyBoardActive: Common_StoryBoardActive
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                HStack(spacing: 8) {
                    KFImage(URL(string: convertImagetoSenceImage(url: storyBoardActive.summary.storyAvatar, scene: .small)))
                        .cacheMemoryOnly()
                        .fade(duration: 0.25)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.theme.border, lineWidth: 0.5))
                    Text(storyBoardActive.summary.storyTitle)
                        .font(.system(size: 15))
                        .foregroundColor(Color.theme.accent)
                }
                Divider()
                HStack{
                    KFImage(URL(string: convertImagetoSenceImage(url: storyBoardActive.creator.userAvatar, scene: .small)))
                        .cacheMemoryOnly()
                        .fade(duration: 0.25)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.theme.border, lineWidth: 0.5))
                    Text(storyBoardActive.creator.userName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.theme.primaryText)
                    Text("创建")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.theme.primaryText)
                }
                .alignmentGuide(.bottom) { d in d[.bottom] }
            }
            Spacer()
            Text(formatTimeAgo(timestamp: storyBoardActive.storyboard.ctime))
                .font(.system(size: 12))
                .foregroundColor(Color.theme.tertiaryText)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

private struct FeedCardContent: View {
    let content: String
    var body: some View {
        VStack{
            Text(content)
                .font(.system(size: 15))
                .foregroundColor(Color.theme.primaryText)
                .lineLimit(3)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        
    }
    
}

private struct FeedCardMedia: View {
    let sceneMediaContents: [SceneMediaContent]
    var body: some View {
        if !sceneMediaContents.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(sceneMediaContents, id: \ .id) { sceneContent in
                        LazyVStack(alignment: .leading, spacing: 2) {
                            if let firstMedia = sceneContent.mediaItems.first {
                                KFImage(firstMedia.url)
                                    .placeholder {
                                        Rectangle()
                                            .fill(Color.theme.tertiaryBackground)
                                            .overlay(
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle())
                                            )
                                    }
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 140, height: 200)
                                    .clipped()
                                    .cornerRadius(6)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        print("Tapped scene: \(sceneContent.sceneTitle)")
                                    }
                            }
                            Text(sceneContent.sceneTitle)
                                .font(.system(size: 12))
                                .foregroundColor(Color.theme.secondaryText)
                                .lineLimit(2)
                                .frame(width: 140)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }
}

private struct FeedCardActions: View {
    @State var storyBoardActive: Common_StoryBoardActive
    let userId: Int64
    @ObservedObject var viewModel: FeedViewModel
    var body: some View {
        HStack(spacing: 4) {
            StorySubViewInteractionButton(
                icon: storyBoardActive.storyboard.currentUserStatus.isLiked ? "heart.fill" : "heart",
                count: "\(storyBoardActive.totalLikeCount)",
                color: storyBoardActive.storyboard.currentUserStatus.isLiked  ? Color.theme.likeIcon: Color.theme.tertiaryText,
                action: {
                    Task{
                        if storyBoardActive.storyboard.currentUserStatus.isLiked {
                            let _ = await viewModel.unlikeStoryBoard(storyId: storyBoardActive.storyboard.storyID, boardId: storyBoardActive.storyboard.storyBoardID, userId: userId)
                            storyBoardActive.totalLikeCount -= 1
                        }else{
                            let _ =  await viewModel.likeStoryBoard(storyId: storyBoardActive.storyboard.storyID, boardId: storyBoardActive.storyboard.storyBoardID, userId: userId)
                            storyBoardActive.totalLikeCount += 1
                        }
                    }
                }
            )
            StorySubViewInteractionButton(
                icon: "bubble.left",
                count: "\(storyBoardActive.totalCommentCount)",
                color: Color.theme.tertiaryText,
                action: {}
            )
            StorySubViewInteractionButton(
                icon: "signpost.right.and.left",
                count: "\(storyBoardActive.totalForkCount)",
                color: Color.theme.tertiaryText,
                action: {}
            )
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

// MARK: - 主卡片视图
private struct FeedItemCard: View {
    let storyBoardActive: Common_StoryBoardActive
    let userId: Int64
    @ObservedObject var viewModel: FeedViewModel
    let sceneMediaContents: [SceneMediaContent]

    init(storyBoardActive: Common_StoryBoardActive?=nil, userId: Int64, viewModel: FeedViewModel) {
        self.storyBoardActive = storyBoardActive!
        self.userId = userId
        self.viewModel = viewModel
        self.sceneMediaContents = storyBoardActive!.toSceneMediaContents()
    }

    var body: some View {
        NavigationLink(
            destination: {
                StoryboardSummary(
                    storyBoardId: storyBoardActive.storyboard.storyBoardID,
                    userId: userId,
                    viewModel: viewModel
                )
            }
        ) {
            VStack(alignment: .leading, spacing: 8) {
                FeedCardHeader(storyBoardActive: storyBoardActive)
                FeedCardContent(content: storyBoardActive.storyboard.content)
                FeedCardMedia(sceneMediaContents: sceneMediaContents)
                FeedCardActions(
                    storyBoardActive: storyBoardActive,
                    userId: userId,
                    viewModel: viewModel
                )
            }
            .padding()
            .padding(.vertical, 6)
            .background(Color.theme.secondaryBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.theme.border, lineWidth: 0.5)
            )
            .shadow(color: Color.theme.primaryText.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
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

// 分类标签区域
private struct CategoryTabsSection: View {
    @Binding var selectedTab: FeedType
    let tabs: [(type: FeedType, title: String)]
    
    var body: some View {
        CategoryTabs(selectedTab: $selectedTab, tabs: tabs)
            .padding(.vertical, 4)
    }
}

// 加载指示器
private struct LoadingIndicator: View {
    @State var isLoading: Bool
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                HStack {
                    ActivityIndicatorView(isVisible: $isLoading, type: .growingArc(.cyan))
                        .frame(width: 64, height: 64)
                        .foregroundColor(.cyan)
                }
                        .frame(height: 50)
                Text("加载中......")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
            }
            .frame(maxWidth: .infinity)
            Spacer()
        }
    }
}

// 发现视图
private struct DiscoveryView: View {
    @ObservedObject var viewModel: FeedViewModel
    @State private var messageText: String = ""
    @State private var messages: [ChatMessage]
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isFocused: Bool
    @State private var isShowingKeyboard = false
    @State private var navigateToStory = false
    @State private var selectedStory: Story?
    @Binding var showTabBar: Bool
    
    init(viewModel: FeedViewModel, messageText: String, showTabBar: Binding<Bool>) {
        self.viewModel = viewModel
        self.messageText = ""
        self.messages = [ChatMessage]()
        self._showTabBar = showTabBar
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 聊天消息区背景
            TrapezoidTriangles()
                .opacity(0.81)
                .ignoresSafeArea()
            // 内容区域
            VStack(spacing: 0) {
                // 聊天消息列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if messages.isEmpty {
                                // 空状态
                                VStack {
                                    Spacer()
                                    Text("没有聊天消息")
                                        .foregroundColor(.gray)
                                        .padding()
                                    Spacer()
                                }
                            } else {
                                ForEach(messages) { message in
                                    ChatBubble(message: message)
                                        .padding(.horizontal, 16)
                                        .id(message.id)
                                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                                        .onTapGesture {
                                            if message.msg.sender == 42 { // AI消息可点击查看故事
                                                handleMessageTap(message)
                                            }
                                        }
                                }
                                
                                Color.clear
                                    .frame(height: 10)
                                    .id("bottom")
                            }
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .onChange(of: messages.count) { _ in
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                    .background(Color.theme.background.opacity(0.85))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isFocused {
                            isFocused = false
                        }
                    }
                }
                
                Spacer(minLength: 0)
            }
            // 键盘隐藏按钮 - 只在键盘显示时出现
            if isFocused {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            isFocused = false
                        }) {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.gray.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 8)
                    }
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: keyboardHeight > 0 ? keyboardHeight - 45 : 0)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
            }
            // 新输入栏
            InputBar(
                text: $messageText,
                isFocused: $isFocused,
                onSend: sendMessage
            )
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(
            // 导航链接跳转到故事页
            NavigationLink(value: selectedStory) {
                EmptyView()
            }
        )
        .onAppear {
            self.showTabBar = false
            setupInitialMessages()
            setupKeyboardNotifications()
        }
        .onDisappear {
            self.showTabBar = true
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    private func handleMessageTap(_ message: ChatMessage) {
        print("tap message: ",message as Any)
    }
    
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.keyboardHeight = keyboardFrame.height
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                self.keyboardHeight = 0
            }
        }
    }
    
    private func setupInitialMessages() {
        var msg1 = Common_ChatMessage()
        msg1.message = "欢迎您来到AI世界，请问您有什么想要了解的事情呢？"
        msg1.sender = 42
        msg1.roleID = 42
        msg1.userID = 1
        self.messages.append(ChatMessage(id: 1, msg: msg1, status: .MessageSendSuccess))
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // 创建用户消息
        var userMsg = Common_ChatMessage()
        userMsg.message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        userMsg.sender = 1
        userMsg.roleID = 42
        userMsg.userID = 1
        
        // 添加用户消息到列表
        withAnimation {
            self.messages.append(ChatMessage(id: Int64(Date().timeIntervalSince1970), msg: userMsg, status: .MessageSendSuccess))
        }
        
        // 清空输入框
        let sentMessage = messageText
        messageText = ""
        
        // 模拟AI回复
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            var aiMsg = Common_ChatMessage()
            aiMsg.message = getAIResponse(to: sentMessage)
            aiMsg.sender = 42
            aiMsg.roleID = 42
            aiMsg.userID = 1
            
            withAnimation {
                self.messages.append(ChatMessage(id: Int64(Date().timeIntervalSince1970), msg: aiMsg, status: .MessageSendSuccess))
            }
        }
    }
    
    // 简单的AI回复逻辑
    private func getAIResponse(to message: String) -> String {
        let lowercasedMessage = message.lowercased()
        
        if lowercasedMessage.contains("你好") || lowercasedMessage.contains("嗨") || lowercasedMessage.contains("hi") {
            return "你好！我是AI助手，很高兴为您服务。点击此消息可以查看推荐故事。"
        } else if lowercasedMessage.contains("名字") {
            return "我是AI助手，您可以叫我小助手。"
        } else if lowercasedMessage.contains("天气") {
            return "抱歉，我目前无法获取实时天气信息。不过我可以回答您其他方面的问题。"
        } else if lowercasedMessage.contains("谢谢") || lowercasedMessage.contains("感谢") {
            return "不客气！有什么问题随时问我。"
        } else {
            return "我理解您说的是'你好'。请问还有其他我能帮助您的吗？"
        }
    }
}

// 新增 InputBar 组件
private struct InputBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var onSend: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: {}) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
            }
            .frame(width: 36, height: 36)

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text("请输入您的问题...")
                        .foregroundColor(Color.gray.opacity(0.8))
                        .padding(.leading, 4)
                }
                TextField("", text: $text)
                    .focused(isFocused)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
            }
            .background(Color(.systemGray6))
            .cornerRadius(18)

            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20))
                    .foregroundColor(text.isEmpty ? Color.gray.opacity(0.6) : .blue)
                    .rotationEffect(.degrees(45))
            }
            .frame(width: 36, height: 36)
            .disabled(text.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Color.white
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        )
        .padding(.horizontal, 8)
        .padding(.bottom, 0)
        .overlay(
            Divider(), alignment: .top
        )
    }
}

// 更新聊天气泡组件
private struct ChatBubble: View {
    let message: ChatMessage
    
    private var isFromCurrentUser: Bool {
        return message.msg.sender == 1 // 假设1是当前用户ID
    }
    
    private var isClickable: Bool {
        return !isFromCurrentUser // 只有AI消息可点击
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isFromCurrentUser {
                // AI头像
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text("AI")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
            } else {
                Spacer()
            }
            
            // 消息气泡
            Text(message.msg.message)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    isFromCurrentUser 
                        ? Color.blue.opacity(0.8)
                        : Color(.systemGray5)
                )
                .foregroundColor(isFromCurrentUser ? .white : .black)
                .cornerRadius(18)
                .overlay(
                    isClickable ? 
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        : nil
                )
            
            if isFromCurrentUser {
                // 用户头像
                Circle()
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text("我")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
            } else {
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

// 角色统计信息视图
private struct RoleStatsView: View {
    let role: StoryRole
    
    var body: some View {
        HStack(spacing: 16) {
            Label("\(role.role.likeCount)", systemImage: role.role.currentUserStatus.isLiked ? "heart.fill" : "heart")
                .font(.system(size: 12))
                .foregroundColor(Color.red)
            
            Label("\(role.role.followCount)", systemImage: role.role.currentUserStatus.isFollowed ? "bell.fill" : "bell")
                .font(.system(size: 12))
                .foregroundColor(Color.blue)

            Label("\(role.role.storyboardNum)", systemImage: "book")
                .font(.system(size: 12))
                .foregroundColor(Color.theme.tertiaryText)
        }
    }
}

// 角色关注按钮
private struct RoleFollowButton: View {
    let role: StoryRole
    let viewModel: FeedViewModel
    
    var body: some View {
        if role.role.currentUserStatus.isFollowed {
            Button {
                Task {
                    _ = await viewModel.unfollowStoryRole(userId: viewModel.user.userID, roleId: role.Id, storyId: role.role.storyID)
                    role.role.currentUserStatus.isFollowed = false
                }
            } label: {
                Text("已关注")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.theme.tertiaryText)
                    .frame(width: 50, height: 24)
                    .background(
                        Capsule()
                            .fill(Color.theme.secondaryBackground)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.theme.tertiaryText, lineWidth: 1)
                    )
            }
        } else {
            Button {
                Task {
                    _ = await viewModel.followStoryRole(userId: viewModel.user.userID, roleId: role.Id, storyId: role.role.storyID)
                    role.role.currentUserStatus.isFollowed = true
                }
            } label: {
                Text("关注")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 24)
                    .background(
                        Capsule()
                            .fill(Color.theme.accent)
                    )
            }
        }
    }
}

// 热门角色卡片
private struct TrendingRoleCard: View {
    let role: StoryRole
    @ObservedObject var viewModel: FeedViewModel
    @State private var navigateToRoleDetail = false
    
    var body: some View {
        Button(action: {
            navigateToRoleDetail = true
        }) {
            HStack(spacing: 16) {
                // 角色头像
                KFImage(URL(string: convertImagetoSenceImage(url: role.role.characterAvatar, scene: .small)))
                    .cacheMemoryOnly()
                    .fade(duration: 0.25)
                    .placeholder {
                        Rectangle()
                            .fill(Color.theme.tertiaryBackground)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // 角色信息
                VStack(alignment: .leading, spacing: 6) {
                    Text(role.role.characterName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.theme.primaryText)
                    
                    Text(role.role.characterDescription)
                        .font(.system(size: 14))
                        .foregroundColor(Color.theme.secondaryText)
                        .lineLimit(2)
                    
                    RoleStatsView(role: role)
                }
                
                Spacer()
                
                RoleFollowButton(role: role, viewModel: viewModel)
            }
            .padding(16)
            .background(Color.theme.secondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.theme.border, lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            NavigationLink(
                destination: StoryRoleDetailView(
                    roleId: role.Id,
                    userId: viewModel.user.userID,
                    role: role
                )
                .transition(.opacity)
                .animation(.easeInOut, value: navigateToRoleDetail),
                isActive: $navigateToRoleDetail,
                label: { EmptyView() }
            )
        )
    }
}

// 热点内容视图
private struct TrendingContentView: View {
    @ObservedObject var viewModel: FeedViewModel
    @State private var selectedTab = 0
    @State private var errorTitle: String = ""
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var isRefreshing = false
    @StateObject public var viewState = TrendingContentViewState()
    
    var body: some View {
        VStack(spacing: 0) {
            // 热点标签页切换
            HStack(spacing: 32) {
                Button(action: { 
                    withAnimation {
                        selectedTab = 0
                    } 
                }) {
                    VStack(spacing: 4) {
                        Text("热门故事")
                            .font(.system(size: 16))
                            .foregroundColor(selectedTab == 0 ? Color.theme.primaryText : Color.theme.tertiaryText)
                            .fontWeight(selectedTab == 0 ? .semibold : .regular)
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedTab == 0 ? Color.theme.accent : Color.clear)
                    }
                }
                Button(action: { 
                    withAnimation {
                        selectedTab = 1
                    }
                }) {
                    VStack(spacing: 4) {
                        Text("热门角色")
                            .font(.system(size: 16))
                            .foregroundColor(selectedTab == 1 ? Color.theme.primaryText : Color.theme.tertiaryText)
                            .fontWeight(selectedTab == 1 ? .semibold : .regular)
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedTab == 1 ? Color.theme.accent : Color.clear)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // 内容区域
            TabView(selection: $selectedTab) {
                // 热门故事
                ScrollView {
                    RefreshableScrollView(
                        isRefreshing: $isRefreshing,
                        onRefresh: {
                            Task {
                                await viewModel.loadTrendingStories()
                                try? await Task.sleep(nanoseconds: 500_000_000)
                                isRefreshing = false
                            }
                        }
                    ) {
                        VStack(alignment: .leading, spacing: 0) {
                            if viewModel.trendingStories.isEmpty {
                                VStack {
                                    Text("暂无热门故事")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color.theme.tertiaryText)
                                        .padding(.vertical, 40)
                                    Button("刷新") {
                                        Task {
                                            await viewModel.loadTrendingStories()
                                        }
                                    }
                                    .padding()
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                LazyVStack(alignment: .leading, spacing: 8) {
                                    ForEach(viewModel.trendingStories, id: \.Id) { story in
                                        TrendingStoryCard(story: story, viewModel: viewModel)
                                            .padding(.horizontal)
                                            .onAppear {
                                                if story.Id == viewModel.trendingStories.last?.Id && viewModel.hasMoreTrendingStories {
                                                    Task {
                                                        await viewModel.loadMoreTrendingStories()
                                                    }
                                                }
                                            }
                                    }
                                    if !viewModel.hasMoreTrendingStories && !viewModel.trendingStories.isEmpty {
                                        HStack {
                                            Spacer()
                                            Text("没有更多热门故事了")
                                                .font(.system(size: 14))
                                                .foregroundColor(Color.theme.tertiaryText)
                                                .padding()
                                            Spacer()
                                        }
                                    }
                                }
                                .padding(.vertical)
                            }
                        }
                    }
                }
                .tag(0)
                
                // 热门角色
                ScrollView {
                    RefreshableScrollView(
                        isRefreshing: $isRefreshing,
                        onRefresh: {
                            Task {
                                await viewModel.loadTrendingRoles()
                                try? await Task.sleep(nanoseconds: 500_000_000)
                                isRefreshing = false
                            }
                        }
                    ) {
                        VStack(alignment: .leading, spacing: 0) {
                            if viewModel.trendingRoles.isEmpty {
                                VStack {
                                    Text("暂无热门角色")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color.theme.tertiaryText)
                                        .padding(.vertical, 40)
                                    Button("刷新") {
                                        Task {
                                            await viewModel.loadTrendingRoles()
                                        }
                                    }
                                    .padding()
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                LazyVStack(alignment: .leading, spacing: 8) {
                                    ForEach(viewModel.trendingRoles, id: \.Id) { role in
                                        TrendingRoleCard(role: role, viewModel: viewModel)
                                            .padding(.horizontal)
                                            .onAppear {
                                                if role.Id == viewModel.trendingRoles.last?.Id && viewModel.hasMoreTrendingRoles {
                                                    Task {
                                                        await viewModel.loadMoreTrendingRoles()
                                                    }
                                                }
                                            }
                                    }
                                    if !viewModel.hasMoreTrendingRoles && !viewModel.trendingRoles.isEmpty {
                                        HStack {
                                            Spacer()
                                            Text("没有更多热门角色了")
                                                .font(.system(size: 14))
                                                .foregroundColor(Color.theme.tertiaryText)
                                                .padding()
                                            Spacer()
                                        }
                                    }
                                }
                                .padding(.vertical)
                            }
                        }
                    }
                }
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color.theme.background)
        .onAppear {
            // 只在第一次出现时初始化
            if !viewState.hasInitialized {
                viewState.hasInitialized = true
                Task {
                    if viewModel.trendingStories.isEmpty {
                        await viewModel.loadTrendingStories()
                    }
                    if viewModel.trendingRoles.isEmpty {
                        await viewModel.loadTrendingRoles()
                    }
                }
            }
        }
        .onChange(of: selectedTab) { newTab in
            // 只在标签切换时刷新对应数据
            if viewState.hasInitialized {
                Task {
                    if newTab == 0 && viewModel.trendingStories.isEmpty {
                        await viewModel.loadTrendingStories()
                    } else if newTab == 1 && viewModel.trendingRoles.isEmpty {
                        await viewModel.loadTrendingRoles()
                    }
                }
            }
        }
        .alert(errorTitle, isPresented: $showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

// 状态管理类
private class TrendingContentViewState: ObservableObject {
    @Published var hasInitialized = false
    @Published var lastRefreshedTab: Int?
    @Published var isRefreshing = false
}

// 热门故事卡片
private struct TrendingStoryCard: View {
    let story: Story
    @ObservedObject var viewModel: FeedViewModel
    @State private var navigateToStory = false
    
    var body: some View {
        Button(action: {
            navigateToStory = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // 故事头部信息
                ZStack(alignment: .topTrailing) {
                    HStack(spacing: 12) {
                        // 故事缩略图
                        KFImage(URL(string: convertImagetoSenceImage(url: story.storyInfo.avatar, scene: .small)))
                            .cacheMemoryOnly()
                            .fade(duration: 0.25)
                            .placeholder {
                                Rectangle()
                                    .fill(Color.theme.tertiaryBackground)
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        // 故事信息
                        VStack(alignment: .leading, spacing: 4) {
                            Text(story.storyInfo.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.theme.primaryText)
                                .lineLimit(1)
                            
                            Text(story.storyInfo.desc)
                                .font(.system(size: 14))
                                .foregroundColor(Color.theme.secondaryText)
                                .lineLimit(2)
                            // 统计数据
                            HStack(spacing: 16) {
                                Label("\(story.storyInfo.likeCount)", systemImage: story.storyInfo.currentUserStatus.isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.red)
                                
                                Label("\(story.storyInfo.followCount)", systemImage: story.storyInfo.currentUserStatus.isFollowed ? "bell.fill" : "bell")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.blue)
                                
                                Label("\(story.storyInfo.totalRoles)", systemImage: "person")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.theme.tertiaryText)
                                
                                Label("\(story.storyInfo.totalBoards)", systemImage: "book")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.theme.tertiaryText)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // 关注按钮 - 移到右上角
                    if story.storyInfo.currentUserStatus.isFollowed {
                        Button {
                            Task {
                                _ = await viewModel.unfollowStory(userId: viewModel.userId, storyId: story.storyInfo.id)
                                story.storyInfo.currentUserStatus.isFollowed = false
                            }
                        } label: {
                            Text("已关注")
                                .font(.system(size: 12))
                                .foregroundColor(Color.white)
                                .fontWeight(.medium)
                                .frame(width: 50, height: 24)
                                .background(Color.gray)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    } else {
                        Button {
                            Task {
                                _ = await viewModel.followStory(userId: viewModel.userId, storyId: story.storyInfo.id)
                                story.storyInfo.currentUserStatus.isFollowed = true
                            }
                        } label: {
                            Text("关注")
                                .font(.system(size: 12))
                                .foregroundColor(Color.white)
                                .fontWeight(.medium)
                                .frame(width: 50, height: 24)
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                
                // 标签栏
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["奇幻", "冒险", "热门", "创意"], id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 12))
                                .foregroundColor(Color.theme.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.theme.accent.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color.theme.secondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.theme.border, lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            NavigationLink(
                destination: StoryView(story: story, userId: viewModel.user.userID)
                .transition(.opacity)
                .animation(.easeInOut, value: navigateToStory),
                isActive: $navigateToStory,
                label: { EmptyView() }
            )
        )
    }
}

