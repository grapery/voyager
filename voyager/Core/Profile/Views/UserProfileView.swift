//
//  UserProfileView.swift
//  voyager
//
//  Created by grapestree on 2024/10/2.
//


import SwiftUI

struct UserProfileView: View {
    @State private var selectedFilter: UserProfileFilterViewModel = .storyboards
    @State private var showingEditProfile = false
    @Namespace var animation
    var user: User
    @StateObject var viewModel: ProfileViewModel
    @GestureState private var dragOffset: CGFloat = 0
    
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
        self.user = user
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // 头部个人信息区域
                    VStack(spacing: 16) {
                        // 头像和用户名
                        HStack(spacing: 12) {
                            CircularProfileImageView(avatarUrl: user.avatar, size: .InProfile)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Text(user.desc.isEmpty ? "神秘的人物，没有简介！" : user.desc)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                        }
                        
                        // 统计数据
                        HStack(spacing: 32) {
                            StatView(
                                icon: "mountain.2",
                                count: Int64(viewModel.profile.createdStoryNum),
                                title: "个故事"
                            )
                            
                            StatView(
                                icon: "person",
                                count: Int64(viewModel.profile.createdRoleNum),
                                title: "个故事角色"
                            )
                        }
                    }
                    .padding(16)
                    
                    Divider()
                    
                    // 分类标签栏
                    HStack(spacing: 0) {
                        ForEach(UserProfileFilterViewModel.allCases, id: \.self) { filter in
                            TabButton(
                                title: filter.title,
                                isSelected: selectedFilter == filter
                            ) {
                                withAnimation {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                    
                    // 内容区域 - 支持左右滑动
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            StoryboardRowView(boards: viewModel.storyboards)
                                .frame(width: geometry.size.width)
                            
                            RolesListView(roles: viewModel.storyRoles, viewModel: viewModel)
                                .frame(width: geometry.size.width)
                        }
                        .offset(x: -CGFloat(selectedFilter.rawValue) * geometry.size.width)
                        .offset(x: dragOffset)
                        .animation(.interactiveSpring(), value: selectedFilter)
                        .gesture(
                            DragGesture()
                                .updating($dragOffset) { value, state, _ in
                                    state = value.translation.width
                                }
                                .onEnded { value in
                                    let threshold = geometry.size.width * 0.25
                                    if value.translation.width > threshold && selectedFilter != .storyboards {
                                        selectedFilter = .storyboards
                                    } else if value.translation.width < -threshold && selectedFilter != .roles {
                                        selectedFilter = .roles
                                    }
                                }
                        )
                    }
                    .frame(height: UIScreen.main.bounds.height * 0.7)
                }
            }
            .background(Color(.systemBackground))
            .refreshable {
                await refreshData()
            }
            .task {
                await loadUserData()
            }
            .onChange(of: selectedFilter) { newValue in
                Task {
                    await loadFilteredContent(for: newValue)
                }
            }
        }
    }
    
    // 刷新数据
    private func refreshData() async {
        do {
            // 显示加载指示器
            await MainActor.run {
                // 如果需要，这里可以设置加载状态
            }
            
            // 强制刷新当前选中标签的内容
            await loadFilteredContent(for: selectedFilter, forceRefresh: true)
            
            // 隐藏加载指示器
            await MainActor.run {
                // 如果需要，这里可以重置加载状态
            }
        } catch {
            print("Error refreshing data: \(error)")
        }
    }
    
    // 加载用户数据
    private func loadUserData() async {
        do {
            await MainActor.run {
                // 如果需要，这里可以设置加载状态
            }
            
            // 加载用户资料
            if viewModel.profile.userID == 0 {
                viewModel.profile = await viewModel.fetchUserProfile()
            }
            
            // 加载当前选中标签的内容
            await loadFilteredContent(for: selectedFilter)
            
            await MainActor.run {
                // 如果需要，这里可以重置加载状态
            }
        } catch {
            print("Error loading user data: \(error)")
        }
    }
    
    // 加载过滤内容
    private func loadFilteredContent(for filter: UserProfileFilterViewModel, forceRefresh: Bool = false) async {
        do {
            switch filter {
            case .storyboards:
                if viewModel.storyboards.isEmpty || forceRefresh {
                    let (boards, _) = try await viewModel.fetchUserCreatedStoryboards(
                        userId: user.userID,
                        groupId: 0,
                        storyId: 0
                    )
                    if let boards = boards {
                        await MainActor.run {
                            viewModel.storyboards = boards
                        }
                    }
                }
                
            case .roles:
                if viewModel.storyRoles.isEmpty || forceRefresh {
                    let (roles, _) = try await viewModel.fetchUserCreatedStoryRoles(
                        userId: user.userID,
                        groupId: 0,
                        storyId: 0
                    )
                    if let roles = roles {
                        await MainActor.run {
                            viewModel.storyRoles = roles
                        }
                    }
                }
            }
        } catch {
            print("Error loading filtered content: \(error)")
        }
    }
}

// 统计视图组件
struct StatView: View {
    let icon: String
    let count: Int64
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.system(size: 16))
            
            Text("\(count) \(title)")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
}

// 标签按钮组件
struct ProfileTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// 列表项组件（用于故事板和角色列表）
struct ContentItemView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(8)
    }
}

struct StoriesGridView: View {
    let stories: [Story]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(stories, id: \.id) { story in
                StoryCardRowView()
                    .aspectRatio(1, contentMode: .fit)
            }
        }
        .padding()
    }
}

struct StoryCardRowView: View{
    var body: some View{
        VStack(alignment: .center){
           Text("Story")
        }
    }
}
    
struct RolesListView: View {
    let roles: [StoryRole]
    var viewModel: ProfileViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(roles, id: \.id) { role in
                    StoryRoleRowView(role: role, viewModel: viewModel, userId: viewModel.user!.userID)
                }
            }
        }
    }
}

struct StoryRoleRowView: View {
    var role: StoryRole
    @State private var showRoleDetail = false
    var viewModel: ProfileViewModel
    let userId: Int64
    
    var body: some View {
        Button(action: { showRoleDetail = true }) {
            HStack(alignment: .top, spacing: 5) {
                // Avatar - 让图片更大且占据左侧空间
                if !role.role.characterAvatar.isEmpty {
                    RectProfileImageView(avatarUrl: role.role.characterAvatar, size: .InProfile2)
                } else {
                    RectProfileImageView(avatarUrl: defaultAvator, size: .InProfile2)
                }
                
                // Right side content
                VStack(alignment: .leading, spacing: 4) {
                    // Name and Description
                    Text(role.role.characterName)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(role.role.characterDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(3)
                    
                    // Stats moved below description
                    HStack(spacing: 16) {
                        // 参与故事板数量
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text")
                                .foregroundColor(.gray)
                            Text("\(10) 故事板")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        // 发送消息数量
                        HStack(spacing: 4) {
                            Image(systemName: "message")
                                .foregroundColor(.gray)
                            Text("\(10) 消息")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                }
                Spacer()
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showRoleDetail) {
            StoryRoleDetailView(
                storyId: role.role.storyID,
                roleId: role.role.roleID,
                userId: self.userId,
                role: self.role
            )
        }
    }
}

struct StoryboardRowView: View {
    let boards: [StoryBoard]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(boards, id: \.id) { board in
                    StoryboardRowCellView(info: board)
                }
            }
        }
    }
}

struct StoryboardRowCellView: View {
    var info: StoryBoard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(info.boardInfo.title)
                    .font(.system(size: 16, weight: .semibold))
                
                if info.boardInfo.isAiGen {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text("#\(info.boardInfo.num)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            // Content
            Text(info.boardInfo.content)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Footer
            if !info.boardInfo.roles.isEmpty {
                HStack {
                    Image(systemName: "person.2")
                        .foregroundColor(.gray)
                    Text("\(info.boardInfo.roles.count) 个角色")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            // Interaction buttons
            HStack(spacing: 24) {
                InteractionButton(icon: "bubble.left", count: 0, isActive: false)
                InteractionButton(icon: "heart", count: 0, isActive: false)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }
}
