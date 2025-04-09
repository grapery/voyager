//
//  UserProfileView.swift
//  voyager
//
//  Created by grapestree on 2024/10/2.
//


import SwiftUI
import Kingfisher
import PhotosUI

// MARK: - Main View
struct UserProfileView: View {
    @State private var selectedTab: Int = 0
    @Namespace var animation
    var user: User
    @StateObject var viewModel: ProfileViewModel
    @GestureState private var dragOffset: CGFloat = 0
    @State private var showingImagePicker = false
    @State private var showingEditProfile = false
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
                headerView
                userInfoSection
                tabsSection
            }
        }
        .background(Color.theme.background)
        .sheet(isPresented: $showingEditProfile) {
            EditUserProfileView(user: user)
                .onDisappear {
                    Task {
                        await refreshData()
                    }
                }
        }
        .sheet(isPresented: $showingImagePicker) {
            SingleImagePicker(image: $viewModel.backgroundImage)
        }
        .onChange(of: viewModel.backgroundImage) { newImage in
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
        .onChange(of: viewModel.profile) { _ in
            // profile 更新时自动刷新数据
            Task {
                await refreshData()
            }
        }
        .alert("错误", isPresented: $showingErrorAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if isLoading {
                loadingOverlay
            }
        }
    }
    
    // MARK: - View Components
    private var headerView: some View {
        HStack {
            Spacer()
            Button(action: { showingEditProfile = true }) {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(Color.theme.tertiaryText)
            }
            .padding(.horizontal, 16)
            
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .foregroundColor(Color.theme.tertiaryText)
            }
            .padding(.trailing, 16)
        }
        .padding(.vertical, 8)
        .background(Color.theme.background)
    }
    
    private var userInfoSection: some View {
        ZStack {
            backgroundImageView
            userProfileInfo
        }
        .onLongPressGesture {
            showingImagePicker = true
        }
    }
    
    private var backgroundImageView: some View {
        PhotosPicker(selection: $viewModel.backgroundSelectedImage) {
            if let image = viewModel.backgroundImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 260)
                    .clipped()
                    .overlay(backgroundGradient)
            } else {
                Rectangle()
                    .fill(Color.theme.tertiaryBackground)
                    .frame(height: 260)
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black.opacity(0.3),
                Color.black.opacity(0.1)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var userProfileInfo: some View {
        VStack(spacing: 20) {
            RectProfileImageView(
                avatarUrl: viewModel.user?.avatar ?? user.avatar,
                size: .InProfile2
            )
            .frame(width: 88, height: 88)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            Text(viewModel.user?.name ?? user.name)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            userStats
        }
        .padding(.vertical, 24)
    }
    
    private var userStats: some View {
        HStack(spacing: 0) {
            StatItem(count: Int(viewModel.profile.watchingStoryNum), title: "创建", icon: "bell.fill")
                .frame(maxWidth: .infinity)
            StatItem(count: Int(viewModel.profile.createdStoryNum), title: "关注", icon: "person.2.fill")
                .frame(maxWidth: .infinity)
            StatItem(count: Int(viewModel.profile.contributStoryNum), title: "参与", icon: "heart.fill")
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 8)
    }
    
    private var tabsSection: some View {
        VStack(spacing: 0) {
            CustomSegmentedControl(
                selectedIndex: $selectedTab,
                titles: ["故事", "角色", "草稿"]
            )
            
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
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
        }
    }
    
    // MARK: - Methods
    private func refreshData() async {
        isLoading = true
        defer { isLoading = false }
        
        let newProfile = await viewModel.fetchUserProfile()
        await MainActor.run {
            viewModel.profile = newProfile
        }
        await loadFilteredContent(for: selectedTab)
    }
    
    private func loadUserData() async {
        isLoading = true
        defer { isLoading = false }
        
        let newProfile = await viewModel.fetchUserProfile()
        await MainActor.run {
            viewModel.profile = newProfile
        }
        await loadFilteredContent(for: selectedTab)
    }
    
    private func loadFilteredContent(for filter: Int, forceRefresh: Bool = false) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            switch filter {
            case 0:
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
                
            case 1:
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
                
            default:
                break
            }
        } catch {
            print("Error loading filtered content: \(error)")
        }
    }
    
    private func handleImageSelected() {
        guard let image = viewModel.backgroundImage else { return }
        
        isLoading = true
        
        Task {
            do {
                let imageUrl = try await Task.detached {
                    try AliyunClient.UploadImage(image: image)
                }.value
                
                let err = await viewModel.updateUserbackgroud(userId: viewModel.user!.userID, backgroundImageUrl: imageUrl)
                
                await MainActor.run {
                    isLoading = false
                    if err != nil {
                        errorMessage = "更新背景图片失败"
                        showingErrorAlert = true
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
    let board: StoryBoardActive
    var sceneMediaContents: [SceneMediaContent]
    init(board: StoryBoardActive) {
        self.board = board
        var tempSceneContents: [SceneMediaContent] = []
        let scenes = board.boardActive.storyboard.sences.list
        for scene in scenes {
            let genResult = scene.genResult
            if let data = genResult.data(using: .utf8),
               let urls = try? JSONDecoder().decode([String].self, from: data) {
                
                var mediaItems: [MediaItem] = []
                for urlString in urls {
                    if let url = URL(string: urlString) {
                        let item = MediaItem(
                            id: UUID().uuidString,
                            type: urlString.hasSuffix(".mp4") ? .video : .image,
                            url: url,
                            thumbnail: urlString.hasSuffix(".mp4") ? URL(string: urlString) : nil
                        )
                        mediaItems.append(item)
                    }
                }
                
                let sceneContent = SceneMediaContent(
                    id: UUID().uuidString,
                    sceneTitle: scene.content,
                    mediaItems: mediaItems
                )
                tempSceneContents.append(sceneContent)
            }
        }
        self.sceneMediaContents = tempSceneContents
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {    
            // 主要内容
            VStack(alignment: .leading, spacing: 12) {
                // 标题行
                HStack {
                    Text(board.boardActive.storyboard.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.theme.primaryText)
                    
                    Spacer()
                    
                    Text(formatDate(board.boardActive.storyboard.ctime))
                        .font(.system(size: 13))
                        .foregroundColor(Color.theme.tertiaryText)
                }
                
                // 内容
                Text(board.boardActive.storyboard.content)
                    .font(.system(size: 15))
                    .foregroundColor(Color.theme.secondaryText)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                if !self.sceneMediaContents.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(self.sceneMediaContents, id: \.id) { sceneContent in
                                    VStack(alignment: .leading, spacing: 4) {
                                        // 场景图片（取第一张）
                                        if let firstMedia = sceneContent.mediaItems.first {
                                            KFImage(firstMedia.url)
                                                .placeholder {
                                                    Rectangle()
                                                        .fill(Color.theme.tertiaryBackground)
                                                        .overlay(
                                                            ProgressView()
                                                                .progressViewStyle(CircularProgressViewStyle())
                                                        )
                                                }
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 140, height: 200)
                                                .clipped()
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.theme.border, lineWidth: 0.5)
                                                )
                                        }
                                        
                                        // 场景标题
                                        Text(sceneContent.sceneTitle)
                                            .font(.system(size: 13))
                                            .foregroundColor(Color.theme.secondaryText)
                                            .lineLimit(2)
                                            .frame(width: 140)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                    }
                }
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
    }
    
    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}


struct StoryboardActiveCell: View {
    let board: StoryBoardActive
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 主要内容
            VStack(alignment: .leading, spacing: 12) {
                // 标题行
                HStack {
                    Text(board.boardActive.storyboard.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.theme.primaryText)
                    
                    Spacer()
                    
                    Text(formatDate(board.boardActive.storyboard.ctime))
                        .font(.system(size: 13))
                        .foregroundColor(Color.theme.tertiaryText)
                }
                
                // 内容
                Text(board.boardActive.storyboard.content)
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
                    roleId: role.role.roleID,
                    userId: viewModel.user?.userID ?? 0,
                    role: role
                )
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
            LazyVStack(spacing: 0) {
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
                        VStack(spacing: 0) {
                            StoryboardCell(board: board)
                            
                            if board.id != viewModel.storyboards.last?.id {
                                Divider()
                                    .background(Color.theme.divider)
                            }
                        }
                    }
                }
            }
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
    let boards: [StoryBoardActive]
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(boards, id: \.id) { board in
                StoryboardActiveCell(board: board)
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
        .background(Color.theme.background)
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
            Text("草稿箱是空的")
                .font(.system(size: 16))
                .foregroundColor(Color.theme.secondaryText)
            
            Button(action: {
                // TODO: 实现创作功能
            }) {
                Text("去创作")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 120)
                    .padding(.vertical, 12)
                    .background(Color.theme.accent)
                    .cornerRadius(22)
            }
            .padding(.top, 16)
            Spacer()
        }
        .frame(minHeight: 300)
    }
    
    private var storyBoardsListView: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.unpublishedStoryboards) { board in
                VStack(spacing: 0) {
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
                    
                    if board.id != viewModel.unpublishedStoryboards.last?.id {
                        Divider()
                            .background(Color.theme.divider)
                    }
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            }
        }
    }
}

struct UnpublishedStoryBoardCellView: View {
    var board: StoryBoardActive
    var userId: Int64
    @ObservedObject var viewModel: UnpublishedStoryViewModel
    @State private var showingPublishAlert = false
    @State private var showingDeleteAlert = false
    @State private var showingEditView = false
    @State private var errorMessage: String = ""
    @State private var showingErrorToast = false
    @State private var showingErrorAlert = false
    var sceneMediaContents: [SceneMediaContent]
    
    init(board: StoryBoardActive, userId: Int64, viewModel: UnpublishedStoryViewModel) {
        self.board = board
        self.userId = userId
        self.viewModel = viewModel
        var tempSceneContents: [SceneMediaContent] = []
        let scenes = board.boardActive.storyboard.sences.list
        for scene in scenes {
            let genResult = scene.genResult
            if let data = genResult.data(using: .utf8),
               let urls = try? JSONDecoder().decode([String].self, from: data) {
                
                var mediaItems: [MediaItem] = []
                for urlString in urls {
                    if let url = URL(string: urlString) {
                        let item = MediaItem(
                            id: UUID().uuidString,
                            type: urlString.hasSuffix(".mp4") ? .video : .image,
                            url: url,
                            thumbnail: urlString.hasSuffix(".mp4") ? URL(string: urlString) : nil
                        )
                        mediaItems.append(item)
                    }
                }
                
                let sceneContent = SceneMediaContent(
                    id: UUID().uuidString,
                    sceneTitle: scene.content,
                    mediaItems: mediaItems
                )
                tempSceneContents.append(sceneContent)
            }
        }
        self.sceneMediaContents = tempSceneContents
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题和内容区域
            VStack(alignment: .leading, spacing: 8) {
                // 标题
                Text(board.boardActive.storyboard.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.theme.primaryText)
                    .lineLimit(2)
                
                // 内容
                Text(board.boardActive.storyboard.content)
                    .font(.system(size: 15))
                    .foregroundColor(Color.theme.secondaryText)
                    .lineLimit(3)
                
                if !self.sceneMediaContents.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(self.sceneMediaContents, id: \.id) { sceneContent in
                                VStack(alignment: .leading, spacing: 4) {
                                    // 场景图片（取第一张）
                                    if let firstMedia = sceneContent.mediaItems.first {
                                        KFImage(firstMedia.url)
                                            .placeholder {
                                                Rectangle()
                                                    .fill(Color.theme.tertiaryBackground)
                                                    .overlay(
                                                        ProgressView()
                                                            .progressViewStyle(CircularProgressViewStyle())
                                                    )
                                            }
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 140, height: 200)
                                            .clipped()
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.theme.border, lineWidth: 0.5)
                                            )
                                    }
                                    
                                    // 场景标题
                                    Text(sceneContent.sceneTitle)
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.theme.secondaryText)
                                        .lineLimit(2)
                                        .frame(width: 140)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            
            // 交互栏
            HStack(spacing: 24) {
                // 编辑
                Button(action: {
                    showingEditView = true
                }) {
                    InteractionStatItem(
                        icon: "paintbrush.pointed",
                        text: "编辑",
                        color: Color.theme.tertiaryText
                    )
                }
                
                // 发布
                Button(action: {
                    showingPublishAlert = true
                }) {
                    InteractionStatItem(
                        icon: "mountain.2",
                        text: "发布",
                        color: Color.theme.tertiaryText
                    )
                }
                
                // 删除
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    InteractionStatItem(
                        icon: "trash",
                        text: "删除",
                        color: Color.theme.tertiaryText
                    )
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.theme.secondaryBackground)
        .overlay(errorToastOverlay)
        .fullScreenCover(isPresented: $showingEditView) {
            NavigationStack {
                EditStoryBoardView(
                    storyId: board.boardActive.storyboard.storyID,
                    boardId: board.boardActive.storyboard.storyBoardID,
                    userId: userId,
                    viewModel: viewModel
                )
            }
        }
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
    }
    
    private var errorToastOverlay: some View {
        Group {
            if showingErrorToast {
                UnpublishedToastView(message: errorMessage)
                    .animation(.easeInOut)
                    .transition(.move(edge: .top))
            }
        }
    }
}

// MARK: - Interaction Stat Item
private struct InteractionStatItem: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15))
            Text(text)
                .font(.system(size: 14))
        }
        .foregroundColor(color)
    }
}

private struct UnpublishedToastView: View {
    let message: String
    
    var body: some View {
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



