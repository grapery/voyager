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
    @State private var selectedStoryBoardId: Int64? = nil
    @Binding var showTabBar: Bool
    
    
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
                
                // 页面内容
                TabView(selection: $selectedIndex) {
                    // 动态页面
                    ScrollView {
                        VStack {
                            // 动态内容
                            LatestUpdatesView(
                                searchText: $searchText,
                                selectedTab: .constant(.Story),
                                tabs: [(type: FeedType.Story, title: "故事"), (type: FeedType.StoryRole, title: "角色")],
                                viewModel: viewModel,
                                errorTitle: $errorTitle,
                                errorMessage: $errorMessage,
                                showError: $showError,
                                selectedStoryBoardId: $selectedStoryBoardId
                            )
                        }
                    }
                    .tag(0)
                    
                    // 热点页面
                    TrendingContentView(viewModel: viewModel)
                    .tag(1)
                    
                    // 发现页面
                    DiscoveryView(viewModel: viewModel, messageText: "最近那边发生了什么事情？", showTabBar: $showTabBar)
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
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
    @Binding var selectedStoryBoardId: Int64?
    let sceneMediaContents: [SceneMediaContent]
    
    init(storyBoardActive: Common_StoryBoardActive?=nil, userId: Int64, viewModel: FeedViewModel, errorTitle: Binding<String>, errorMessage: Binding<String>, showError: Binding<Bool>, selectedStoryBoardId: Binding<Int64?>) {
        self._storyBoardActive = State(initialValue: storyBoardActive!)
        self.userId = userId
        self.viewModel = viewModel
        self.showStoryboardSummary = false
        self.showChildNodes = false
        self._errorTitle = errorTitle
        self._errorMessage = errorMessage
        self._showError = showError
        self._selectedStoryBoardId = selectedStoryBoardId
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
                selectedStoryBoardId = storyBoardActive.storyboard.storyBoardID
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showStoryboardSummary = true
                }
            }) {
                VStack(alignment: .leading, spacing: 12) {
                    // 顶部信息：创建者和故事信息
                    HStack(spacing: 8) {
                        // 故事缩略图和名称
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
                                // 创建者头像
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
                        if storyBoardActive.storyboard.currentUserStatus.isLiked{
                            if let err = await viewModel.unlikeStoryBoard(storyId: storyBoardActive.storyboard.storyID, boardId: storyBoardActive.storyboard.storyBoardID, userId: self.userId) {
                                await MainActor.run {
                                    errorTitle = "取消点赞失败"
                                    errorMessage = err.localizedDescription
                                    showError = true
                                }
                            } else {
                                storyBoardActive.storyboard.currentUserStatus.isLiked = false
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
                                storyBoardActive.storyboard.currentUserStatus.isLiked = true
                                storyBoardActive.totalLikeCount += 1
                            }
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: storyBoardActive.storyboard.currentUserStatus.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                        Text("\(storyBoardActive.totalLikeCount)")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(storyBoardActive.storyboard.currentUserStatus.isLiked ? Color.red : Color.theme.tertiaryText)
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
                    .foregroundColor(Color.theme.tertiaryText)
                    //.foregroundColor(showChildNodes ? Color.theme.accent : Color.theme.tertiaryText)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 6)
        .background(Color.theme.secondaryBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.theme.border, lineWidth: 0.5)
        )
        .shadow(color: Color.theme.primaryText.opacity(0.05), radius: 4, y: 2)
        .fullScreenCover(isPresented: $showStoryboardSummary) {
            if let storyBoardId = selectedStoryBoardId {
                StoryboardSummary(
                    storyBoardId: storyBoardId,
                    userId: userId,
                    viewModel: viewModel
                )
            }
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
    @Binding var selectedStoryBoardId: Int64?
    
    init(searchText: Binding<String>, 
         selectedTab: Binding<FeedType>, 
         tabs: [(type: FeedType, title: String)], 
         viewModel: FeedViewModel, 
         errorTitle: Binding<String>, 
         errorMessage: Binding<String>, 
         showError: Binding<Bool>,
         selectedStoryBoardId: Binding<Int64?>) {
        self._searchText = searchText
        self._selectedTab = selectedTab
        self.tabs = tabs
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self._errorTitle = errorTitle
        self._errorMessage = errorMessage
        self._showError = showError
        self._selectedStoryBoardId = selectedStoryBoardId
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
                showError: $showError,
                selectedStoryBoardId: $selectedStoryBoardId
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
            .padding(.vertical, 4)
            .onChange(of: selectedTab) { newTab in
                Task {
                    await viewModel.refreshData(type: newTab)
                }
            }
    }
}

// 下拉刷新控件
private struct FeedViewRefreshControl: View {
    @Binding var isRefreshing: Bool
    var threshold: CGFloat = 120
    let action: () async -> Void

    var body: some View {
        GeometryReader { geometry in
            let offset = geometry.frame(in: .global).minY
            if offset > threshold {
                Spacer()
                    .onAppear {
                        guard !isRefreshing else { return }
                        isRefreshing = true
                        Task { await action() }
                    }
            }
            HStack {
                Spacer()
                if isRefreshing {
                    ProgressView()
                }
                Spacer()
            }
        }
        .frame(height: 5)
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
    @Binding var selectedStoryBoardId: Int64?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                FeedViewRefreshControl(isRefreshing: $isRefreshing, threshold: 120) {
                    await viewModel.refreshData(type: selectedTab)
                    isRefreshing = false
                }
                FeedItemList(
                    viewModel: viewModel,
                    selectedTab: $selectedTab,
                    errorTitle: $errorTitle,
                    errorMessage: $errorMessage,
                    showError: $showError,
                    selectedStoryBoardId: $selectedStoryBoardId
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
    @Binding var selectedStoryBoardId: Int64?
    @State private var isLoadingMore = false

    var body: some View {
        LazyVStack(spacing: 4) {
            ForEach(viewModel.storyBoardActives, id: \.storyboard.storyBoardID) { active in
                FeedItemCard(
                    storyBoardActive: active,
                    userId: viewModel.user.userID,
                    viewModel: viewModel,
                    errorTitle: $errorTitle,
                    errorMessage: $errorMessage,
                    showError: $showError,
                    selectedStoryBoardId: $selectedStoryBoardId
                )
            }

            // 加载更多按钮
            if viewModel.hasMoreData && !viewModel.isLoading {
                Button(action: {
                    if !isLoadingMore {
                        isLoadingMore = true
                        Task {
                            await viewModel.loadMoreData(type: selectedTab)
                            isLoadingMore = false
                        }
                    }
                }) {
                    HStack {
                        Spacer()
                        if isLoadingMore {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text(isLoadingMore ? "加载中..." : "加载更多")
                            .font(.system(size: 12))
                            .foregroundColor(Color.gray)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
            }

            if viewModel.isLoading && !viewModel.isRefreshing {
                LoadingIndicator()
            }

            if !viewModel.hasMoreData && !viewModel.storyBoardActives.isEmpty {
                Text("没有更多了")
                    .font(.system(size: 12))
                    .foregroundColor(Color.gray)
                    .padding()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
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
                        
                        // 下划线指示器
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
                        
                        // 下划线指示器
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
                                try? await Task.sleep(nanoseconds: 500_000_000) // 添加轻微延迟以显示刷新效果
                                isRefreshing = false
                            }
                        }
                    ) {
                        VStack(alignment: .leading, spacing: 0) {
                            if isRefreshing {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        ProgressView()
                                        Text("正在刷新...")
                                            .font(.caption)
                                            .foregroundColor(Color.theme.tertiaryText)
                                    }
                                    .padding(.vertical, 20)
                                    Spacer()
                                }
                            }
                            
                            if viewModel.isLoadingTrending && !isRefreshing {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding(.vertical, 40)
                                    Spacer()
                                }
                            } else if viewModel.trendingStories.isEmpty && !viewModel.isLoadingTrending {
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
                            } else if !viewModel.trendingStories.isEmpty {
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
                                    
                                    if viewModel.isLoadingMoreTrending {
                                        HStack {
                                            Spacer()
                                            ProgressView()
                                                .padding()
                                            Spacer()
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
                                try? await Task.sleep(nanoseconds: 500_000_000) // 添加轻微延迟以显示刷新效果
                                isRefreshing = false
                            }
                        }
                    ) {
                        VStack(alignment: .leading, spacing: 0) {
                            if isRefreshing {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        ProgressView()
                                        Text("正在刷新...")
                                            .font(.caption)
                                            .foregroundColor(Color.theme.tertiaryText)
                                    }
                                    .padding(.vertical, 20)
                                    Spacer()
                                }
                            }
                            
                            if viewModel.isLoadingTrending && !isRefreshing {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding(.vertical, 40)
                                    Spacer()
                                }
                            } else if viewModel.trendingRoles.isEmpty && !viewModel.isLoadingTrending {
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
                            } else if !viewModel.trendingRoles.isEmpty {
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
                                    
                                    if viewModel.isLoadingMoreTrending {
                                        HStack {
                                            Spacer()
                                            ProgressView()
                                                .padding()
                                            Spacer()
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
            Task {
                if viewModel.trendingStories.isEmpty {
                    await viewModel.loadTrendingStories()
                }
                if viewModel.trendingRoles.isEmpty {
                    await viewModel.loadTrendingRoles()
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
                            Text(story.storyInfo.name)
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
                                await viewModel.unfollowStory(userId: viewModel.userId, storyId: story.storyInfo.id)
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
                                await viewModel.followStory(userId: viewModel.userId, storyId: story.storyInfo.id)
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

