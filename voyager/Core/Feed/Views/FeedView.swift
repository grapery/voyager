//
//  FeedView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI
import Kingfisher

extension Date{
    var timeStamp: String{
        let formatter = DateFormatter()
        formatter.dateFormat = "s"
        return formatter.string(from: self)
    }
}

enum FeedType{
    case Groups
    case Story
    case StoryRole
}
    
// 获取用户的关注以及用户参与的故事，以及用户关注或者参与的小组的故事动态。不可以用户关注用户，只可以关注小组或者故事,以及故事的角色
struct FeedView: View {
    @StateObject var viewModel: FeedViewModel
    @State private var selectedTab: FeedType = .Groups
    @State private var showNewItemView = false
    @State private var isShowingFollowing = true
    @State private var chatMessages: [ChatMessage] = []
    @State private var chatInput = ""
    
    // 定义标签页数组
    let tabs: [(type: FeedType, title: String)] = [
        (.Groups, "小组"),
        (.Story, "故事"),
        (.StoryRole, "角色")
    ]
    
    let discoverTabs :[String] = ["热点故事","故事时间线","角色","世界观"]
  
    
    @Namespace private var namespace
    
    init(userId: Int64) {
        self._viewModel = StateObject(wrappedValue: FeedViewModel(userId: userId))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部导航栏
                CustomNavigationBar(
                    isShowingFollowing: $isShowingFollowing,
                    showNewItemView: $showNewItemView,
                    namespace: namespace
                )
                
                // 主要内容区域
                TabView(selection: $isShowingFollowing) {
                    followingFeedContent
                        .tag(true)
                    
                    discoverFeedContent
                        .tag(false)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: isShowingFollowing)
            }
            .navigationBarHidden(true)
        }
        .onAppear { fetchData() }
        .onChange(of: selectedTab) { _ in fetchData() }
        .onChange(of: isShowingFollowing) { _ in fetchData() }
    }
    
    // 自定义导航栏
    private struct CustomNavigationBar: View {
        @Binding var isShowingFollowing: Bool
        @Binding var showNewItemView: Bool
        var namespace: Namespace.ID
        
        var body: some View {
            HStack(spacing: 20) {
                // Logo或标题
                Image("app_logo") // 替换为实际的logo
                    .resizable()
                    .frame(width: 32, height: 32)
                
                // 标签切换器
                HStack(spacing: 24) {
                    TabButton(
                        title: "最新动态",
                        isSelected: isShowingFollowing,
                        action: { withAnimation { isShowingFollowing = true } }
                    )
                    
                    TabButton(
                        title: "发现",
                        isSelected: !isShowingFollowing,
                        action: { withAnimation { isShowingFollowing = false } }
                    )
                }
                
                Spacer()
                
                // 右侧按钮
                Button(action: { showNewItemView = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                Color.white
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            )
        }
    }
    
    // 修改后的followingFeedContent
    private var followingFeedContent: some View {
        VStack(spacing: 0) {
            // 自定义分类标签
            CustomSegmentedControl(selectedTab: $selectedTab, tabs: tabs)
                .padding(.vertical, 8)
            
            // 搜索栏
            EnhancedSearchBar(text: $searchText, isSearching: $isSearching)
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            // 内容区域
            TabView(selection: $selectedTab) {
                ForEach(tabs, id: \.type) { tab in
                    FeedContentView(
                        type: tab.type,
                        groups: filteredGroups,
                        stories: filteredStories,
                        roles: filteredRoles
                    )
                    .tag(tab.type)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }
    
    // 添加搜索状态
    @State private var searchText = ""
    @State private var isSearching = false
    
    // 添加计算属性来过滤内容
    private var filteredGroups: [BranchGroup] {
        if searchText.isEmpty {
            return viewModel.groups
        }
        return viewModel.groups.filter { group in
            group.info.name.localizedCaseInsensitiveContains(searchText) ||
            group.info.desc.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredStories: [Story] {
        if searchText.isEmpty {
            return viewModel.storys
        }
        return viewModel.storys.filter { story in
            story.storyInfo.name.localizedCaseInsensitiveContains(searchText) ||
            story.storyInfo.origin.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredRoles: [StoryRole] {
        if searchText.isEmpty {
            return viewModel.roles
        }
        return viewModel.roles.filter { role in
            role.role.characterName.localizedCaseInsensitiveContains(searchText) ||
            role.role.characterDescription.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // 添加搜索处理函数
    private func performSearch(query: String) async {
        guard !query.isEmpty else { return }
        
        isSearching = true
        defer { isSearching = false }
        
        do {
            switch selectedTab {
            case .Groups:
                print("Groups")
                //await viewModel.searchGroups(query: query)
            case .Story:
                //await viewModel.searchStories(query: query)
                print("Story")
            case .StoryRole:
                //await viewModel.searchRoles(query: query)
                print("StoryRole")
            }
        } catch {
            print("Search error: \(error)")
            // 这里可以添加错误处理逻辑
        }
    }
    
    // Discover/trending content
    private var discoverFeedContent: some View {
        VStack(spacing: 0) {
            // 分类标签栏
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(discoverTabs, id: \.self) { tab in
                        DiscoverTabButton(
                            title: tab,
                            icon: getTabIcon(tab),
                            isSelected: discoverSelectedTab == tab,
                            action: { discoverSelectedTab = tab }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(Color.white)
            
            // AI助手区域
            VStack(spacing: 16) {
                AIAssistantHeader()
                
                if !chatMessages.isEmpty {
                    ChatMessagesList(messages: chatMessages)
                }
                
                Spacer()
                
                ChatInputBar(
                    text: $chatInput,
                    onSend: sendMessage
                )
            }
            .padding(.top, 16)
        }
    }
    
    // Helper properties and methods
    @State private var discoverSelectedTab = "世界观"
    
    private func getTabIcon(_ tab: String) -> String {
        switch tab {
        case "热点故事":
            return "livephoto"
        case "故事时间线":
            return "signpost.right.and.left"
        case "角色":
            return "person.crop.rectangle.stack"
        case "世界观":
            return "building.columns"
        default:
            return "signpost.right.and.left"
        }
    }
    
    // Chat Message View
    struct ChatMessageView: View {
        let isAI: Bool
        let message: String
        let avatar: String
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                if isAI {
                    Image(avatar)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(message)
                        .padding()
                        .background(isAI ? Color(.systemGray6) : Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
                .frame(maxWidth: .infinity, alignment: isAI ? .leading : .trailing)
                
                if !isAI {
                    Image(avatar)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                }
            }
        }
    }
    
    private func fetchData() {
        Task {
            if isShowingFollowing == true{
                switch selectedTab {
                case .Groups:
                    await viewModel.fetchGroups()
                case .Story:
                    await viewModel.fetchStorys()
                case .StoryRole:
                    await viewModel.fetchStoryRoles()
                }
            }
            
        }
    }
    
    struct ChatMessage: Identifiable {
        let id = UUID()
        let content: String
        let isAI: Bool
        let timestamp: Date
        
        init(content: String, isAI: Bool) {
            self.content = content
            self.isAI = isAI
            self.timestamp = Date()
        }
    }
    
    struct ChatMessagesList: View {
        let messages: [ChatMessage]
        
        var body: some View {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        ChatMessageView(
                            isAI: message.isAI,
                            message: message.content,
                            avatar: message.isAI ? "ai_avatar" : "user_avatar" // Replace with actual avatar images
                        )
                    }
                }
                .padding()
            }
        }
    }
    
    private func sendMessage() {
        guard !chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(content: chatInput, isAI: false)
        chatMessages.append(userMessage)
        
        // Clear input
        chatInput = ""
        
        // Simulate AI response (replace with actual AI integration)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let aiResponse = ChatMessage(content: "这是AI助手的回复示例。", isAI: true)
            chatMessages.append(aiResponse)
        }
    }
}

struct FeedCustomTabView: View {
    @Binding var selectedTab: FeedType
    let tabs: [(type: FeedType, title: String)]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(tabs, id: \.type) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = tab.type
                        }
                    }) {
                        VStack(spacing: 0) {
                            Text(tab.title)
                                .font(.system(size: 12))
                                .foregroundColor(selectedTab == tab.type ? .orange : .gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            Divider()
        }
    }
}

// Helper views for each feed type
struct GroupsList: View {
    let groups: [BranchGroup]
    
    var body: some View {
        ForEach(groups, id: \.id) { group in
            FeedCellView(item: group)
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct StoriesList: View {
    let stories: [Story]
    
    var body: some View {
        ForEach(stories, id: \.id) { story in
            NavigationLink(destination: StoryView(story: story, userId: 0)) {
                FeedCellView(item: story)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct RolesList: View {
    let roles: [StoryRole]
    
    var body: some View {
        ForEach(roles, id: \.id) { role in
            FeedCellView(item: role)
        }
    }
}

struct BoardsList: View {
    let boards: [StoryBoard]
    
    var body: some View {
        ForEach(boards, id: \.id) { board in
            FeedCellView(item: board)
        }
    }
}

struct FeedCellView: View {
    let item: Any
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                avatarView
                titleView
                Spacer()
                Image(systemName: "ellipsis")
            }
            
            descriptionView
            
            // Add more content here as needed
            
            actionButtons
        }
        .padding()
        .background(Color.white)
    }
    
    @ViewBuilder
    private var avatarView: some View {
        if let group = item as? BranchGroup {
            KFImage(URL(string: group.info.avatar))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
        } else if let story = item as? Story {
            KFImage(URL(string: story.storyInfo.avatar))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    private var titleView: some View {
        if let group = item as? BranchGroup {
            Text(group.info.name)
                .font(.headline)
        } else if let story = item as? Story {
            Text(story.storyInfo.name)
                .font(.headline)
        } else if let role = item as? StoryRole {
            Text(role.role.characterName)
                .font(.headline)
        } else if let board = item as? StoryBoard {
            Text(board.boardInfo.title)
                .font(.headline)
        }
    }
    
    @ViewBuilder
    private var descriptionView: some View {
        if let group = item as? BranchGroup {
            Text(group.info.desc)
                .font(.subheadline)
                .lineLimit(2)
        } else if let story = item as? Story {
            Text(story.storyInfo.origin)
                .font(.subheadline)
                .lineLimit(2)
        } else if let role = item as? StoryRole {
            Text(role.role.characterDescription)
                .font(.subheadline)
                .lineLimit(2)
        } else if let board = item as? StoryBoard {
            Text(board.boardInfo.content)
                .font(.subheadline)
                .lineLimit(2)
        }
    }
    
    private var actionButtons: some View {
        HStack {
            Spacer()
            Button(action: {}) {
                Image(systemName: "bell.circle")
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "bubble.circle")
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "heart.circle")
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "square.and.arrow.up.circle")
            }
            Spacer()
        }
        .foregroundColor(.secondary)
    }
}

// 辅助扩展，用于显示相对时间

// 增强版搜索栏
private struct EnhancedSearchBar: View {
    @Binding var text: String
    @Binding var isSearching: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("搜索内容...", text: $text)
                    .font(.system(size: 15))
                
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .transition(.scale)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// 自定义分段控制器
private struct CustomSegmentedControl: View {
    @Binding var selectedTab: FeedType
    let tabs: [(type: FeedType, title: String)]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(tabs, id: \.type) { tab in
                    Button(action: {
                        withAnimation { selectedTab = tab.type }
                    }) {
                        VStack(spacing: 8) {
                            Text(tab.title)
                                .font(.system(size: 15, weight: selectedTab == tab.type ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab.type ? .primary : .gray)
                            
                            // 选中指示器
                            Rectangle()
                                .fill(selectedTab == tab.type ? Color.accentColor : Color.clear)
                                .frame(height: 2)
                                .animation(.spring(), value: selectedTab)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// Feed内容视图
struct FeedContentView: View {
    let type: FeedType
    let groups: [BranchGroup]
    let stories: [Story]
    let roles: [StoryRole]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                switch type {
                case .Groups:
                    ForEach(groups, id: \.id) { group in
                        GroupFeedCell(group: group)
                    }
                case .Story:
                    ForEach(stories, id: \.id) { story in
                        StoryFeedCell(story: story)
                    }
                case .StoryRole:
                    ForEach(roles, id: \.id) { role in
                        RoleFeedCell(role: role)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .refreshable {
            await refreshData()
        }
        .onAppear {
            await refreshData()
        }
    }
}

// 优化后的小组Feed单元格
struct GroupFeedCell: View {
    let group: BranchGroup
    @State private var isFollowing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部信息
            HStack(spacing: 12) {
                KFImage(URL(string: group.info.avatar))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.info.name)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("成员: \(10)")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: { isFollowing.toggle() }) {
                    Text(isFollowing ? "已关注" : "关注")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isFollowing ? .gray : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(isFollowing ? Color.gray.opacity(0.1) : Color.blue)
                        .clipShape(Capsule())
                }
            }
            
            // 描述内容
            if !group.info.desc.isEmpty {
                Text(group.info.desc)
                    .font(.system(size: 15))
                    .lineLimit(3)
                    .padding(.vertical, 8)
            }
            
            // 互动栏
            HStack(spacing: 24) {
                InteractionButton(
                    icon: "bell",
                    count: 20,
                    isActive: false,
                    action: { 
                        // 在这里处理点击事件
                        print("Bell button tapped")
                    }
                )
                
                InteractionButton(
                    icon: "bubble.left",
                    count: 20,
                    isActive: false,
                    action: { 
                        // 在这里处理点击事件
                        print("Bubble left button tapped")
                    }
                )
                
                InteractionButton(
                    icon: "heart",
                    count: 20,
                    isActive: false,
                    action: { 
                        // 在这里处理点击事件
                        print("Heart button tapped")
                    }
                )
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }
}

// 优化后的故事Feed单元
struct StoryFeedCell: View {
    let story: Story
    @State private var isFollowing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部信息
            HStack(spacing: 12) {
                KFImage(URL(string: story.storyInfo.avatar))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(story.storyInfo.name)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(Date(timeIntervalSince1970: TimeInterval(story.storyInfo.mtime)).timeAgoDisplay())
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: { isFollowing.toggle() }) {
                    Text(isFollowing ? "已关注" : "关注")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isFollowing ? .gray : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(isFollowing ? Color.gray.opacity(0.1) : Color.blue)
                        .clipShape(Capsule())
                }
            }
            
            // 故事内容预览
            if !story.storyInfo.origin.isEmpty {
                Text(story.storyInfo.origin)
                    .font(.system(size: 15))
                    .lineLimit(3)
                    .padding(.vertical, 8)
            }
            
            // 故事封面图（如果有的话）
            if !story.storyInfo.avatar.isEmpty {
                KFImage(URL(string: story.storyInfo.avatar))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
            }
            
            // 互动栏
            HStack(spacing: 24) {
                InteractionButton(
                    icon: "bookmark",
                    count: 10,
                    isActive: false,
                    action: { 
                        // 在这里处理点击事件
                        print("Bookmark button tapped")
                    }
                )
                
                InteractionButton(
                    icon: "bubble.left",
                    count: 10,
                    isActive: false,
                    action: { 
                        // 在这里处理点击事件
                        print("Bubble left button tapped")
                    }
                )
                
                InteractionButton(
                    icon: "heart",
                    count: 10,
                    isActive: false,
                    action: { 
                        // 在这里处理点击事件
                        print("Heart button tapped")
                    }
                )
                
                Spacer()
                
                Button(action: {
                    print("Square and arrow up button tapped")
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }
}

// 角色Feed单元格
struct RoleFeedCell: View {
    let role: StoryRole
    @State private var isFollowing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部信息
            HStack(spacing: 12) {
                KFImage(URL(string: role.role.characterAvatar))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.role.characterName)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("来自故事: \(role.role.characterName)")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: { 
                    isFollowing.toggle() 
                    print("isFollowing: \(isFollowing)")
                }) {
                    Text(isFollowing ? "已关注" : "关注")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isFollowing ? .gray : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(isFollowing ? Color.gray.opacity(0.1) : Color.blue)
                        .clipShape(Capsule())
                }
            }
            
            // 角色描述
            if !role.role.characterDescription.isEmpty {
                Text(role.role.characterDescription)
                    .font(.system(size: 15))
                    .lineLimit(3)
                    .padding(.vertical, 8)
            }
            
            
            // 互动栏
            HStack(spacing: 24) {
                InteractionButton(
                    icon: "bell",
                    count: 30,
                    isActive: false,
                    action: { 
                        // 在这里处理点击事件
                        print("Bell button tapped")
                    }
                )
                
                InteractionButton(
                    icon: "bubble.left",
                    count: 30,
                    isActive: false,
                    action: { 
                        // 在这里处理点击事件
                        print("Bubble left button tapped")
                    }
                )
                
                InteractionButton(
                    icon: "heart",
                    count: 30,
                    isActive: false,
                    action: { 
                        // 在这里处理点击事件
                        print("Heart button tapped")
                    }
                )
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }
}

// 互动按钮组件
struct InteractionButton: View {
    let icon: String
    let count: Int
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text("\(count)")
                    .font(.system(size: 14))
            }
            .foregroundColor(isActive ? .blue : .gray)
        }
    }
}

// 发现页面组件
struct DiscoverTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .foregroundColor(isSelected ? .blue : .gray)
            .cornerRadius(20)
        }
    }
}

// AI手头部
struct AIAssistantHeader: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 48, height: 48)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text("AI故事助手")
                    .font(.system(size: 16, weight: .semibold))
                Text("为您推荐个性化的故事和角色")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }
}

// 聊天输入栏
struct ChatInputBar: View {
    @Binding var text: String
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("输入您的问题...", text: $text)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(24)
            
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
            }
            .disabled(text.isEmpty)
        }
        .padding()
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: -2)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .gray)
                
                // Selection indicator
                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 2)
                    .matchedGeometryEffect(id: "tab_\(title)", in: namespace)
            }
        }
    }
    
    @Namespace private var namespace
}

extension Date {
    func timeAgoDisplay() -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.second, .minute, .hour, .day, .month, .year], from: self, to: now)
        
        if let years = components.year, years > 0 {
            return years == 1 ? "1年前" : "\(years)年前"
        }
        if let months = components.month, months > 0 {
            return months == 1 ? "1个月前" : "\(months)个月前"
        }
        if let days = components.day, days > 0 {
            return days == 1 ? "1天前" : "\(days)天前"
        }
        if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1小时前" : "\(hours)小时前"
        }
        if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1分钟前" : "\(minutes)分钟前"
        }
        if let seconds = components.second, seconds > 0 {
            return seconds < 5 ? "刚刚" : "\(seconds)秒前"
        }
        return "刚刚"
    }
}
