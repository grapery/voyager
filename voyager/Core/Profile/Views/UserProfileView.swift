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
    @State private var backgroundImage: UIImage?
    @State private var showSettings = false
    
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
        self.user = user
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 顶部个人信息区域
                VStack(spacing: 16) {
                    // 头像和用户信息
                    VStack(spacing: 8) {
                        // 头像
                        VStack {
                            RectProfileImageView(
                                avatarUrl: user.avatar,
                                size: .InProfile2
                            )
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        }
                        .onTapGesture {
                            showingImagePicker = true
                        }
                        
                        // 用户名
                        Text(user.name)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        
                        // 统计数据
                        HStack(spacing: 32) {
                            StatItem(count: 8, title: "关注", icon: "bell")
                            StatItem(count: 3, title: "粉丝", icon: "person")
                            StatItem(count: 2, title: "获赞", icon: "heart")
                        }
                    }
                }
                .padding(.vertical)
                .background(Color(hex: "1C1C1E")) // 添加背景色
                
                // 分段控制器
                CustomSegmentedControl(
                    selectedIndex: $selectedTab,
                    titles: ["故事", "角色", "待发布"]
                )
                .padding(.top, 8)
                .background(Color(hex: "1C1C1E")) // 添加背景色
                
                // 内容区域
                ProfileContentView(
                    selectedTab: $selectedTab,
                    viewModel: viewModel
                )
            }
            .background(Color(hex: "1C1C1E")) // 内容背景色
        }
        .background(Color(hex: "1C1C1E")) // ScrollView 背景色
        .safeAreaInset(edge: .top) {
            // 操作按钮行
            HStack {
                Spacer()
                // 编辑资料按钮
                Button(action: {
                    showingEditProfile = true
                }) {
                    Text("编辑资料")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                // 设置按钮
                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gear")
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(hex: "1C1C1E"))
        }
        .sheet(isPresented: $showingEditProfile) {
            EditUserProfileView(user: user)
        }
        .sheet(isPresented: $showingImagePicker) {
            SingleImagePicker(image: $backgroundImage)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .refreshable {
            await refreshData()
        }
        .task {
            await loadUserData()
        }
        .onChange(of: selectedTab) { newValue in
            Task {
                await loadFilteredContent(for: selectedTab)
            }
        }
//        .fullScreenCover(isPresented: $showEditView) {
//            EditStoryBoardView(
//                storyId: storyId,
//                boardId: (board?.boardInfo.storyBoardID)!,
//                userId: self.userId,
//                viewModel: self.viewModel
//            )
//        }
    }
    
    // MARK: - Action Handlers
    private func handleHeaderLongPress() {
        showingImagePicker = true
    }
    
    private func handleSettingsPress() {
        showingEditProfile = true
    }
    
    private func handleSheetDismiss() {
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
            print("loadFilteredContent : ",filter,"forceRefresh: ",forceRefresh)
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

// 更新分段控制器样式
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
                            .fill(selectedIndex == index ? Color.green : Color.clear)
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
        .background(Color(hex: "1C1C1E"))
        .padding(.bottom, 1) // 添加底部最小间距
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
        LazyVStack(spacing: 1) {
            ForEach(roles, id: \.id) { role in
                ProfileRoleCell(role: role, viewModel: viewModel)
            }
        }
    }
}

struct ProfileRoleCell: View {
    let role: StoryRole
    @StateObject var viewModel: ProfileViewModel
    @State private var showRoleDetail = false
    
    var body: some View {
        Button(action: { showRoleDetail = true }) {
            HStack(spacing: 0) {
                // 左侧角色图片
                KFImage(URL(string: role.role.characterAvatar.isEmpty ? defaultAvator : role.role.characterAvatar))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 100)
                    .clipped()
                
                // 右侧内容区域
                VStack(alignment: .leading, spacing: 12) {
                    // 标题和时间
                    HStack {
                        Text(role.role.characterName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(formatDate(timestamp: role.role.ctime))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    // 角色描述
                    Text(role.role.characterDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    
                    // 统计信息
                    HStack(spacing: 24) {
                        Label("\(role.role.storyboardNum) 故事", systemImage: "doc.text.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Label("\(role.role.likeCount) 赞", systemImage: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .background(Color(hex: "1C1C1E"))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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
                        .foregroundColor(.white)
                })
            }
        }
    }
    
    private func formatDate(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
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
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 故事标签页
            StoriesTab(viewModel: viewModel)
                .tag(0)
            
            // 角色标签页
            RolesTab(viewModel: viewModel)
                .tag(1)
            
            // 待发布标签页
            PendingTab(userId: viewModel.user?.userID ?? 0)
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(minHeight: UIScreen.main.bounds.height * 0.7)
        .background(Color(hex: "1C1C1E"))
    }
}

// 故事标签页
private struct StoriesTab: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        Group {
            if viewModel.storyboards.isEmpty {
                EmptyStateView(
                    image: "doc.text",
                    title: "还没有故事",
                    message: "开始创作你的第一个故事吧"
                )
            } else {
                StoryboardsListView(boards: viewModel.storyboards)
            }
        }
    }
}

// 角色标签页
private struct RolesTab: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        Group {
            if viewModel.storyRoles.isEmpty {
                EmptyStateView(
                    image: "person.circle",
                    title: "还没有角色",
                    message: "创建你的第一个角色吧"
                )
            } else {
                RolesListView(roles: viewModel.storyRoles, viewModel: viewModel)
                    .padding(.top, 0) // 移除顶部间距
            }
        }
        .background(Color(hex: "1C1C1E"))
    }
}

// 空状态视图
private struct EmptyStateView: View {
    let image: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: image)
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.gray)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.8))
            Spacer()
        }
    }
}

// 修改 StoryboardsListView
private struct StoryboardsListView: View {
    let boards: [StoryBoard]
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(boards, id: \.id) { board in
                StoryboardCell(board: board)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct PendingTab: View {
    @StateObject private var viewModel: UnpublishedStoryViewModel
    @State private var isRefreshing = false
    
    init(userId: Int64) {
        _viewModel = StateObject(wrappedValue: UnpublishedStoryViewModel(userId: userId))
    }
    
    var body: some View {
        ScrollView {
            RefreshableScrollView(
                isRefreshing: $isRefreshing,
                onRefresh: {
                    Task {
                        await viewModel.refreshData()
                        isRefreshing = false
                    }
                }
            ) {
                if viewModel.unpublishedStoryboards.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    storyBoardsListView
                }
            }
        }
        .task {
            if viewModel.unpublishedStoryboards.isEmpty {
                await viewModel.fetchUnpublishedStoryboards()
            }
        }
        .alert("加载失败", isPresented: $viewModel.hasError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            Text("暂无待发布的故事")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            Button(action: {
                // TODO: 实现创作功能
            }) {
                Text("去创作")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 120)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(22)
            }
            .padding(.top, 16)
            Spacer()
        }
        .frame(minHeight: 300)
    }
    
    private var storyBoardsListView: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.unpublishedStoryboards) { board in
                UnpublishedStoryBoardCellView(
                    board: board,
                    userId: viewModel.userId,
                    viewModel: viewModel
                )
                .onAppear {
                    if board.id == viewModel.unpublishedStoryboards.last?.id {
                        Task {
                            await viewModel.fetchUnpublishedStoryboards()
                        }
                    }
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            }
        }
        .padding(.vertical, 8)
    }
}

struct UnpublishedStoryBoardCellView: View {
    var board: StoryBoard
    var userId: Int64
    @ObservedObject var viewModel: UnpublishedStoryViewModel
    @State private var showingPublishAlert = false
    @State private var showingDeleteAlert = false
    @State private var showingEditView = false
    @State private var errorMessage: String = ""
    @State private var showingErrorToast = false
    @State private var showingErrorAlert = false
    
    private var headerView: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(board.boardInfo.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.vertical, 4)
            
            Spacer()
            
            Text(formatDate(timestamp: board.boardInfo.ctime))
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(board.boardInfo.content)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .lineLimit(3)
                .padding(.vertical, 4)
            
            let scenes = board.boardInfo.sences.list
            if !scenes.isEmpty {
                HStack {
                    Image(systemName: "photo.stack")
                        .foregroundColor(.gray)
                        .font(.system(size: 12))
                    Text("共\(scenes.count)个场景")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.top, 2)
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 24) {
            // 编辑按钮
            Button(action: {
                showingEditView = true
            }) {
                Image(systemName: "pencil.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
            }
            
            // 发布按钮
            Button(action: {
                showingPublishAlert = true
            }) {
                Image(systemName: "arrow.up.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            
            // 删除按钮
            Button(action: {
                showingDeleteAlert = true
            }) {
                Image(systemName: "trash.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.red)
            }
        }
        .padding(.top, 8)
    }
    
    var body: some View {
        mainContent
            .padding(12)
            .background(Color(hex: "1C1C1E"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .overlay(errorToastOverlay)
            .modifier(AlertModifier(
                showingPublishAlert: $showingPublishAlert,
                showingDeleteAlert: $showingDeleteAlert,
                showingEditView: $showingEditView,
                board: board,
                userId: userId,
                viewModel: viewModel
            ))
    }
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            contentView
            actionButtons
        }
    }
    
    private var errorToastOverlay: some View {
        Group {
            if showingErrorToast {
                ToastView(message: errorMessage)
                    .animation(.easeInOut)
                    .transition(.move(edge: .top))
            }
        }
    }
    
    private func formatDate(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return DateFormatter.shortDate.string(from: date)
    }
    
    private func ToastView(message: String) -> some View {
        VStack {
            Text(message)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
        }
        .padding(.top, 20)
    }
}

private struct AlertModifier: ViewModifier {
    @Binding var showingPublishAlert: Bool
    @Binding var showingDeleteAlert: Bool
    @Binding var showingEditView: Bool
    let board: StoryBoard
    let userId: Int64
    let viewModel: UnpublishedStoryViewModel
    
    func body(content: Content) -> some View {
        content
            .alert("确认发布", isPresented: $showingPublishAlert) {
                Button("取消", role: .cancel) { }
                Button("发布", role: .destructive) {
                    Task {
                        // TODO: 调用发布API
                        // await viewModel.publishStoryBoard(boardId: board.id)
                    }
                }
            } message: {
                Text("确定要发布这个故事板吗？发布后将无法修改。")
            }
            .alert("确认删除", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    Task {
                        // TODO: 调用删除API
                        // await viewModel.deleteUnpublishedStoryBoard(boardId: board.id)
                    }
                }
            } message: {
                Text("确定要删除这个故事板吗？此操作无法撤销。")
            }
            .fullScreenCover(isPresented: $showingEditView) {
                NavigationStack {
                    EditStoryBoardView(
                        storyId: board.boardInfo.storyID,
                        boardId: board.boardInfo.storyBoardID,
                        userId: userId,
                        viewModel: viewModel
                    )
                    .navigationBarItems(leading: Button(action: {
                        showingEditView = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                    })
                }
            }
    }
}

struct RefreshableScrollView<Content: View>: View {
    @Binding var isRefreshing: Bool
    let onRefresh: () -> Void
    let content: Content
    
    init(
        isRefreshing: Binding<Bool>,
        onRefresh: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self._isRefreshing = isRefreshing
        self.onRefresh = onRefresh
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                if geometry.frame(in: .global).minY > 50 {
                    Color.clear
                        .preference(key: RefreshKey.self, value: true)
                } else {
                    Color.clear
                        .preference(key: RefreshKey.self, value: false)
                }
            }
            .frame(height: 0)
            
            if isRefreshing {
                ProgressView()
                    .padding(8)
            }
            
            content
        }
        .onPreferenceChange(RefreshKey.self) { shouldRefresh in
            if shouldRefresh && !isRefreshing {
                isRefreshing = true
                onRefresh()
            }
        }
    }
}

private struct RefreshKey: PreferenceKey {
    static var defaultValue = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}



