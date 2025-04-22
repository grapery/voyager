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
    @State private var selectedIndex: Int = 0
    @State private var searchText = ""
    @State private var errorTitle: String = ""
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: FeedViewModel(user: user))
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
                .padding(.vertical, 12)
                
                // 页面内容
                TabView(selection: $selectedIndex) {
                    // 动态页面
                    ScrollView {
                        VStack {
                            // 搜索栏
                            CommonSearchBar(
                                searchText: $searchText,
                                placeholder: "发生了什么......."
                            )
                            
                            // 动态内容
                            LatestUpdatesView(
                                searchText: $searchText,
                                selectedTab: .constant(.Story),
                                tabs: [(type: FeedType.Story, title: "故事"), (type: FeedType.StoryRole, title: "角色")],
                                viewModel: viewModel,
                                errorTitle: $errorTitle,
                                errorMessage: $errorMessage,
                                showError: $showError
                            )
                        }
                    }
                    .tag(0)
                    
                    // 热点页面
                    ScrollView {
                        Text("热点内容")
                            .padding()
                    }
                    .tag(1)
                    
                    // 发现页面
                    DiscoveryView(viewModel: viewModel, messageText: "最近那边发生了什么事情？")
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Color.theme.background)
        }
        .alert(errorTitle, isPresented: $showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
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
    @State var storyBoardActive: Common_StoryBoardActive
    let userId: Int64
    @ObservedObject var viewModel: FeedViewModel
    @State private var showStoryboardSummary = false
    @State private var showChildNodes = false
    @Binding var errorTitle: String
    @Binding var errorMessage: String
    @Binding var showError: Bool
    let sceneMediaContents: [SceneMediaContent]
    
    init(storyBoardActive: Common_StoryBoardActive?=nil, userId: Int64, viewModel: FeedViewModel, errorTitle: Binding<String>, errorMessage: Binding<String>, showError: Binding<Bool>) {
        self._storyBoardActive = State(initialValue: storyBoardActive!)
        self.userId = userId
        self.viewModel = viewModel
        self.showStoryboardSummary = false
        self.showChildNodes = false
        self._errorTitle = errorTitle
        self._errorMessage = errorMessage
        self._showError = showError
        var tempSceneContents: [SceneMediaContent] = []
        let scenes = storyBoardActive!.storyboard.sences.list
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
        self.sceneMediaContents = tempSceneContents
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                showStoryboardSummary = true
            }) {
                VStack(alignment: .leading, spacing: 12) {
                    // 顶部信息：创建者和故事信息
                    HStack(spacing: 8) {
                        // 故事缩略图和名称
                        HStack(spacing: 4) {
                            HStack(spacing: 8) {
                                KFImage(URL(string: storyBoardActive.summary.storyAvatar))
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
                                // 创建者头像
                                KFImage(URL(string: storyBoardActive.creator.userAvatar))
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
                        if !self.sceneMediaContents.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 2) {
                                        ForEach(self.sceneMediaContents, id: \.id) { sceneContent in
                                            VStack(alignment: .leading, spacing: 2) {
                                                // 场景图片（取第一张）
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
                                                
                                                // 场景标题
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
                    .padding(.horizontal)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // 交互按钮
            HStack(spacing: 24) {
                // 点赞按钮
                Button(action: {
                    Task {
                        if storyBoardActive.isliked {
                            if let err = await viewModel.unlikeStoryBoard(storyId: storyBoardActive.storyboard.storyID, boardId: storyBoardActive.storyboard.storyBoardID, userId: self.userId) {
                                await MainActor.run {
                                    errorTitle = "取消点赞失败"
                                    errorMessage = err.localizedDescription
                                    showError = true
                                }
                            } else {
                                storyBoardActive.isliked = false
                                storyBoardActive.totalLikeCount -= 1
                            }
                        } else {
                            if let err = await viewModel.likeStoryBoard(storyId: storyBoardActive.storyboard.storyID, boardId: storyBoardActive.storyboard.storyBoardID, userId: self.userId) {
                                await MainActor.run {
                                    errorTitle = "点赞失败"
                                    errorMessage = err.localizedDescription
                                    showError = true
                                }
                            } else {
                                storyBoardActive.isliked = true
                                storyBoardActive.totalLikeCount += 1
                            }
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: storyBoardActive.isliked ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                        Text("\(storyBoardActive.totalLikeCount)")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(storyBoardActive.isliked ? Color.red : Color.theme.tertiaryText)
                }
                
                // 评论按钮
                Button(action: {
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 16))
                        Text("\(storyBoardActive.totalCommentCount)")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(Color.theme.tertiaryText)
                }
                
                // fork 按钮
                Button(action: {
                    withAnimation(.spring()) {
                        showChildNodes.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "signpost.right.and.left")
                            .font(.system(size: 16))
                        Text("\(storyBoardActive.totalForkCount)")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(showChildNodes ? Color.theme.accent : Color.theme.tertiaryText)
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
        .fullScreenCover(isPresented: $showStoryboardSummary) {
            StoryboardSummary(
                storyBoardId: storyBoardActive.storyboard.storyBoardID,
                userId: userId,
                viewModel: self.viewModel
            )
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
    @Binding var errorTitle: String
    @Binding var errorMessage: String
    @Binding var showError: Bool
    
    init(searchText: Binding<String>, selectedTab: Binding<FeedType>, tabs: [(type: FeedType, title: String)], viewModel: FeedViewModel, errorTitle: Binding<String>, errorMessage: Binding<String>, showError: Binding<Bool>) {
        self._searchText = searchText
        self._selectedTab = selectedTab
        self.tabs = tabs
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self._errorTitle = errorTitle
        self._errorMessage = errorMessage
        self._showError = showError
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CategoryTabsSection(selectedTab: $selectedTab, tabs: tabs, viewModel: viewModel)
            FeedContentSection(
                selectedTab: $selectedTab,
                isRefreshing: $isRefreshing,
                viewModel: viewModel,
                errorTitle: $errorTitle,
                errorMessage: $errorMessage,
                showError: $showError
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
    @Binding var errorTitle: String
    @Binding var errorMessage: String
    @Binding var showError: Bool
    
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
                    selectedTab: $selectedTab,
                    errorTitle: $errorTitle,
                    errorMessage: $errorMessage,
                    showError: $showError
                )
            }
        }
    }
}

// 动态列表
private struct FeedItemList: View {
    @ObservedObject var viewModel: FeedViewModel
    @Binding var selectedTab: FeedType
    @Binding var errorTitle: String
    @Binding var errorMessage: String
    @Binding var showError: Bool
    
    var body: some View {
        LazyVStack(spacing: 4) {
            ForEach(viewModel.storyBoardActives, id: \.storyboard.storyBoardID) { active in
                FeedItemCard(
                    storyBoardActive: active,
                    userId: viewModel.user.userID,
                    viewModel: viewModel,
                    errorTitle: $errorTitle,
                    errorMessage: $errorMessage,
                    showError: $showError
                )
                .onAppear {
                    checkAndLoadMore(active)
                }
            }
            
            if viewModel.isLoading && !viewModel.isRefreshing {
                LoadingIndicator()
            }
            
            if !viewModel.hasMoreData && !viewModel.storyBoardActives.isEmpty {
                Text("没有更多数据了")
                    .font(.system(size: 14))
                    .foregroundColor(Color.theme.tertiaryText)
                    .padding()
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
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.theme.accent))
            Spacer()
        }
        .padding()
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
    
    init(viewModel: FeedViewModel, messageText: String) {
        self.viewModel = viewModel
        self.messageText = ""
        self.messages = [ChatMessage]()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 内容区域
            VStack(spacing: 0) {
                // 聊天消息列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .padding(.horizontal, 16)
                                    .id(message.id)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                            
                            Color.clear
                                .frame(height: 10)
                                .id("bottom")
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .onChange(of: messages.count) { _ in
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                    .background(Color.theme.background)
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
                    
                    // 调整键盘高度的空间
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: keyboardHeight > 0 ? keyboardHeight - 45 : 0)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
            }
            
            // 输入栏 - 固定在底部
            VStack(spacing: 0) {
                Divider()
                
                HStack(alignment: .center, spacing: 8) {
                    // 左侧附加按钮
                    Button(action: {}) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                    .padding(.leading, 8)
                    
                    // 输入框
                    ZStack(alignment: .leading) {
                        if messageText.isEmpty {
                            Text("请输入您的问题...")
                                .foregroundColor(Color.gray.opacity(0.8))
                                .padding(.leading, 8)
                                .padding(.top, 8)
                                .padding(.bottom, 8)
                        }
                        
                        TextField("", text: $messageText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .focused($isFocused)
                            .onChange(of: isFocused) { focused in
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    isShowingKeyboard = focused
                                }
                            }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(18)
                    .padding(.vertical, 6)
                    
                    // 发送按钮
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20))
                            .foregroundColor(messageText.isEmpty ? Color.gray.opacity(0.6) : .blue)
                            .rotationEffect(.degrees(45))
                            .padding(8)
                    }
                    .disabled(messageText.isEmpty)
                    .padding(.trailing, 4)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white)
            }
            .padding(.bottom, isFocused ? (keyboardHeight > 0 ? 0 : 0) : 0)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            setupInitialMessages()
            setupKeyboardNotifications()
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
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
            return "你好！我是AI助手，很高兴为您服务。"
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

// 更新聊天气泡组件
private struct ChatBubble: View {
    let message: ChatMessage
    
    private var isFromCurrentUser: Bool {
        return message.msg.sender == 1 // 假设1是当前用户ID
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
