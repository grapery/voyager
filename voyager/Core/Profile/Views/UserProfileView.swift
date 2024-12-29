//
//  UserProfileView.swift
//  voyager
//
//  Created by grapestree on 2024/10/2.
//


import SwiftUI

// MARK: - Main View
struct UserProfileView: View {
    @State private var selectedFilter: UserProfileFilterViewModel = .storyboards
    @Namespace var animation
    var user: User
    @StateObject var viewModel: ProfileViewModel
    @GestureState private var dragOffset: CGFloat = 0
    @State private var showingImagePicker = false
    @State private var showingEditProfile = false
    @State private var showingSubView = false
    @State private var backgroundImage: UIImage?
    
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
        self.user = user
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // 用户信息头部
                    ProfileHeaderView(user: user)
                    
                    // 统计信息
                    StatisticsView(viewModel: viewModel)
                    
                    // 分段控制器
                    SegmentedControlView(
                        selectedFilter: $selectedFilter,
                        animation: animation
                    )
                    
                    // 内容区域
                    ContentView(
                        selectedFilter: selectedFilter,
                        viewModel: viewModel
                    )
                }
            }
            .background(Color(hex: "1C1C1E"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileSettingsButton(action: handleSettingsPress)
                }
            }
            .sheet(isPresented: $showingSubView) {
                ProfileSheetContent(
                    showingEditProfile: showingEditProfile,
                    showingImagePicker: showingImagePicker,
                    user: user,
                    backgroundImage: $backgroundImage,
                    onDismiss: handleSheetDismiss
                )
            }
            .background(Color(.systemBackground))
            .refreshable { await refreshData() }
            .task { await loadUserData() }
            .onChange(of: selectedFilter) { newValue in
                Task {
                    await loadFilteredContent(for: newValue)
                }
            }
        }
    }
    
    // MARK: - Action Handlers
    private func handleHeaderLongPress() {
        showingSubView = true
        showingImagePicker = true
    }
    
    private func handleSettingsPress() {
        showingSubView = true
        showingEditProfile = true
    }
    
    private func handleSheetDismiss() {
        showingSubView = false
        showingEditProfile = false
        showingImagePicker = false
    }
    
    // MARK: - Data Loading Methods
    private func refreshData() async {
        await loadFilteredContent(for: selectedFilter, forceRefresh: true)
    }
    
    private func loadUserData() async {
        if viewModel.profile.userID == 0 {
            viewModel.profile = await viewModel.fetchUserProfile()
        }
        await loadFilteredContent(for: selectedFilter)
    }
    
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


// MARK: - Background Image View
private struct BackgroundImageView: View {
    let image: UIImage?
    
    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 280)
                .clipped()
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 280)
        }
    }
}

// MARK: - User Info Header
private struct UserInfoHeader: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 12) {
            CircularProfileImageView(avatarUrl: user.avatar, size: .InProfile)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(user.desc.isEmpty ? "神秘的人物，没有简介！" : user.desc)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            Spacer()
        }
    }
}

// MARK: - Profile Stats Row
private struct ProfileStatsRow: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
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
}

// MARK: - Filter Tab Bar
private struct FilterTabBar: View {
    @Binding var selectedFilter: UserProfileFilterViewModel
    var animation: Namespace.ID
    
    var body: some View {
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
    }
}

// MARK: - Profile Content View
private struct ProfileContentView: View {
    let selectedFilter: UserProfileFilterViewModel
    let dragOffset: CGFloat
    let viewModel: ProfileViewModel
    let onFilterChange: (UserProfileFilterViewModel) -> Void
    
    var body: some View {
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
                    .onEnded { value in
                        let threshold = geometry.size.width * 0.25
                        if value.translation.width > threshold && selectedFilter != .storyboards {
                            onFilterChange(.storyboards)
                        } else if value.translation.width < -threshold && selectedFilter != .roles {
                            onFilterChange(.roles)
                        }
                    }
            )
        }
        .frame(height: UIScreen.main.bounds.height * 0.7)
    }
}

// MARK: - Profile Sheet Content
private struct ProfileSheetContent: View {
    let showingEditProfile: Bool
    let showingImagePicker: Bool
    let user: User
    @Binding var backgroundImage: UIImage?
    let onDismiss: () -> Void
    
    var body: some View {
        Group {
            if showingEditProfile {
                EditUserProfileView(user: user)
            } else if showingImagePicker {
                SingleImagePicker(image: $backgroundImage)
            }
        }
        .onDisappear(perform: onDismiss)
    }
}

// MARK: - Profile Settings Button
private struct ProfileSettingsButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape.fill")
                .foregroundColor(.white)
        }
    }
}

// MARK: - Existing Supporting Views
// Keep the existing StatView, StoryCardRowView, RolesListView, etc.
// ... (rest of the supporting view implementations remain unchanged)

// MARK: - Stat View
struct StatView: View {
    let icon: String
    let count: Int64
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.system(size: 16))
            
            Text("\(count) \(title)")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

// MARK: - Storyboard Row View
struct StoryboardRowView: View {
    let boards: [StoryBoard]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(boards, id: \.id) { board in
                    StoryboardCell(board: board)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(uiColor: .systemBackground))
    }
}

struct StoryboardCell: View {
    let board: StoryBoard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题行
            HStack {
                Text(board.boardInfo.title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(formatDate(board.boardInfo.ctime))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            // 内容
            Text(board.boardInfo.content)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(3)
                .padding(.bottom, 4)
            
            // 底部统计
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 14))
                    Text("\(10)")
                }
                .foregroundColor(.secondary)
                .font(.system(size: 14))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                        .font(.system(size: 14))
                    Text("\(20)")
                }
                .foregroundColor(.secondary)
                .font(.system(size: 14))
                
                Spacer()
                
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Roles List View
struct RolesListView: View {
    let roles: [StoryRole]
    var viewModel: ProfileViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(roles, id: \.id) { role in
                    RoleCell(role: role, viewModel: viewModel)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(uiColor: .systemBackground))
    }
}

struct RoleCell: View {
    let role: StoryRole
    @StateObject var viewModel: ProfileViewModel
    @State private var showRoleDetail = false
    
    var body: some View {
        Button(action: { showRoleDetail = true }) {
            HStack(spacing: 12) {
                // 角色头像
                RectProfileImageView(
                    avatarUrl: role.role.characterAvatar.isEmpty ? defaultAvator : role.role.characterAvatar,
                    size: .InProfile
                )
                .frame(width: 56, height: 56)
                .cornerRadius(6)
                
                // 角色信息
                VStack(alignment: .leading, spacing: 6) {
                    Text(role.role.characterName)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    
                    Text(role.role.characterDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    // 统计信息
                    HStack(spacing: 16) {
                        StatLabel(icon: "doc.text", count: 22)
                        StatLabel(icon: "bubble.left", count: 42)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showRoleDetail) {
            StoryRoleDetailView(
                storyId: role.role.storyID,
                roleId: role.role.roleID,
                userId: viewModel.user?.userID ?? 0,
                role: role
            )
        }
    }
}

// 新增辅助视图
private struct StatLabel: View {
    let icon: String
    let count: Int64
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text("\(count)")
        }
        .font(.system(size: 14))
        .foregroundColor(.secondary)
    }
}

// MARK: - Interaction Button
struct ProfileInteractionButton: View {
    let icon: String
    let count: Int
    let isActive: Bool
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text("\(count)")
                    .font(.system(size: 14))
            }
            .foregroundColor(isActive ? .blue : .gray)
        }
    }
}


// MARK: - Statistics View
private struct StatisticsView: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        HStack(spacing: 40) {
            StatItem(
                count: 9,
                title: "个故事",
                icon: "mountain.2"
            )
            
            StatItem(
                count: 8,
                title: "个角色",
                icon: "person"
            )
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

private struct StatItem: View {
    let count: Int
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .font(.system(size: 14))
            Text("\(count) \(title)")
                .foregroundColor(.gray)
                .font(.system(size: 14))
        }
    }
}

// MARK: - Segmented Control View
private struct SegmentedControlView: View {
    @Binding var selectedFilter: UserProfileFilterViewModel
    var animation: Namespace.ID
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(UserProfileFilterViewModel.allCases, id: \.self) { filter in
                Button(action: { selectedFilter = filter }) {
                    VStack(spacing: 8) {
                        Text(filter.title)
                            .foregroundColor(selectedFilter == filter ? .white : .gray)
                            .font(.system(size: 16, weight: .medium))
                        
                        ZStack {
                            if selectedFilter == filter {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.green)
                                    .frame(width: 30, height: 3)
                                    .matchedGeometryEffect(id: "TAB", in: animation)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .background(Color(hex: "2C2C2E"))
    }
}

// MARK: - Content View
private struct ContentView: View {
    let selectedFilter: UserProfileFilterViewModel
    let viewModel: ProfileViewModel
    
    var body: some View {
        VStack {
            switch selectedFilter {
            case .storyboards:
                StoryboardsListView(boards: viewModel.storyboards)
            case .roles:
                RolesListView(roles: viewModel.storyRoles, viewModel: viewModel)
            }
        }
    }
}

// MARK: - Storyboards List View
private struct StoryboardsListView: View {
    let boards: [StoryBoard]
    
    var body: some View {
        LazyVStack(spacing: 1) {
            ForEach(boards, id: \.id) { board in
                StoryboardCell(board: board)
            }
        }
        .background(Color(hex: "1C1C1E"))
    }
}


private struct StatInfoItem: View {
    let icon: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.gray)
            Text("\(count)")
                .foregroundColor(.gray)
                .font(.system(size: 14))
        }
        .padding(.trailing, 16)
    }
}
