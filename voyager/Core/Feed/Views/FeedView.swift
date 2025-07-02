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
private struct StoryInfoCapsule: View {
    let avatarUrl: String
    let title: String
    var body: some View {
        HStack(spacing: 6) {
            KFImage(URL(string: convertImagetoSenceImage(url: avatarUrl, scene: .small)))
                .cacheMemoryOnly()
                .fade(duration: 0.25)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 20, height: 20)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.theme.border, lineWidth: 0.5))
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.theme.primaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.theme.secondaryBackground))
        .overlay(Capsule().stroke(Color.theme.border, lineWidth: 0.5))
    }
}

private struct FeedCardHeader: View {
    let storyBoardActive: Common_StoryBoardActive
    var body: some View {
        HStack(spacing: 8) {
            // 故事图片
            KFImage(URL(string: convertImagetoSenceImage(url: storyBoardActive.summary.storyAvatar, scene: .small)))
                .cacheMemoryOnly()
                .fade(duration: 0.25)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.theme.border, lineWidth: 0.5))
            // 标题和时间
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 2) {
                    Text(String(storyBoardActive.summary.storyTitle.prefix(6)))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.theme.captionText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(".")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.theme.highlight)
                        .alignmentGuide(.firstTextBaseline) { d in d[.firstTextBaseline] }
                    Text(String(storyBoardActive.storyboard.title.prefix(6)))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.theme.captionText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Text(formatTimeAgo(timestamp: storyBoardActive.storyboard.ctime))
                    .font(.system(size: 12))
                    .foregroundColor(Color.theme.tertiaryText)
            }
            .frame(height: 32, alignment: .center)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}

private struct FeedCardContent: View {
    let content: String
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(content)
                .font(.system(size: 15))
                .foregroundColor(Color.theme.primaryText)
                .lineLimit(3)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
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
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
    }
}

private struct FeedCardActions: View {
    @Binding var storyBoardActive: Common_StoryBoardActive
    let userId: Int64
    @ObservedObject var viewModel: FeedViewModel
    var showStoryInfo: Bool = false
    let creatorAvatar: String?
    let creatorName: String?
    var body: some View {
        HStack(spacing: 8) {
            StorySubViewInteractionButton(
                icon: storyBoardActive.storyboard.currentUserStatus.isLiked ? "heart.fill" : "heart",
                count: "\(storyBoardActive.totalLikeCount)",
                color: storyBoardActive.storyboard.currentUserStatus.isLiked  ? Color.theme.likeIcon: Color.theme.tertiaryText,
                action: {
                    Task{
                        if storyBoardActive.storyboard.currentUserStatus.isLiked {
                            let _ = await viewModel.unlikeStoryBoard(storyId: storyBoardActive.storyboard.storyID, boardId: storyBoardActive.storyboard.storyBoardID, userId: userId)
                            storyBoardActive.totalLikeCount -= 1
                            storyBoardActive.storyboard.currentUserStatus.isLiked = false
                        }else{
                            let _ =  await viewModel.likeStoryBoard(storyId: storyBoardActive.storyboard.storyID, boardId: storyBoardActive.storyboard.storyBoardID, userId: userId)
                            storyBoardActive.totalLikeCount += 1
                            storyBoardActive.storyboard.currentUserStatus.isLiked = true
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
            // 右下角显示创作者信息胶囊
            if showStoryInfo, let avatar = creatorAvatar, let name = creatorName {
                StoryInfoCapsule(avatarUrl: avatar, title: name)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}

// MARK: - 主卡片视图
private struct FeedItemCard: View {
    @State var storyBoardActive: Common_StoryBoardActive
    let userId: Int64
    @ObservedObject var viewModel: FeedViewModel
    @State private var sceneMediaContents: [SceneMediaContent]

    init(storyBoardActive: Common_StoryBoardActive?=nil, userId: Int64, viewModel: FeedViewModel) {
        self._storyBoardActive = State(initialValue: storyBoardActive!)
        self.userId = userId
        self.viewModel = viewModel
        self._sceneMediaContents = State(initialValue: storyBoardActive!.toSceneMediaContents())
    }

    var body: some View {
        NavigationLink(
            destination: {
                StoryboardSummary(
                    storyBoardId: storyBoardActive.storyboard.storyBoardID,
                    userId: userId,
                    viewModel: viewModel
                )
                .onDisappear {
                    // 当StoryboardSummary消失时，同步更新数据
                    syncDataFromViewModel()
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 4) {
                FeedCardHeader(storyBoardActive: storyBoardActive)
                FeedCardContent(content: storyBoardActive.storyboard.content)
                FeedCardMedia(sceneMediaContents: sceneMediaContents)
                FeedCardActions(
                    storyBoardActive: $storyBoardActive,
                    userId: userId,
                    viewModel: viewModel,
                    showStoryInfo: true,
                    creatorAvatar: storyBoardActive.creator.userAvatar,
                    creatorName: storyBoardActive.creator.userName
                )
            }
            .padding(8)
            .background(Color.theme.secondaryBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.theme.border, lineWidth: 0.5)
            )
            .shadow(color: Color.theme.primaryText.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // 每次出现时同步数据
            syncDataFromViewModel()
        }
    }
    
    // 从ViewModel同步数据到本地状态
    private func syncDataFromViewModel() {
        if let updatedActive = viewModel.storyBoardActives.first(where: { $0.storyboard.storyBoardID == storyBoardActive.storyboard.storyBoardID }) {
            storyBoardActive = updatedActive
            sceneMediaContents = updatedActive.toSceneMediaContents()
        }
    }
}

// 优化搜索栏组件
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.theme.tertiaryText)
                .padding(.leading, 8)
            
            TextField("请输入您的问题...", text: $text)
                .font(.system(size: 16))
                .foregroundColor(Color.theme.inputText)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.theme.tertiaryText)
                        .padding(.trailing, 8)
                }
            }
        }
        .frame(height: 36)
        .background(Color.theme.inputBackground)
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


// 热门角色卡片
private struct TrendingRoleCard: View {
    let role: StoryRole
    @ObservedObject var viewModel: FeedViewModel
    @State private var navigateToRoleDetail = false
    
    var body: some View {
        Button(action: {
            navigateToRoleDetail = true
        }) {
            HStack(alignment: .top, spacing: 8) {
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
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                // 右侧内容区
                ZStack(alignment: .topTrailing) {
                    VStack(alignment: .leading, spacing: 6) {
                        // 名称和关注按钮同一行
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(role.role.characterName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.theme.primaryText)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            // 关注按钮，2. 与名称基线对齐
                            RoleFollowButton(role: role, viewModel: viewModel)
                                .alignmentGuide(.firstTextBaseline) { d in d[.firstTextBaseline] }
                        }
                        // 角色描述，3. 宽度不超过关注按钮左侧
                        Text(role.role.characterDescription)
                            .font(.system(size: 14))
                            .foregroundColor(Color.theme.secondaryText)
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        // 统计栏
                        RoleStatsView(role: role)
                            .padding(.top, 2)
                    }
                }
            }
            .padding(16)
            .background(Color.theme.secondaryBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
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
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        // 故事信息
                        VStack(alignment: .leading, spacing: 4) {
                            Text(story.storyInfo.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.theme.primaryText)
                                .lineLimit(1)
                            
                            Text(story.storyInfo.desc)
                                .font(.system(size: 14))
                                .foregroundColor(Color.theme.secondaryText)
                                .lineLimit(1)
                            // 统计数据
                            HStack(spacing: 16) {
                                Label("\(story.storyInfo.likeCount)", systemImage: story.storyInfo.currentUserStatus.isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.theme.error)
                                
                                Label("\(story.storyInfo.followCount)", systemImage: story.storyInfo.currentUserStatus.isFollowed ? "bell.fill" : "bell")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.theme.accent)
                                
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
                                .foregroundColor(Color.theme.primaryText)
                                .fontWeight(.medium)
                                .frame(width: 50, height: 24)
                                .background(Color.theme.secondaryBackground)
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
                                .foregroundColor(Color.theme.primaryText)
                                .fontWeight(.medium)
                                .frame(width: 50, height: 24)
                                .background(Color.theme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                
//                // 标签栏
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 8) {
//                        ForEach(["奇幻", "冒险", "热门", "创意"], id: \.self) { tag in
//                            Text(tag)
//                                .font(.system(size: 12))
//                                .foregroundColor(Color.theme.accent)
//                                .padding(.horizontal, 10)
//                                .padding(.vertical, 4)
//                                .background(Color.theme.accent.opacity(0.1))
//                                .cornerRadius(12)
//                        }
//                    }
//                }
            }
            .padding(12)
            .background(Color.theme.secondaryBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.theme.border, lineWidth: 0.5)
            )
            .shadow(color: Color.theme.primaryText.opacity(0.05), radius: 2, x: 0, y: 1)
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

