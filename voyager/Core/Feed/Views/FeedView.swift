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
    @State var storyBoardActive: Common_StoryBoardActive
    let userId: Int64
    @ObservedObject var viewModel: FeedViewModel
    @State private var showStoryboardSummary = false
    let sceneMediaContents: [SceneMediaContent]
    
    init(storyBoardActive: Common_StoryBoardActive?=nil, userId: Int64, viewModel: FeedViewModel) {
        self._storyBoardActive = State(initialValue: storyBoardActive!)
        self.userId = userId
        self.viewModel = viewModel
        self.showStoryboardSummary = false
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
                            KFImage(URL(string: storyBoardActive.summary.storyAvatar))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 32, height: 32)
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
                                .frame(width: 20, height: 20)
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
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                }
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
                            await viewModel.unlikeStoryBoard(storyId:storyBoardActive.storyboard.storyID, boardId: storyBoardActive.storyboard.storyBoardID,userId: self.userId)
                            storyBoardActive.isliked = false
                            storyBoardActive.totalLikeCount -= 1
                        } else {
                            await viewModel.likeStoryBoard(storyId:storyBoardActive.storyboard.storyID,boardId: storyBoardActive.storyboard.storyBoardID,userId: self.userId)
                            storyBoardActive.isliked = true
                            storyBoardActive.totalLikeCount += 1
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
                    print("fork button taped")
                }) {
                    Image(systemName: "signpost.right.and.left")
                        .font(.system(size: 16))
                        .foregroundColor(Color.theme.tertiaryText)
                    Text("\(storyBoardActive.totalForkCount)")
                        .font(.system(size: 14))
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
        LazyVStack(spacing: 4) {
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
    
    init(viewModel: FeedViewModel, messageText: String) {
        self.viewModel = viewModel
        self.messageText = ""
        self.messages = [ChatMessage]()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack {
                Text("动态")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color.theme.primaryText)
                
                Spacer()
                
                Button(action: {
                    // Add new post action
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.theme.accent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
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
            ChatInputBar(text: $messageText, onSend: sendMessage)
        }
        .onAppear {
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
            self.messages.append(ChatMessage(id: 1, msg: msg1, status: .MessageSendSuccess))
            self.messages.append(ChatMessage(id: 1, msg: msg2, status: .MessageSendSuccess))
        }
        .background(Color.theme.background)
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        messageText = ""
    }
}

// AI助手头部信息
private struct AIChatHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("AI故事助手")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color.theme.primaryText)
            
            Text("欢迎大家来一起创作好玩的故事吧！")
                .font(.system(size: 16))
                .foregroundColor(Color.theme.secondaryText)
                .multilineTextAlignment(.center)
            
            Image("ai_avatar")
                .resizable()
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.theme.accent, lineWidth: 2)
                )
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.theme.secondaryBackground)
        .cornerRadius(16)
    }
}

// 聊天气泡
private struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.msg.sender == message.msg.roleID {
                // AI消息
                HStack(alignment: .top, spacing: 12) {
                    KFImage(URL(string: defaultAvator))
                        .resizable()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.theme.border, lineWidth: 1)
                        )
                    
                    Text(message.msg.message)
                        .font(.system(size: 16))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.theme.secondaryBackground)
                        .cornerRadius(20)
                        .foregroundColor(Color.theme.primaryText)
                    
                    Spacer()
                }
            } else {
                // 用户消息
                HStack(alignment: .top, spacing: 12) {
                    Spacer()
                    
                    Text(message.msg.message)
                        .font(.system(size: 16))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.theme.accent)
                        .cornerRadius(20)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// 底部输入框
private struct ChatInputBar: View {
    @Binding var text: String
    @State private var isShowingInput = false
    @State private var isShowingImagePicker = false
    @State private var selectedImages: [UIImage]? = nil
    @FocusState private var isFocused: Bool
    let onSend: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if !isShowingInput {
                // 未展开状态 - 显示占位按钮
                Button(action: {
                    isShowingInput = true
                    isFocused = true
                }) {
                    HStack {
                        Image(systemName: "text.bubble")
                            .foregroundColor(Color.theme.tertiaryText)
                        Text("请输入您的问题...")
                            .foregroundColor(Color.theme.tertiaryText)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.theme.secondaryBackground)
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.theme.border, lineWidth: 1)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            } else {
                // 展开状态 - 显示完整输入栏
                VStack(spacing: 12) {
                    // 选中的图片预览
                    if let images = selectedImages, !images.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(images.indices, id: \.self) { index in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: images[index])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        
                                        Button(action: {
                                            selectedImages?.remove(at: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(Color.theme.tertiaryText)
                                                .font(.system(size: 20))
                                                .background(Color.white)
                                                .clipShape(Circle())
                                        }
                                        .padding(4)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        // 图片选择按钮
                        Button(action: {
                            isShowingImagePicker = true
                        }) {
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                                .foregroundColor(Color.theme.accent)
                                .frame(width: 44, height: 44)
                                .background(Color.theme.secondaryBackground)
                                .clipShape(Circle())
                        }
                        
                        // 输入框
                        TextField("请输入您的问题...", text: $text)
                            .focused($isFocused)
                            .font(.system(size: 16))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.theme.secondaryBackground)
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.theme.border, lineWidth: 1)
                            )
                        
                        // 发送按钮
                        Button(action: {
                            onSend()
                            if text.isEmpty && (selectedImages?.isEmpty ?? true) {
                                isShowingInput = false
                            }
                        }) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    (text.isEmpty && (selectedImages?.isEmpty ?? true))
                                        ? Color.theme.tertiaryBackground 
                                        : Color.theme.accent
                                )
                                .clipShape(Circle())
                        }
                        .disabled(text.isEmpty && (selectedImages?.isEmpty ?? true))
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                .background(Color.theme.background)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.theme.border)
                        .opacity(0.5),
                    alignment: .top
                )
            }
        }
        .onChange(of: isFocused) { focused in
            if !focused && text.isEmpty && (selectedImages?.isEmpty ?? true) {
                isShowingInput = false
            }
        }
    }
}
