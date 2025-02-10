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
    @State private var selectedTab: Int = 0
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
        ScrollView {
            
            VStack(spacing: 0) {
                // 顶部个人信息区域
                VStack(spacing: 16) {
                    HStack {
                        Spacer()
                        // 编辑资料按钮
                        Button(action: {}) {
                            Text("编辑资料")
                                .font(.system(size: 14))
                                .foregroundColor(.black)
                        }
                        // 设置按钮
                        Button(action: {}) {
                            Image(systemName: "gear")
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 头像和用户信息
                    VStack(spacing: 8) {
                        // 头像
                        RectProfileImageView(
                            avatarUrl: user.avatar,
                            size: .InProfile2
                        )
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        
                        // 用户名
                        Text(user.name)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        
                        // 统计数据
                        HStack(spacing: 32) {
                            StatItem(count: 8, title: "关注",icon: "bell")
                            StatItem(count: 3, title: "粉丝",icon: "person")
                            StatItem(count: 2, title: "获赞",icon: "heart")
                        }
                    }
                }
                .padding(.vertical)
                // 分段控制器
                CustomSegmentedControl(
                    selectedIndex: $selectedTab,
                    titles: ["故事", "角色", "待发布"]
                )
                .padding(.top, 8)
                
                // 内容区域
                ProfileContentView(
                    selectedTab: $selectedTab,
                    viewModel: viewModel
                )
                
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
            .refreshable {
                await refreshData()
            }
            .task {
                await loadUserData()
            }
            .onChange(of: selectedTab) { newValue in
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
        await loadFilteredContent(for: selectedTab, forceRefresh: true)
    }
    
    private func loadUserData() async {
        if viewModel.profile.userID == 0 {
            viewModel.profile = await viewModel.fetchUserProfile()
        }
        await loadFilteredContent(for: selectedTab)
    }
    
    private func loadFilteredContent(for filter: Int, forceRefresh: Bool = false) async {
        do {
            switch filter {
            case 0:
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
                
            case 1:
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
            default:
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
            }
        } catch {
            print("Error loading filtered content: \(error)")
        }
    }
}

struct CustomSegmentedControl: View {
    @Binding var selectedIndex: Int
    let titles: [String]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 24) {
                ForEach(0..<titles.count, id: \.self) { index in
                    VStack(spacing: 10) {
                        Text(titles[index])
                            .font(.system(size: 14))
                            .foregroundColor(selectedIndex == index ? .white : .gray)
                        
                        // 下划线
                        Rectangle()
                            .fill(selectedIndex == index ? Color.orange : Color.clear)
                            .frame(height: 2)
                    }
                    .onTapGesture {
                        withAnimation {
                            selectedIndex = index
                        }
                    }
                }
            }
            .padding(.horizontal)
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
    @Binding var selectedIndex: Int
    let titles: [String]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 24) {
                ForEach(0..<titles.count, id: \.self) { index in
                    VStack(spacing: 8) {
                        Text(titles[index])
                            .font(.system(size: 14))
                            .foregroundColor(selectedIndex == index ? .white : .gray)
                        
                        // 下划线
                        Rectangle()
                            .fill(selectedIndex == index ? Color.orange : Color.clear)
                            .frame(height: 2)
                    }
                    .onTapGesture {
                        withAnimation {
                            selectedIndex = index
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Content View
private struct ProfileContentView: View {
    @Binding var selectedTab: Int
    let viewModel: ProfileViewModel
    var body: some View {
        VStack {
            TabView(selection: $selectedTab) {
                StoryboardsListView(boards: viewModel.storyboards)
                    .tag(0)
                RolesListView(roles: viewModel.storyRoles, viewModel: viewModel)
                    .tag(1)
                PendingTab()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
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

struct PendingTab: View {
    var body: some View {
        VStack {
            Spacer()
            Image("raccoon_waiting") 
                .resizable()
                .frame(width: 100, height: 100)
            
            Text("改写故事")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.top, 16)
            
            Button(action: {
                
            }) {
                Text("去创作")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .cornerRadius(22)
            }
            .padding(.top, 24)
            
            Spacer()
        }
        .background(Color.black)
    }
}
