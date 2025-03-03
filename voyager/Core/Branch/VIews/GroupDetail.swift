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

    init(user: User, group: BranchGroup) {
        self.user = user
        self.currentUser = user
        self.group = group
        self.viewModel = GroupDetailViewModel(user: user, groupId: (group.info.groupID))
    }
    
    var body: some View {
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
            
            // Custom Tab View
            CustomTabView(selectedTab: $selectedTab)
                .padding(.vertical, 8)
            Divider()
            
            // Story List
            if selectedTab == 0 {
                ScrollView {
                    RefreshControl(isRefreshing: $isRefreshing) {
                        await refreshGroupData()
                    }
                    
                    if viewModel.storys.isEmpty {
                        EmptyStateView(
                            icon: "doc.text.image",
                            title: "暂无关注的故事",
                            message: "快来创建第一个故事吧"
                        )
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.storys) { story in
                                NavigationLink(destination: StoryView(story: story, userId: user.userID)) {
                                    StoryCellView(story: story, userId: user.userID, viewModel: viewModel)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            } else if selectedTab == 1 {
                ScrollView {
                    RefreshControl(isRefreshing: $isRefreshing) {
                        await refreshGroupData()
                    }
                    
                    if viewModel.storys.isEmpty {
                        EmptyStateView(
                            icon: "doc.text.image",
                            title: "暂无最新故事",
                            message: "快来创建第一个故事吧"
                        )
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.storys.sorted { $0.storyInfo.ctime > $1.storyInfo.ctime }) { story in
                                NavigationLink(destination: StoryView(story: story, userId: user.userID)) {
                                    StoryCellView(story: story, userId: user.userID, viewModel: viewModel)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)  // Hide the default navigation bar
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
    let tabs = ["关注", "最近"]
    
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
