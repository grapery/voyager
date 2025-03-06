//
//  GroupDetail.swift
//  voyager
//
//  Created by grapestree on 2024/9/30.
//

import SwiftUI
import Kingfisher
import Combine

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
        ScrollView {
            GeometryReader { geometry in
                Color.clear.preference(key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named("scroll")).minY)
            }
            .frame(height: 0)
            
            VStack(spacing: 0) {
                // Group Info Header with Background
                ZStack(alignment: .top) {
                    // Background Image
                    KFImage(URL(string: defaultAvator))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)  // 增加高度以容纳所有内容
                        .clipped()
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black.opacity(0.3), Color.black.opacity(0.5)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    VStack(spacing: 0) {
                        // Top Navigation Bar
                        HStack {
                            // Back Button
                            Button(action: {
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("返回")
                                        .font(.system(size: 16))
                                }
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Capsule())
                            }
                            
                            Spacer()
                            
                            // Action Buttons
                            HStack(spacing: 12) {
                                Button(action: {
                                    showNewStoryView = true
                                }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 32, height: 32)
                                        .background(Color.black.opacity(0.3))
                                        .clipShape(Circle())
                                }
                                
                                Button(action: {
                                    showUpdateGroupView = true
                                }) {
                                    Image(systemName: "gearshape")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 32, height: 32)
                                        .background(Color.black.opacity(0.3))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        // Group Info Content
                        VStack(alignment: .leading, spacing: 12) {
                            // Group Avatar and Basic Info
                            HStack(spacing: 12) {
                                KFImage(URL(string: group!.info.avatar))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(group!.info.name)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    HStack(spacing: 16) {
                                        // Story Count
                                        Label("\(group!.info.profile.groupStoryNum) 个故事", systemImage: "book.fill")
                                            .font(.system(size: 14))
                                        
                                        // Member Count
                                        Label("\(group!.info.profile.groupMemberNum) 个成员", systemImage: "person.2.fill")
                                            .font(.system(size: 14))
                                    }
                                    .foregroundColor(.white.opacity(0.9))
                                }
                                
                                Spacer()
                                
                                // Join Button
                                Button(action: {
                                    Task {
                                        await viewModel.JoinGroup(groupdId: group!.info.groupID)
                                    }
                                }) {
                                    Text(group!.info.currentUserStatus.isJoined ? "已加入" : "加入")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(group!.info.currentUserStatus.isJoined ? .gray : .white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(group!.info.currentUserStatus.isJoined ? Color.gray.opacity(0.1) : Color.blue)
                                        .clipShape(Capsule())
                                }
                            }
                            
                            // Group Description
                            if !group!.info.desc.isEmpty {
                                Text(group!.info.desc)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                    .lineLimit(3)
                            }
                            
                            // Member Avatars
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: -8) {
                                    ForEach(group!.info.members.prefix(6), id: \.userID) { member in
                                        KFImage(URL(string: member.avatar.isEmpty ? defaultAvator : member.avatar))
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                    }
                                    
                                    if group!.info.members.count > 6 {
                                        Text("+\(group!.info.members.count - 6)")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                            .frame(width: 32, height: 32)
                                            .background(Color.gray.opacity(0.5))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)  // 增加与顶部导航栏的间距
                    }
                }
                
                // Story List Section (Non-sticky version)
                VStack(spacing: 0) {
                    // Horizontal Story List
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            Button(action: {
                                selectedStoryId = nil
                            }) {
                                VStack {
                                    Circle()
                                        .fill(selectedStoryId == nil ? Color.blue : Color.gray.opacity(0.3))
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Image(systemName: "timelapse")
                                                .foregroundColor(.white)
                                        )
                                    Text("全部")
                                        .font(.system(size: 12))
                                }
                            }
                            
                            ForEach(viewModel.storys) { story in
                                Button(action: {
                                    selectedStoryId = story.storyInfo.id
                                }) {
                                    VStack {
                                        KFImage(URL(string: story.storyInfo.avatar))
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedStoryId == story.storyInfo.id ? Color.orange : Color.gray, lineWidth: 2)
                                            )
                                        Text(story.storyInfo.name.prefix(4))
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
                
                // Story Updates List
                LazyVStack(spacing: 0) {
                    if let selectedId = selectedStoryId {
                        // Show updates for selected story
                        ForEach(viewModel.storys.filter { $0.storyInfo.id == selectedId }) { story in
                            StoryUpdateCell(story: story, userId: user.userID, viewModel: viewModel)
                        }
                    } else {
                        // Show all updates
                        ForEach(viewModel.storys.sorted { $0.storyInfo.ctime > $1.storyInfo.ctime }) { story in
                            StoryUpdateCell(story: story, userId: user.userID, viewModel: viewModel)
                        }
                    }
                }
                .padding(.top, isHeaderSticky ? 100 : 0) // Add padding when header is sticky
            }
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            withAnimation {
                isHeaderSticky = value < -200 // Adjust this value based on when you want the header to stick
            }
        }
        .overlay(
            Group {
                if isHeaderSticky {
                    // Sticky Header Overlay
                    VStack(spacing: 0) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                Button(action: {
                                    selectedStoryId = nil
                                }) {
                                    VStack {
                                        Circle()
                                            .fill(selectedStoryId == nil ? Color.blue : Color.gray.opacity(0.3))
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Image(systemName: "star.fill")
                                                    .foregroundColor(.white)
                                            )
                                        Text("全部")
                                            .font(.system(size: 12))
                                    }
                                }
                                
                                ForEach(viewModel.storys) { story in
                                    Button(action: {
                                        selectedStoryId = story.storyInfo.id
                                    }) {
                                        VStack {
                                            KFImage(URL(string: story.storyInfo.avatar))
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 60, height: 60)
                                                .clipShape(Circle())
                                                .overlay(
                                                    Circle()
                                                        .stroke(selectedStoryId == story.storyInfo.id ? Color.blue : Color.clear, lineWidth: 2)
                                                )
                                            Text(story.storyInfo.name.prefix(4))
                                                .font(.system(size: 12))
                                                .lineLimit(1)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        
                        Divider()
                    }
                    .background(Color(UIColor.systemBackground))
                    .transition(.opacity)
                }
            }
            , alignment: .top
        )
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
        .onAppear {
            Task {
                await refreshGroupData()
            }
        }
    }
    
    private func refreshGroupData() async {
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
                        Image(systemName: "bell.circle")
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
                        Image(systemName: "heart.circle")
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
                        Image(systemName: "square.and.arrow.up.circle")
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
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                KFImage(URL(string: story.storyInfo.avatar))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(story.storyInfo.name)
                        .font(.system(size: 15, weight: .medium))
                    Text(formatTimeAgo(timestamp: story.storyInfo.ctime))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Content
            Text(story.storyInfo.origin)
                .font(.system(size: 14))
                .lineLimit(3)
            
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
        .compositingGroup() // Add this to ensure proper layering
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
