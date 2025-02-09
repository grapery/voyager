//
//  UserProfileView.swift
//  voyager
//
//  Created by grapestree on 2024/10/2.
//


import SwiftUI
import Kingfisher

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
                    VStack(spacing: 0) {
                        ZStack {
                            // 背景图片
                            KFImage(URL(string: defaultAvator))
                                .resizable() // 允许调整大小
                                .aspectRatio(contentMode: .fill) // 填充模式
                                .frame(height: 240) // 限制高度
                                .clipped() // 裁剪超出部分
                                .blur(radius: 1.0)
                            
                            VStack(spacing: 0) {
                                ProfileHeaderView(user: user)
                                StatisticsView(viewModel: viewModel)
                            }
                        }
                        .frame(height: 240)
                        // ... rest of the content ...
                    }
                    .frame(height: 240)
                    
                    // 分段控制器
                    SegmentedControlView(
                        selectedFilter: $selectedFilter,
                        animation: animation
                    )
                    .padding(.top, 5)    // 上方间距 4px
                    .padding(.bottom, 10) // 下方间距 16px
                    
                    // 内容区域
                    ProfileContentView(
                        selectedFilter: selectedFilter,
                        viewModel: viewModel
                    )
                }
            }
            .background(Color(hex: "1C1C1E"))
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


struct StoryboardCell: View {
    let board: StoryBoard
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧装饰条
            Rectangle()
                .fill(Color.primaryGreenBackgroud.opacity(0.3))
                .frame(width: 12)
            
            // 虚线分隔带圆孔
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.primaryGreenBackgroud.opacity(0.3))
                        .frame(width: 2)
                        .frame(height: geometry.size.height / 4)
                    
                    Circle()
                        .fill(Color(hex: "E7E7E7"))
                        .frame(width: 6, height: 6)
                    
                    Rectangle()
                        .fill(Color.primaryGreenBackgroud.opacity(0.3))
                        .frame(width: 2)
                        .frame(height: geometry.size.height / 2)
                        
                    Circle()
                        .fill(Color(hex: "E7E7E7"))
                        .frame(width: 6, height: 6)
                        
                    Rectangle()
                        .fill(Color.primaryGreenBackgroud.opacity(0.3))
                        .frame(width: 2)
                        .frame(height: geometry.size.height / 4)
                }
            }
            .frame(width: 6)
            
            // 主要内容
            VStack(alignment: .leading, spacing: 8) {
                // 标题行
                HStack {
                    Text(board.boardInfo.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(formatDate(board.boardInfo.ctime))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                // 内容
                Text(board.boardInfo.content)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // 底部统计
                HStack {
                    StatLabel(
                        icon: "bubble.left",
                        count: 10,
                        iconColor: .gray,
                        countColor: .gray
                    )
                    
                    Spacer()
                    
                    StatLabel(
                        icon: "heart",
                        count: 10,
                        iconColor: .gray,
                        countColor: .gray
                    )
                    
                    Spacer()
                    
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .background(Color.primaryBackgroud) // 深灰色背景
        .cornerRadius(8) // 整体圆角
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
        LazyVStack(spacing: 12) {
            ForEach(roles, id: \.id) { role in
                ProfileRoleCell(role: role, viewModel: viewModel)
            }
        }
        .padding(.horizontal, 16)
    }
}

struct ProfileRoleCell: View {
    let role: StoryRole
    @StateObject var viewModel: ProfileViewModel
    @State private var showRoleDetail = false
    
    var body: some View {
        Button(action: { showRoleDetail = true }) {
            HStack(spacing: 12) {
                // 角色头像
                RectProfileImageView(
                    avatarUrl: role.role.characterAvatar.isEmpty ? defaultAvator : role.role.characterAvatar,
                    size: .InContent
                )
                .frame(width: 64, height: 64)
                .cornerRadius(32) // 圆形头像
                
                VStack(alignment: .leading, spacing: 4) {
                    // 角色名称
                    Text(role.role.characterName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    // 角色描述
                    Text(role.role.characterDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // 右侧箭头
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.primaryBackgroud.opacity(0.3))
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showRoleDetail) {
            NavigationStack {
                StoryRoleDetailView(
                    storyId: role.role.storyID,
                    roleId: role.role.roleID,
                    userId: viewModel.user?.userID ?? 0,
                    role: role
                )
                .navigationBarItems(leading: Button(action: {
                    showRoleDetail = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                })
            }
        }
    }
}

// 修改统计标签组件
struct StatLabel: View {
    let icon: String
    let count: Int
    var iconColor: Color = .secondary
    var countColor: Color = .secondary
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
            Text("\(count)")
                .foregroundColor(countColor)
                .font(.system(size: 14))
        }
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
        .background(Color.white.opacity(0.3)) // 添加半透明白色背景
    }
}

private struct StatItem: View {
    let count: Int
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.system(size: 14))
            Text("\(count) \(title)")
                .foregroundColor(.white)
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
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.5)) {
                        selectedFilter = filter 
                    }
                }) {
                    Text(filter.title)
                        .foregroundColor(selectedFilter == filter ? .white : .gray)
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: 128)
                        .frame(height: 32)
                        .background(
                            Capsule()
                                .fill(selectedFilter == filter ? Color.primaryGreenBackgroud : Color(hex: "E7E7E7"))
                                .matchedGeometryEffect(id: selectedFilter == filter ? "TAB" : "", in: animation)
                        )
                        .padding(.horizontal, 4)
                }
            }
        }
        .padding(2) // 添加内边距，让按钮与外框有间隔
        .background(
            Capsule()
                .fill(Color.white)
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}

// MARK: - Content View
private struct ProfileContentView: View {
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
        ScrollView {
            LazyVStack(spacing: 12) { // 增加卡片间距
                ForEach(boards, id: \.id) { board in
                    StoryboardCell(board: board)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(hex: "1C1C1E")) // 使用深色背景
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
