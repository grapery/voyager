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
    
    // 定义标签页数组
    let tabs: [(type: FeedType, title: String)] = [
        (.Groups, "小组"),
        (.Story, "故事"),
        (.StoryRole, "角色")
    ]
    
    @Namespace private var namespace
    
    init(userId: Int64) {
        self._viewModel = StateObject(wrappedValue: FeedViewModel(userId: userId))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top tab selector
                topTabSelector
                
                // Main content
                TabView(selection: $isShowingFollowing) {
                    followingFeedContent
                        .tag(true)
                    
                    discoverFeedContent
                        .tag(false)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationBarItems(trailing:
                Button(action: {
                    showNewItemView = true
                }) {
                    Image(systemName: "plus.circle")
                }
            )
        }
        .onAppear {
            fetchData()
        }
        .onChange(of: selectedTab) { _ in
            fetchData()
        }
        .onChange(of: isShowingFollowing) { _ in
            fetchData()
        }
    }
    
    // 顶部标签选择器
    private var topTabSelector: some View {
        HStack(spacing: 16) {
            Button(action: { 
                withAnimation {
                    isShowingFollowing = true
                }
            }) {
                VStack(spacing: 12) {
                    Text("最新动态")
                        .foregroundColor(isShowingFollowing ? .black : .gray)
                        .font(.system(size: 12, weight: .medium))
                    
                    // 下划线指示器
                    Rectangle()
                        .fill(isShowingFollowing ? .black : .clear)
                        .frame(height: 2)
                        .matchedGeometryEffect(id: "underline", in: namespace, isSource: isShowingFollowing)
                }
            }
            
            Button(action: {
                withAnimation {
                    isShowingFollowing = false
                }
            }) {
                VStack(spacing: 8) {
                    Text("发现")
                        .foregroundColor(!isShowingFollowing ? .black : .gray)
                        .font(.system(size: 12, weight: .medium))
                    
                    // 下划线指示器
                    Rectangle()
                        .fill(!isShowingFollowing ? .black : .clear)
                        .frame(height: 2)
                        .matchedGeometryEffect(id: "underline", in: namespace, isSource: !isShowingFollowing)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.white)
    }
    
    // Following feed content
    private var followingFeedContent: some View {
        VStack(spacing: 0) {
            // Custom tab header
            FeedCustomTabView(selectedTab: $selectedTab, tabs: tabs)
            
            // Content with TabView
            TabView(selection: $selectedTab) {
                // Groups Tab
                ScrollView {
                    LazyVStack(spacing: 0) {
                        GroupsList(groups: viewModel.groups)
                    }
                }
                .tag(FeedType.Groups)
                
                // Story Tab
                ScrollView {
                    LazyVStack(spacing: 0) {
                        StoriesList(stories: viewModel.storys)
                    }
                }
                .tag(FeedType.Story)
                
                // StoryRole Tab
                ScrollView {
                    LazyVStack(spacing: 0) {
                        RolesList(roles: viewModel.roles)
                    }
                }
                .tag(FeedType.StoryRole)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }
    
    // Discover/trending content
    private var discoverFeedContent: some View {
        VStack(spacing: 0) {
            
            // Tab Selector
            HStack(spacing: 0) {
                ForEach(["热点问题", "时间线", "咨询"], id: \.self) { tab in
                    Button(action: {
                        discoverSelectedTab = tab
                    }) {
                        HStack {
                            Image(systemName: getTabIcon(tab))
                            Text(tab)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(discoverSelectedTab == tab ? Color(.systemGray5) : Color(.systemGray6))
                        .cornerRadius(20)
                    }
                    .foregroundColor(.primary)
                }
                Spacer()
            }
            .padding(.horizontal)
            .background(Color(.systemGray6))
            
            // Chat Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // AI Assistant Intro Message
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "infinity.circle") // 替换为实际的 AI 头像
                            .resizable()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("metric order")
                                .font(.headline)
                            
                            Text("你好，我是矩阵，为您推荐故事或者故事角色")
                                .font(.body)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Chat Messages would go here
                    // ... 
                }
                .padding()
            }
            
            // Bottom Input Bar
            HStack(spacing: 12) {
                TextField("Ask for knowledge", text: $chatInput)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                
                Button(action: { /* Send message */ }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(Color.white)
            .shadow(color: .black.opacity(0.05), radius: 5, y: -2)
        }
    }
    
    // Helper properties and methods
    @State private var discoverSelectedTab = "咨询"
    @State private var chatInput = ""
    
    private func getTabIcon(_ tab: String) -> String {
        switch tab {
        case "热点问题":
            return "star"
        case "时间线":
            return "clock"
        case "咨询":
            return "bubble.left"
        default:
            return ""
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
}

struct FeedCustomTabView: View {
    @Binding var selectedTab: FeedType
    let tabs: [(type: FeedType, title: String)]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(tabs, id: \.type) { tab in
                    Button(action: {
                        withAnimation {
                            selectedTab = tab.type
                        }
                    }) {
                        VStack(spacing: 0) {
                            Text(tab.title)
                                .foregroundColor(selectedTab == tab.type ? .black : .gray)
                            
                            // 添加下划线指示器
                            Rectangle()
                                .fill(selectedTab == tab.type ? Color.black : Color.clear)
                                .frame(height: 2)
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
extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
