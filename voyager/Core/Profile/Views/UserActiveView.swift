//
//  UserActiveView.swift
//  voyager
//
//  Created by grapestree on 2025/4/3.
//

import SwiftUI
import PhotosUI
import Kingfisher



// MARK: - User Activity View
struct UserActivesView: View {
    @StateObject public var viewModel: UserActivityViewModel
    var userId: Int64
    var lasttime: Int64
    @State private var isRefreshing = false
    @State private var isLoadingMore = false
    
    init(userId: Int64, lasttime: Int64) {
        self.userId = userId
        self.lasttime = lasttime
        self._viewModel = StateObject(wrappedValue: UserActivityViewModel(userId: userId, lasttime: lasttime))
    }
    
    var body: some View {
        ScrollView {
            ActiveRefreshControl(isRefreshing: $isRefreshing) {
                await refresh()
            }
            
            LazyVStack(spacing: 16) {
                if let actives = viewModel.actives {
                    ForEach(actives) { activity in
                        ActivityCell(activity: activity)
                            .onAppear {
                                if activity.id == actives.last?.id && !isLoadingMore {
                                    Task {
                                        await loadMore()
                                    }
                                }
                            }
                    }
                }
                
                if isLoadingMore {
                    ProgressView()
                        .frame(height: 50)
                }
            }
            .padding()
        }
        .task {
            if viewModel.actives == nil || viewModel.actives?.isEmpty == true {
                await viewModel.fetchUserActivities(userId: userId, lasttime: lasttime)
            }
        }
    }
    
    // 下拉刷新
    private func refresh() async {
        isRefreshing = true
        // 使用当前时间戳作为最新时间点
        let currentTime = Int64(Date().timeIntervalSince1970)
        await viewModel.fetchUserActivities(userId: userId, lasttime: currentTime)
        isRefreshing = false
    }
    
    // 上拉加载更多
    private func loadMore() async {
        guard let actives = viewModel.actives, !actives.isEmpty else { return }
        
        isLoadingMore = true
        // 使用列表中最后一个活动的时间戳
        if let oldestTime = actives.last?.activity.ctime {
            _ = await viewModel.loadMoreActivities(userId: userId, lasttime: oldestTime)
        }
        isLoadingMore = false
    }
}

// MARK: - Activity Cell
private struct ActivityCell: View {
    let activity: UserActivity
    
    var body: some View {
        VStack {
            activityContent
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var activityContent: some View {
        switch activity.activitytype {
        case .followStory:
            followGroupContent
        case .newStory:
            createStoryContent
        case .newStoryBoard:
            createStoryboardContent
        case .likeStory:
            shareStoryContent
        case .likeStoryBoard:
            shareStoryboardContent
        case .newRole:
            createCharacterContent
        case .noneActive, .allActive, .joinGroup, .followRole, .likeRole, .followGroup, .likeGroup, .forkStory, .UNRECOGNIZED:
            HStack(spacing: 12) {
                // 活动图标
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.theme.tertiaryText)
                    .frame(width: 40, height: 40)
                    .background(Color.theme.tertiaryText.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("无动态")
                        .font(.system(size: 14))
                        .foregroundColor(.theme.tertiaryText)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.theme.secondaryBackground)
            .cornerRadius(12)
        }
    }
    
    private var followGroupContent: some View {
        FollowGroupActivityView(activity: activity)
    }
    
    private var createStoryContent: some View {
        CreateStoryActivityView(activity: activity)
    }
    
    private var createStoryboardContent: some View {
        CreateStoryboardActivityView(activity: activity)
    }
    
    private var shareStoryContent: some View {
        ShareStoryActivityView(activity: activity)
    }
    
    private var shareStoryboardContent: some View {
        ShareStoryboardActivityView(activity: activity)
    }
    
    private var createCharacterContent: some View {
        CreateCharacterActivityView(activity: activity)
    }
}

// MARK: - Refresh Control
private struct ActiveRefreshControl: View {
    @Binding var isRefreshing: Bool
    let action: () async -> Void
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.frame(in: .global).minY > 50 {
                Spacer()
                    .onAppear {
                        guard !isRefreshing else { return }
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
        .frame(height: 50)
    }
}


// MARK: - Follow Group Activity View
struct FollowGroupActivityView: View {
    let activity: UserActivity
    
    var body: some View {
        HStack(spacing: 12) {
            // 活动图标
            Image(systemName: "person.2.fill")
                .font(.system(size: 24))
                .foregroundColor(.theme.accent)
                .frame(width: 40, height: 40)
                .background(Color.theme.accent.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                // 活动描述
                Text("关注了小组")
                    .font(.system(size: 14))
                    .foregroundColor(.theme.primaryText)
                
                // 小组信息
                HStack {
                    KFImage(URL(string: activity.activity.groupInfo.avatar))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                    
                    Text(activity.activity.groupInfo.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.theme.accent)
                }
                
                // 时间
                Text(formatTimeAgo(timestamp: activity.activity.ctime))
                    .font(.system(size: 12))
                    .foregroundColor(.theme.tertiaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(12)
    }
}

// MARK: - Create Story Activity View
struct CreateStoryActivityView: View {
    let activity: UserActivity
    
    var body: some View {
        HStack(spacing: 12) {
            // 活动图标
            Image(systemName: "book.fill")
                .font(.system(size: 24))
                .foregroundColor(.theme.primary)
                .frame(width: 40, height: 40)
                .background(Color.theme.primary.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                // 活动描述
                Text("创建了故事")
                    .font(.system(size: 14))
                    .foregroundColor(.theme.primaryText)
                
                // 故事信息
                HStack {
                    KFImage(URL(string: activity.activity.storyInfo.avatar))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                    
                    Text(activity.activity.storyInfo.name ?? "未知故事")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.theme.primary)
                }
                
                // 时间
                Text(formatTimeAgo(timestamp: activity.activity.ctime))
                    .font(.system(size: 12))
                    .foregroundColor(.theme.tertiaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(12)
    }
}

// MARK: - Create Storyboard Activity View
struct CreateStoryboardActivityView: View {
    let activity: UserActivity
    
    var body: some View {
        HStack(spacing: 12) {
            // 活动图标
            Image(systemName: "rectangle.stack.fill")
                .font(.system(size: 24))
                .foregroundColor(.theme.warning)
                .frame(width: 40, height: 40)
                .background(Color.theme.warning.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                // 活动描述
                Text("创建了故事板")
                    .font(.system(size: 14))
                    .foregroundColor(.theme.primaryText)
                
                // 故事板信息
                HStack {
                    KFImage(URL(string:activity.activity.storyInfo.name))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                    
                    Text(activity.activity.boardInfo.title ?? "未知章节")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.theme.warning)
                }
                
                // 时间
                Text(formatTimeAgo(timestamp: activity.activity.ctime))
                    .font(.system(size: 12))
                    .foregroundColor(.theme.tertiaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(12)
    }
}

// MARK: - Share Story Activity View
struct ShareStoryActivityView: View {
    let activity: UserActivity
    
    var body: some View {
        HStack(spacing: 12) {
            // 活动图标
            Image(systemName: "square.and.arrow.up.fill")
                .font(.system(size: 24))
                .foregroundColor(.theme.success)
                .frame(width: 40, height: 40)
                .background(Color.theme.success.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                // 活动描述
                Text("分享了故事")
                    .font(.system(size: 14))
                    .foregroundColor(.theme.primaryText)
                
                // 故事信息
                HStack {
                    KFImage(URL(string: activity.activity.storyInfo.avatar ?? defaultAvator))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                    
                    Text(activity.activity.storyInfo.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.theme.success)
                }
                
                // 时间
                Text(formatTimeAgo(timestamp: activity.activity.ctime))
                    .font(.system(size: 12))
                    .foregroundColor(.theme.tertiaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(12)
    }
}

// MARK: - Share Storyboard Activity View
struct ShareStoryboardActivityView: View {
    let activity: UserActivity
    
    var body: some View {
        HStack(spacing: 12) {
            // 活动图标
            Image(systemName: "square.and.arrow.up.fill")
                .font(.system(size: 24))
                .foregroundColor(.theme.success)
                .frame(width: 40, height: 40)
                .background(Color.theme.success.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                // 活动描述
                Text("分享了故事板")
                    .font(.system(size: 14))
                    .foregroundColor(.theme.primaryText)
                
                // 故事板信息
                HStack {
                    KFImage(URL(string: activity.activity.storyInfo.avatar))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                    
                    Text(activity.activity.boardInfo.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.theme.success)
                }
                
                // 时间
                Text(formatTimeAgo(timestamp: activity.activity.ctime))
                    .font(.system(size: 12))
                    .foregroundColor(.theme.tertiaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(12)
    }
}

// MARK: - Create Character Activity View
struct CreateCharacterActivityView: View {
    let activity: UserActivity
    
    var body: some View {
        HStack(spacing: 12) {
            // 活动图标
            Image(systemName: "person.fill")
                .font(.system(size: 24))
                .foregroundColor(.theme.accent)
                .frame(width: 40, height: 40)
                .background(Color.theme.accent.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                // 活动描述
                Text("创建了角色")
                    .font(.system(size: 14))
                    .foregroundColor(.theme.primaryText)
                
                // 角色信息
                HStack {
                    KFImage(URL(string:activity.activity.roleInfo.characterAvatar))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                    
                    Text(activity.activity.roleInfo.characterName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.theme.accent)
                }
                
                // 时间
                Text(formatTimeAgo(timestamp: activity.activity.ctime))
                    .font(.system(size: 12))
                    .foregroundColor(.theme.tertiaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(12)
    }
}

