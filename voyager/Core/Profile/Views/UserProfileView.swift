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
    @State private var isLoading = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
        self.user = user
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 顶部操作栏
                HStack {
                    Spacer()
                    Button(action: {
                        showingEditProfile = true
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(Color.theme.tertiaryText)
                    }
                    .padding(.horizontal, 16)
                    
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(Color.theme.tertiaryText)
                    }
                    .padding(.trailing, 16)
                }
                .padding(.vertical, 8)
                .background(Color.theme.background)
                
                // 用户信息区域
                ZStack {
                    // 背景图片
                    if let image = backgroundImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 260)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.black.opacity(0.3),
                                        Color.black.opacity(0.1)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        Rectangle()
                            .fill(Color.theme.tertiaryBackground)
                            .frame(height: 260)
                    }
                    
                    // 虚化圆形效果
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 200, height: 200)
                        .blur(radius: 30)
                    
                    // 用户信息
                    VStack(spacing: 20) {
                        // 头像
                        RectProfileImageView(
                            avatarUrl: user.avatar,
                            size: .InProfile2
                        )
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        // 用户名
                        Text(user.name)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        // 统计数据
                        HStack(spacing: 0) {
                            StatItem(count: 8, title: "关注", icon: "bell.fill")
                                .frame(maxWidth: .infinity)
                            
                            StatItem(count: 3, title: "粉丝", icon: "person.2.fill")
                                .frame(maxWidth: .infinity)
                            
                            StatItem(count: 2, title: "获赞", icon: "heart.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 24)
                }
                .onLongPressGesture {
                    showingImagePicker = true
                }
                
                // 分段控制器
                CustomSegmentedControl(
                    selectedIndex: $selectedTab,
                    titles: ["故事", "角色", "待发布"]
                )
                
                // 内容区域
                TabView(selection: $selectedTab) {
                    StoriesTab(viewModel: viewModel, isLoading: isLoading)
                        .tag(0)
                        .id("stories")
                    
                    RolesTab(viewModel: viewModel, isLoading: isLoading)
                        .tag(1)
                        .id("roles")
                    
                    PendingTab(userId: viewModel.user?.userID ?? 0)
                        .tag(2)
                        .id("pending")
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(minHeight: UIScreen.main.bounds.height * 0.6)
            }
        }
        .background(Color.theme.background)
        .sheet(isPresented: $showingEditProfile) {
            EditUserProfileView(user: user)
        }
        .sheet(isPresented: $showingImagePicker) {
            SingleImagePicker(image: $backgroundImage)
        }
        .onChange(of: backgroundImage) { newImage in
            if newImage != nil {
                handleImageSelected()
            }
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
                await loadFilteredContent(for: newValue, forceRefresh: true)
            }
        }
        .alert("错误", isPresented: $showingErrorAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
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
        isLoading = true
        defer { isLoading = false }
        await loadFilteredContent(for: selectedTab, forceRefresh: true)
    }
    
    private func loadUserData() async {
        isLoading = true
        defer { isLoading = false }
        
        if viewModel.profile.userID == 0 {
            viewModel.profile = await viewModel.fetchUserProfile()
        }
        await loadFilteredContent(for: selectedTab)
    }
    
    private func loadFilteredContent(for filter: Int, forceRefresh: Bool = false) async {
        isLoading = true
        
        do {
            switch filter {
            case 0:
                let (boards, _) = try await viewModel.fetchUserCreatedStoryboards(
                    userId: user.userID,
                    groupId: 0,
                    storyId: 0
                )
                await MainActor.run {
                    if let boards = boards {
                        viewModel.storyboards = boards
                    }
                    isLoading = false
                }
                
            case 1:
                let (roles, _) = try await viewModel.fetchUserCreatedStoryRoles(
                    userId: user.userID,
                    groupId: 0,
                    storyId: 0
                )
                await MainActor.run {
                    if let roles = roles {
                        viewModel.storyRoles = roles
                    }
                    isLoading = false
                }
                
            case 2:
                // 待发布标签页有自己的 ViewModel，不需要在这里处理
                isLoading = false
                
            default:
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
            print("Error loading filtered content: \(error)")
        }
    }
    
    private func handleImageSelected() {
        guard let image = backgroundImage else { return }
        
        // 显示加载状态
        isLoading = true
        
        Task {
            do {
                // 上传图片到阿里云 OSS
                let imageUrl = try await Task.detached {
                    try AliyunClient.UploadImage(image: image)
                }.value
                
                // 更新用户资料
                let updatedProfile = await viewModel.updateUserbackgroud(backgroundImage: imageUrl)
                
                await MainActor.run {
                    if updatedProfile {
                        // 更新成功
                        isLoading = false
                    } else {
                        // 更新失败
                        errorMessage = "更新背景图片失败"
                        showingErrorAlert = true
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "上传图片失败: \(error.localizedDescription)"
                    showingErrorAlert = true
                    isLoading = false
                }
            }
        }
    }
}

// 更新分段控制器样式
struct CustomSegmentedControl: View {
    @Binding var selectedIndex: Int
    let titles: [String]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(0..<titles.count, id: \.self) { index in
                    Button(action: {
                        withAnimation {
                            selectedIndex = index
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text(titles[index])
                                .font(.system(size: 15))
                                .foregroundColor(selectedIndex == index ? Color.theme.accent : Color.theme.tertiaryText)
                            
                            // 下划线
                            Rectangle()
                                .fill(selectedIndex == index ? Color.theme.accent : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            
            Divider()
                .background(Color.theme.divider)
        }
        .background(Color.theme.background)
    }
}



struct StoryboardCell: View {
    let board: StoryBoard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {    
            // 主要内容
            VStack(alignment: .leading, spacing: 12) {
                // 标题行
                HStack {
                    Text(board.boardInfo.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.theme.primaryText)
                    
                    Spacer()
                    
                    Text(formatDate(board.boardInfo.ctime))
                        .font(.system(size: 13))
                        .foregroundColor(Color.theme.tertiaryText)
                }
                
                // 内容
                Text(board.boardInfo.content)
                    .font(.system(size: 15))
                    .foregroundColor(Color.theme.secondaryText)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // 底部统计
                HStack(spacing: 24) {
                    StatLabel(
                        icon: "bubble.left.fill",
                        count: 10,
                        iconColor: Color.theme.tertiaryText,
                        countColor: Color.theme.tertiaryText
                    )
                    
                    StatLabel(
                        icon: "heart.fill",
                        count: 10,
                        iconColor: Color.theme.tertiaryText,
                        countColor: Color.theme.tertiaryText
                    )
                    
                    StatLabel(
                        icon: "arrow.triangle.2.circlepath",
                        count: 10,
                        iconColor: Color.theme.tertiaryText,
                        countColor: Color.theme.tertiaryText
                    )
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
        }
        .background(Color.theme.secondaryBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.theme.border, lineWidth: 0.5)
        )
    }
    
    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}


struct ProfileRoleCell: View {
    let role: StoryRole
    @StateObject var viewModel: ProfileViewModel
    @State private var showRoleDetail = false
    
    var body: some View {
        Button(action: { showRoleDetail = true }) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    // 角色头像
                    KFImage(URL(string: role.role.characterAvatar.isEmpty ? defaultAvator : role.role.characterAvatar))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // 角色信息
                    VStack(alignment: .leading, spacing: 4) {
                        Text(role.role.characterName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.theme.primaryText)
                        
                        Text(role.role.characterDescription)
                            .font(.system(size: 14))
                            .foregroundColor(Color.theme.secondaryText)
                            .lineLimit(2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                    .background(Color.theme.divider)
            }
            .background(Color.theme.background)
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
                        .foregroundColor(Color.theme.primaryText)
                })
            }
        }
    }
}

// 修改统计标签组件
struct StatLabel: View {
    let icon: String
    let count: Int
    var iconColor: Color = Color.theme.tertiaryText
    var countColor: Color = Color.theme.tertiaryText
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(iconColor)
            Text("\(count)")
                .font(.system(size: 13))
                .foregroundColor(countColor)
        }
    }
}



struct StatItem: View {
    let count: Int
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
            
            Text("\(count)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
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
                            .foregroundColor(selectedIndex == index ? Color.theme.primaryText : Color.theme.tertiaryText)
                        
                        // 下划线
                        Rectangle()
                            .fill(selectedIndex == index ? Color.theme.accent : Color.clear)
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


// 故事标签页
private struct StoriesTab: View {
    @ObservedObject var viewModel: ProfileViewModel
    let isLoading: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if viewModel.storyboards.isEmpty {
                    EmptyStateView(
                        image: "doc.text",
                        title: "还没有故事",
                        message: "开始创作你的第一个故事吧"
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(viewModel.storyboards) { board in
                        StoryboardCell(board: board)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.top, 16)
        }
        .background(Color.theme.background)
    }
}

// 角色标签页
private struct RolesTab: View {
    @ObservedObject var viewModel: ProfileViewModel
    let isLoading: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if viewModel.storyRoles.isEmpty {
                    EmptyStateView(
                        image: "person.circle",
                        title: "还没有角色",
                        message: "创建你的第一个角色吧"
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(viewModel.storyRoles) { role in
                        ProfileRoleCell(role: role, viewModel: viewModel)
                    }
                }
            }
            .padding(.top, 16)
        }
        .background(Color.theme.background)
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
        HStack(alignment: .center, spacing: 12) {
            Text(board.boardInfo.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color.theme.primaryText)
            
            Spacer()
            
            Text(formatDate(timestamp: board.boardInfo.ctime))
                .font(.system(size: 13))
                .foregroundColor(Color.theme.tertiaryText)
        }
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(board.boardInfo.content)
                .font(.system(size: 15))
                .foregroundColor(Color.theme.secondaryText)
                .lineLimit(3)
                .padding(.vertical, 4)
            
            let scenes = board.boardInfo.sences.list
            if !scenes.isEmpty {
                HStack {
                    Image(systemName: "photo.stack.fill")
                        .foregroundColor(Color.theme.tertiaryText)
                        .font(.system(size: 13))
                    Text("共\(scenes.count)个场景")
                        .font(.system(size: 13))
                        .foregroundColor(Color.theme.tertiaryText)
                }
            }
            
            Divider()
                .background(Color.theme.divider)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 32) {
            // 编辑按钮
            Button(action: {
                showingEditView = true
            }) {
                Label("编辑", systemImage: "pencil")
                    .font(.system(size: 14))
                    .foregroundColor(Color.theme.tertiaryText)
            }
            
            // 发布按钮
            Button(action: {
                showingPublishAlert = true
            }) {
                Label("发布", systemImage: "arrow.up.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.theme.accent)
            }
            
            // 删除按钮
            Button(action: {
                showingDeleteAlert = true
            }) {
                Label("删除", systemImage: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(Color.theme.error)
            }
            
            Spacer()
        }
        .padding(.top, 12)
    }
    
    var body: some View {
        mainContent
            .padding(16)
            .background(Color.theme.secondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.theme.border, lineWidth: 0.5)
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
        VStack(alignment: .leading, spacing: 12) {
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
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func ToastView(message: String) -> some View {
        VStack {
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.theme.secondary.opacity(0.9))
                .cornerRadius(8)
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



