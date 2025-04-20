//
//  GroupDetail.swift
//  voyager
//
//  Created by grapestree on 2024/9/30.
//

import SwiftUI
import Kingfisher
import Combine

// MARK: - Group Header View
struct GroupHeaderView: View {
    let group: BranchGroup?
    var currentUser: User
    @Binding var viewModel: GroupDetailViewModel
    @Binding var showNewStoryView: Bool
    let onBack: () -> Void
    let onSettings: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background Image with Gradient
            KFImage(URL(string: group?.info.avatar ?? defaultAvator))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .ignoresSafeArea(edges: .top)
                .clipped()
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.1),
                            Color.black.opacity(0.7)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.theme.secondary.opacity(0.3))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: onSettings) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.theme.secondary.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                GroupInfoView(group: group, currentUser: currentUser, viewModel: $viewModel, showNewStoryView: $showNewStoryView)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                
                Spacer()
            }
        }
    }
}

// MARK: - Group Info View
struct GroupInfoView: View {
    let group: BranchGroup?
    var currentUser: User
    @Binding var viewModel: GroupDetailViewModel
    @Binding var showNewStoryView: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    KFImage(URL(string: group?.info.avatar ?? defaultAvator))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 72, height: 72)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .padding(.leading, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group?.info.name ?? "")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        GroupStatsView(group: group)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            GroupActionButtonsView(group: group, viewModel: viewModel, user: currentUser, showNewStoryView: $showNewStoryView)
                .padding(.trailing, 12)
        }
    }
}

// MARK: - Group Stats View
struct GroupStatsView: View {
    let group: BranchGroup?
    
    var body: some View {
        HStack(spacing: 16) {
            StatItemView(
                icon: "book.fill",
                value: Int64(group?.info.profile.groupStoryNum ?? 0),
                title: "故事"
            )
            
            StatItemView(
                icon: "person.2.fill",
                value: Int64(group?.info.profile.groupMemberNum ?? 0),
                title: "成员"
            )
            
            StatItemView(
                icon: "bell.fill",
                value: Int64(group?.info.profile.groupFollowerNum ?? 0),
                title: "关注"
            )
        }
    }
}

struct StatItemView: View {
    let icon: String
    let value: Int64
    let title: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.9))
                .font(.system(size: 14))
            Text("\(value)")
                .foregroundColor(.white.opacity(0.9))
                .font(.system(size: 14))
            Text(title)
                .foregroundColor(.white.opacity(0.9))
                .font(.system(size: 12))
        }
    }
}

// MARK: - Group Action Buttons View
struct GroupActionButtonsView: View {
    let group: BranchGroup?
    @StateObject var viewModel: GroupDetailViewModel
    var user: User
    @Binding var showNewStoryView: Bool
    @State private var showError = false
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    
    init(group: BranchGroup?, viewModel: GroupDetailViewModel, user: User, showNewStoryView: Binding<Bool>) {
        self.group = group
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.user = user
        self._showNewStoryView = showNewStoryView
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Button(action: {
                showNewStoryView = true
            }) {
                HStack(spacing: 2) {
                    Image(systemName: "plus")
                        .font(.system(size: 15))
                    Text("创建故事")
                        .font(.system(size: 15))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.theme.accent)
                .cornerRadius(12)
            }
            
            Button(action: {
                Task {
                    if group?.info.currentUserStatus.isJoined == false {
                        await viewModel.JoinGroup(groupdId: group?.info.groupID ?? 0)
                        group?.info.currentUserStatus.isJoined = true
                        group?.info.profile.groupMemberNum = (group?.info.profile.groupMemberNum)! + 1
                    } else {
                        await viewModel.LeaveGroup(groupdId: group?.info.groupID ?? 0)
                        group?.info.currentUserStatus.isJoined = false
                        group?.info.profile.groupMemberNum = (group?.info.profile.groupMemberNum)! - 1
                    }
                }
            }) {
                HStack(spacing: 2) {
                    Image(systemName: group?.info.currentUserStatus.isJoined ?? false ? "person.badge.minus" : "person.badge.plus")
                        .font(.system(size: 15))
                    Text(group?.info.currentUserStatus.isJoined ?? false ? "已加入" : "加入小组")
                        .font(.system(size: 15))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(group?.info.currentUserStatus.isJoined ?? false ? Color.theme.tertiaryBackground : Color.theme.accent)
                .cornerRadius(12)
            }
            
            Button(action: {
                Task {
                    if group?.info.currentUserStatus.isFollowed == false {
                        if let err = await viewModel.followGroup(userId: user.userID, groupId: group?.info.groupID ?? 0) {
                            await MainActor.run {
                                errorTitle = "关注 \(group?.info.name ?? "小组") 失败"
                                errorMessage = err.localizedDescription
                                showError = true
                            }
                        } else {
                            group?.info.currentUserStatus.isFollowed = true
                            group?.info.profile.groupFollowerNum = (group?.info.profile.groupFollowerNum)! + 1
                        }
                    } else {
                        if let err = await viewModel.unFollowGroup(userId: user.userID, groupId: group?.info.groupID ?? 0) {
                            await MainActor.run {
                                errorTitle = "取消关注 \(group?.info.name ?? "小组") 失败"
                                errorMessage = err.localizedDescription
                                showError = true
                            }
                        } else {
                            group?.info.currentUserStatus.isFollowed = false
                            group?.info.profile.groupFollowerNum = (group?.info.profile.groupFollowerNum)! - 1
                        }
                    }
                }
            }) {
                HStack(spacing: 2) {
                    Image(systemName: group?.info.currentUserStatus.isFollowed ?? false ? "bell.fill" : "bell")
                        .font(.system(size: 15))
                    Text(group?.info.currentUserStatus.isFollowed ?? false ? "已关注" : "关注小组")
                        .font(.system(size: 15))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(group?.info.currentUserStatus.isFollowed ?? false ? Color.theme.tertiaryBackground : Color.theme.accent)
                .cornerRadius(12)
            }
        }
        .alert(errorTitle, isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Story List Header View
struct StoryListHeaderView: View {
    let stories: [Story]
    @Binding var selectedStoryId: Int64?
    let isHeaderSticky: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    Button(action: {
                        selectedStoryId = nil
                    }) {
                        VStack {
                            Circle()
                                .fill(selectedStoryId == nil ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 49, height: 49)
                                .overlay(
                                    Image(systemName: "timelapse")
                                        .foregroundColor(.white)
                                )
                            Text("全部")
                                .font(.system(size: 12))
                        }
                    }
                    
                    ForEach(stories) { story in
                        Button(action: {
                            selectedStoryId = story.storyInfo.id
                        }) {
                            VStack {
                                KFImage(URL(string: story.storyInfo.avatar))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 49, height: 49)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(selectedStoryId == story.storyInfo.id ? Color.orange : Color.gray, lineWidth: 2)
                                    )
                                Text(story.storyInfo.title.prefix(4))
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(UIColor.systemBackground))
            
            Divider()
        }
        .opacity(isHeaderSticky ? 0 : 1)
    }
}

// MARK: - Story List Content View
struct StoryListContentView: View {
    let stories: [Story]
    let selectedStoryId: Int64?
    let userId: Int64
    let viewModel: GroupDetailViewModel
    let isHeaderSticky: Bool
    
    var body: some View {
        LazyVStack(spacing: 0) {
            if let selectedId = selectedStoryId {
                ForEach(stories.filter { $0.storyInfo.id == selectedId }) { story in
                    StoryUpdateCell(story: story, userId: userId, viewModel: viewModel)
                }
            } else {
                ForEach(stories.sorted { $0.storyInfo.ctime > $1.storyInfo.ctime }) { story in
                    StoryUpdateCell(story: story, userId: userId, viewModel: viewModel)
                }
            }
        }
        .padding(.top, isHeaderSticky ? 100 : 0)
    }
}

// MARK: - Main Group Detail View
struct GroupDetailView: View {
    var user: User
    var currentUser: User
    @State var group: BranchGroup?
    @State var naviItemPressed: Bool = false
    @State var showNewStoryView: Bool = false
    @State var showUpdateGroupView: Bool = false
    @State var viewModel: GroupDetailViewModel
    @State private var selectedTab = 0
    @State private var needsRefresh = false
    @State private var isRefreshing = false
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStoryId: Int64? = nil
    @State private var scrollOffset: CGFloat = 0
    @State private var isHeaderSticky: Bool = false

    init(user: User, group: BranchGroup) {
        self.user = user
        self.currentUser = user
        self.group = group
        self.viewModel = GroupDetailViewModel(user: user, groupId: (group.info.groupID))
    }
    
    var body: some View {
        ZStack {
            if isLoading {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("加载中...")
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            } else {
                ScrollView {
                    GeometryReader { geometry in
                        Color.clear.preference(key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY)
                    }
                    .frame(height: 0)
                    
                    VStack(spacing: 0) {
                        GroupHeaderView(
                            group: group,
                            currentUser: user,
                            viewModel: $viewModel,
                            showNewStoryView: $showNewStoryView,
                            onBack: { dismiss() },
                            onSettings: { showUpdateGroupView = true }
                        )
                        
                        StoryListHeaderView(
                            stories: viewModel.storys,
                            selectedStoryId: $selectedStoryId,
                            isHeaderSticky: isHeaderSticky
                        )
                        
                        StoryListContentView(
                            stories: viewModel.storys,
                            selectedStoryId: selectedStoryId,
                            userId: user.userID,
                            viewModel: viewModel,
                            isHeaderSticky: isHeaderSticky
                        )
                    }
                }
                .navigationBarHidden(true)
                .sheet(isPresented: $showNewStoryView) {
                    NewStoryView(groupId: group!.info.groupID, userId: user.userID)
                        .onDisappear {
                            Task {
                                await refreshGroupData()
                            }
                        }
                }
                .sheet(isPresented: $showUpdateGroupView) {
                    UpdateGroupView(group: group!, userId: user.userID)
                }
            }
        }
        .onAppear {
            Task {
                isLoading = true
                await refreshGroupData()
                isLoading = false
            }
        }
    }
    
    private func refreshGroupData() async {
        isRefreshing = true
        await viewModel.fetchGroupStorys(groupdId: group!.info.groupID)
        isRefreshing = false
    }
}

private struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.gray)
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.gray)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

struct CustomTabView: View {
    @Binding var selectedTab: Int
    let tabs = ["关注", "全部"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(0..<tabs.count) { index in
                    Button(action: {
                        withAnimation { selectedTab = index }
                    }) {
                        VStack(spacing: 8) {
                            Text(tabs[index])
                                .font(.system(size: 15, weight: selectedTab == index ? .semibold : .regular))
                                .foregroundColor(selectedTab == index ? .primary : .gray)
                            
                            Rectangle()
                                .fill(selectedTab == index ? Color.accentColor : Color.clear)
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

struct StoryCellView: View {
    let story: Story
    var userId: Int64
    var currentUserId: Int64
    var viewModel: GroupDetailViewModel
    
    init(story: Story, userId: Int64, viewModel: GroupDetailViewModel) {
        self.story = story
        self.userId = userId
        self.currentUserId = userId
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                KFImage(URL(string: story.storyInfo.avatar))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                
                HStack {
                    Text(story.storyInfo.name)
                        .font(.headline)
                    Spacer()
                    Text(formatDate(timestamp: story.storyInfo.ctime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "ellipsis")
            }
            
            Text(story.storyInfo.origin)
                .font(.body)
            
            KFImage(URL(string: story.storyInfo.avatar))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)
                .cornerRadius(8)
            
            HStack {
                Spacer()
                Button(action: {
                    Task {
                        await viewModel.watchStory(storyId: self.story.storyInfo.id, userId: self.currentUserId)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bell")
                            .font(.system(size: 14))
                        Text("订阅")
                            .font(.system(size: 14))
                    }
                }
                Spacer()
                Button(action: {
                    Task {
                        await viewModel.likeStory(userId: self.currentUserId, storyId: story.storyInfo.id)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .font(.system(size: 14))
                        Text("点赞")
                            .font(.system(size: 14))
                    }
                }
                Spacer()
                Button(action: {
                    Task {
                        await viewModel.likeStory(userId: self.currentUserId, storyId: story.storyInfo.id)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                        Text("分享")
                            .font(.system(size: 14))
                    }
                }
                Spacer()
            }
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
    }
}

func formatDate(timestamp: Int64) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

// 添加 RefreshControl 组件
struct RefreshControl: View {
    @Binding var isRefreshing: Bool
    let action: () async -> Void
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.frame(in: .global).minY > 50 {
                Spacer()
                    .onAppear {
                        guard !isRefreshing else { return }
                        isRefreshing = true
                        Task {
                            await action()
                        }
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

// Preference Key for tracking scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Story Update Cell View
struct StoryUpdateCell: View {
    let story: Story
    let userId: Int64
    let viewModel: GroupDetailViewModel
    
    var body: some View {
        NavigationLink(destination: StoryView(story: story, userId: userId)) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    KFImage(URL(string: story.storyInfo.avatar))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 49, height: 49)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(story.storyInfo.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                        Text(formatTimeAgo(timestamp: story.storyInfo.ctime))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                
                // Content
                Text(story.storyInfo.origin)
                    .font(.system(size: 14))
                    .lineLimit(3)
                    .foregroundColor(.primary)
                
                if let imageUrl = URL(string: story.storyInfo.avatar) {
                    KFImage(imageUrl)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipped()
                        .cornerRadius(8)
                }
            }
            .padding(16)
            .background(Color(UIColor.systemBackground))
            .compositingGroup()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Helper function to format time
func formatTimeAgo(timestamp: Int64) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
    let now = Date()
    let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)
    
    if let day = components.day, day > 0 {
        return "\(day)天前"
    } else if let hour = components.hour, hour > 0 {
        return "\(hour)小时前"
    } else if let minute = components.minute, minute > 0 {
        return "\(minute)分钟前"
    } else {
        return "刚刚"
    }
}
