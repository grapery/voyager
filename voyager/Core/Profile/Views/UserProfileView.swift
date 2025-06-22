//
//  UserProfileView.swift
//  voyager
//
//  Created by grapestree on 2024/10/2.
//


import SwiftUI
import Kingfisher
import PhotosUI
import ActivityIndicatorView

// MARK: - Main View
struct UserProfileView: View {
    @State private var selectedTab: Int = 0
    @Namespace var animation
    var user: User
    @StateObject var viewModel: ProfileViewModel
    @StateObject private var userState = UserStateManager.shared
    @GestureState private var dragOffset: CGFloat = 0
    @State private var showingEditProfile = false
    @State private var showSettings = false
    @State private var isLoading = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showStatsDetail = false
    @State private var showingBackgroundPicker = false
    @State private var showingBackgroundUpdateToast = false
    @State private var backgroundUpdateToastMessage = ""
    @State private var isShowingStoryView = false
    @State private var selectedStoryId: Int64? = nil
    @StateObject private var unpublishedViewModel: UnpublishedStoryViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // 判断是否是当前登录用户
    private var isCurrentUser: Bool {
        userState.currentUser?.userID == user.userID
    }
    
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
        self.user = user
        self._unpublishedViewModel = StateObject(wrappedValue: UnpublishedStoryViewModel(userId: user.userID))
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    UserProfileHeaderView(
                        user: viewModel.user ?? user,
                        profile: viewModel.profile,
                        onBack: {
                            presentationMode.wrappedValue.dismiss()
                        },
                        onFollow: {
                            
                        },
                        onMessage: {
                            
                        },
                        onEditProfile: {
                            showingEditProfile = true
                        },
                        onShowSettings: {
                            showSettings = true
                        },
                        onShowStats: {
                            showStatsDetail = true
                        },
                        viewModel: self.viewModel,
                        isCurrentUser: self.isCurrentUser
                    )
                    
                    UserHomeTabsSection
                }
            }
            .ignoresSafeArea(edges: .top)
            .background(Color.theme.background)
            .sheet(isPresented: $showingEditProfile) {
                EditUserProfileView(user: user)
                    .onDisappear {
                        Task {
                            await refreshData()
                        }
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
            .fullScreenCover(isPresented: $isShowingStoryView) {
                if let storyId = selectedStoryId {
                    NavigationStack {
                        StoryView(storyId: storyId, userId: user.userID)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button(action: { isShowingStoryView = false }) {
                                        HStack{
                                            Image(systemName: "chevron.left")
                                        }
                                    }
                                }
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button(action: { isShowingStoryView = false }) {
                                        Image(systemName: "xmark")
                                    }
                                }
                            }
                    }
                }else{
                    NavigationStack {
                        Text("Voyager")
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button(action: { isShowingStoryView = false }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "chevron.left")
                                        }
                                    }
                                }
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button(action: { isShowingStoryView = false }) {
                                        Image(systemName: "xmark")
                                    }
                                }
                            }
                    }
                }
            }
        }
    }
    
    
    
    private var backgroundImageView: some View {
        ZStack {
            if let image = viewModel.backgroundImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay(backgroundGradient)
            } else {
                RandomCirclesBackground()
                    .overlay(backgroundGradient)
            }
            
            // 长按提示
            if !showingBackgroundPicker {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("长按更换背景")
                            .font(.system(size: 14))
                            .foregroundColor(Color.theme.primaryText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.theme.buttonBackground)
                            .cornerRadius(12)
                            .padding(.trailing, 16)
                            .padding(.bottom, 16)
                    }
                }
            }
        }
        .onLongPressGesture {
            showingBackgroundPicker = true
        }
        .sheet(isPresented: $showingBackgroundPicker) {
            PhotosPicker(selection: $viewModel.backgroundSelectedImage) {
                Text("选择图片")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color.theme.primaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.theme.accent)
                    .cornerRadius(12)
                    .padding()
            }
            .onChange(of: viewModel.backgroundSelectedImage) { newValue in
                if newValue != nil {
                    handleImageSelected()
                }
            }
        }
        .overlay {
            if showingBackgroundUpdateToast {
                VStack {
                    Spacer()
                    Text(backgroundUpdateToastMessage)
                        .font(.system(size: 14))
                        .foregroundColor(Color.theme.primaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.theme.buttonBackground)
                        .cornerRadius(8)
                        .padding(.bottom, 16)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingBackgroundUpdateToast)
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.theme.background.opacity(0.4),
                Color.theme.background.opacity(0.2),
                Color.theme.background.opacity(0.4)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private struct RandomCirclesBackground: View {
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange]
        
        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    ForEach(0..<15) { _ in
                        Circle()
                            .fill(colors.randomElement()!)
                            .frame(width: CGFloat.random(in: 50...200), height: CGFloat.random(in: 50...200))
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: 0...geometry.size.height)
                            )
                            .opacity(Double.random(in: 0.1...0.5))
                    }
                }
                .background(Color.theme.background)
                .blur(radius: 60)
            }
        }
    }
    
    
    
    
    private struct StatsDetailRow: View {
        let icon: String
        let iconColor: Color
        let title: String
        let value: String
        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(iconColor)
                    .frame(width: 16, height: 16)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(Color.theme.primaryText)
                Spacer()
                Text(value)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.theme.primaryText)
            }
            .frame(width: 80)
        }
    }
    
    private var UserHomeTabsSection: some View {
        VStack(spacing: 0) {
            CustomSegmentedControl(
                selectedIndex: $selectedTab,
                titles: isCurrentUser ? ["故事", "角色", "草稿"] : ["故事", "角色"]
            )
            
            TabView(selection: $selectedTab) {
                StoriesTab(
                    viewModel: viewModel,
                    isLoading: isLoading,
                    selectedStoryId: $selectedStoryId,
                    isShowingStoryView: $isShowingStoryView
                )
                .tag(0)
                .id("stories")
                .frame(maxWidth: .infinity)
                
                RolesTab(viewModel: viewModel, isLoading: isLoading)
                    .tag(1)
                    .id("roles")
                    .frame(maxWidth: .infinity)
                
                if isCurrentUser {
                    PendingTab(viewModel: unpublishedViewModel)
                        .tag(2)
                        .id("pending")
                        .frame(maxWidth: .infinity)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity)
            .frame(minHeight: UIScreen.main.bounds.height * 0.6)
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.theme.background.opacity(0.3)
                .ignoresSafeArea()
            VStack {
                Spacer()
                VStack(spacing: 12) {
                    HStack {
                        ActivityIndicatorView(isVisible: $isLoading, type: .growingArc(.cyan))
                            .frame(width: 64, height: 64)
                            .foregroundColor(.cyan)
                    }
                            .frame(height: 50)
                    Text("加载中......")
                        .foregroundColor(Color.theme.secondaryText)
                        .font(.system(size: 14))
                }
                .frame(maxWidth: .infinity)
                Spacer()
            }
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
        showingBackgroundPicker = false
        
        Task {
            do {
                let imageUrl = try await Task.detached {
                    try AliyunClient.UploadImage(image: image)
                }.value
                
                let err = await viewModel.updateUserbackgroud(userId: viewModel.user!.userID, backgroundImageUrl: imageUrl)
                
                await MainActor.run {
                    isLoading = false
                    if err != nil {
                        backgroundUpdateToastMessage = "更新背景图片失败"
                        showingBackgroundUpdateToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showingBackgroundUpdateToast = false
                        }
                    } else {
                        backgroundUpdateToastMessage = "背景图片更新成功"
                        showingBackgroundUpdateToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showingBackgroundUpdateToast = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    backgroundUpdateToastMessage = "上传图片失败: \(error.localizedDescription)"
                    showingBackgroundUpdateToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showingBackgroundUpdateToast = false
                    }
                }
            }
        }
    }
    private var userStatsDetail: some View {
        ZStack {
            Color.theme.background.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Text("创建和关注")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.theme.primaryText)
                        .padding(.top, 24)
                    VStack(alignment: .listRowSeparatorTrailing,spacing: 20) {
                        StatsDetailRow(icon: "fossil.shell", iconColor: Color.theme.accent, title: "创建了故事", value: "\(viewModel.profile.createdStoryNum)")
                        StatsDetailRow(icon: "person.text.rectangle", iconColor: Color.theme.accent, title: "创建了角色", value: "\(viewModel.profile.createdRoleNum)")
                        StatsDetailRow(icon: "list.clipboard", iconColor: Color.theme.accent, title: "创建了故事版", value: "\(viewModel.profile.createdStoryNum)")
                        StatsDetailRow(icon: "person.2.fill", iconColor: Color.theme.accent, title: "关注了故事", value: "\(viewModel.profile.watchingStoryNum)")
                        StatsDetailRow(icon: "person.text.rectangle", iconColor: Color.theme.accent, title: "关注了角色", value: "\(viewModel.profile.watchingStoryNum)")
                        StatsDetailRow(icon: "bonjour", iconColor: Color.theme.accent, title: "关注了小组", value: "\(viewModel.profile.watchingGroupNum)")
                    }
                    .padding(.vertical, 24)
                }
                Divider()
                Button(action: { showStatsDetail = false }) {
                    Text("了解")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.theme.primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.theme.accent)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                }
            }
            .frame(width: 320)
            .background(Color.theme.inputBackground)
            .cornerRadius(24)
            //.shadow(color: Color.theme.settingsBackground.opacity(0.15), radius: 16, x: 0, y: 8)
        }
    }
    // 头部区域子视图
    private struct UserProfileHeaderView: View {
        let user: User
        let profile: UserProfile
        let onBack: () -> Void
        let onFollow: () -> Void
        let onMessage: () -> Void
        let onEditProfile: () -> Void
        let onShowSettings: () -> Void
        let onShowStats: () -> Void
        @ObservedObject var viewModel: ProfileViewModel
        let isCurrentUser: Bool

        var body: some View {
            ZStack(alignment: .top) {
                // This container ensures the header has a fixed total height.
                // The parent view's background will be visible behind this ZStack.
                
                // MARK: - Content Layer (Card and Avatar)
                ZStack(alignment: .topLeading) {
                    
                    // MARK: - Info Card
                    VStack(alignment: .leading, spacing: 12) {
                        // Top row for stats, with space for the avatar
                        HStack {
                            Spacer().frame(width: 88 + 32) // Avatar width + horizontal padding
                            
                            HStack(spacing: 5) {
                                ProfileStatView(count: "\(viewModel.profile.createdStoryNum)", title: "故事")
                                Divider().frame(height: 10)
                                ProfileStatView(count: "\(viewModel.profile.watchingStoryNum)", title: "关注")
                                Divider().frame(height: 10)
                                ProfileStatView(count: "\(viewModel.profile.createdStoryNum)", title: "故事版")
                                Divider().frame(height: 10)
                                ProfileStatView(count: "\(viewModel.profile.createdRoleNum)", title: "故事角色")
                            }
                            Spacer()
                        }
                        .padding(.top, 12)

                        // User Info Section
                        VStack(alignment: .center, spacing: 8) {
                            // Name and Badges
                            HStack {
                                Text(user.name)
                                    .font(.system(size: 20, weight: .bold))
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Action Buttons
                        if isCurrentUser {
                            Button(action: onEditProfile) {
                                Text("编辑资料")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(Color(UIColor.systemGray5))
                                    .clipShape(Capsule())
                            }
                            .padding([.horizontal, .top], 16)
                        } else {
                            HStack(spacing: 12) {
                                Button(action: onFollow) {
                                    Text("+ 关注")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .background(Color.blue)
                                        .clipShape(Capsule())
                                }
                                Button(action: onMessage) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "paperplane")
                                        Text("发私信")
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(height: 44)
                                    .padding(.horizontal, 20)
                                    .background(Color(UIColor.systemGray5))
                                    .clipShape(Capsule())
                                }
                            }
                            .padding([.horizontal, .top], 16)
                        }
                    }
                    .padding(.vertical)
                    .background(Color.theme.background)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    .padding(.horizontal, 8)
                    
                    // MARK: - Avatar (Floating)
                    RectProfileImageView(avatarUrl: user.avatar, size: .InContent)
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 3)
                        .offset(x: 24, y: -44) // Key change for floating effect
                }
                .padding(.top, 180) // Push the card down to make space for the background
            }
            .frame(height: 350) // Total height of the header
            .overlay(alignment: .top) {
                HStack {
                    // Back button for non-current users
                    if !isCurrentUser {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.title3.weight(.light))
                                .foregroundColor(.primary)
                                //.padding(10)
                                .background(Color.theme.buttonBackground.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    
                    Spacer()
                    
                    // Settings button for current user
                    if isCurrentUser {
                        Button(action: onShowSettings) {
                            Image(systemName: "gearshape.fill")
                                .font(.title3.weight(.light))
                                .foregroundColor(.primary)
                                //.padding(10)
                                .background(Color.theme.buttonBackground.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 50) // Adjust for safe area
            }
        }
    }


    private struct ProfileStatView: View {
        let count: String
        let title: String
        
        var body: some View {
            VStack(spacing: 4) {
                Text(count)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.theme.primaryText)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(Color.theme.secondaryText)
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
                        Button(action: {
                            withAnimation {
                                selectedIndex = index
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text(titles[index])
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(selectedIndex == index ? Color.theme.primaryText : Color.theme.tertiaryText)
                                
                                // 下划线
                                Rectangle()
                                    .fill(selectedIndex == index ? Color.theme.accent : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                Divider()
                    .background(Color.theme.divider)
            }
            .background(Color.theme.background)
        }
    }
}

struct StoryboardCell: View {
    let board: StoryBoardActive
    var sceneMediaContents: [SceneMediaContent]
    @Binding var selectedStoryId: Int64?
    @Binding var isShowingStoryView: Bool
    init(board: StoryBoardActive, selectedStoryId: Binding<Int64?>, isShowingStoryView: Binding<Bool>) {
        self.board = board
        self._selectedStoryId = selectedStoryId
        self._isShowingStoryView = isShowingStoryView
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
                                    LazyVStack(alignment: .leading, spacing: 2) {
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
                HStack(spacing: 8) {
                    StatLabel(
                        icon: "heart",
                        count: Int(board.boardActive.totalLikeCount),
                        iconColor: Color.theme.accent,
                        countColor: Color.theme.tertiaryText
                    )
                    
                    StatLabel(
                        icon: "bubble.left",
                        count: Int(board.boardActive.totalCommentCount),
                        iconColor: Color.theme.accent,
                        countColor: Color.theme.tertiaryText
                    )
                    
                    StatLabel(
                        icon: "signpost.right.and.left",
                        count: Int(board.boardActive.totalForkCount),
                        iconColor: Color.theme.accent,
                        countColor: Color.theme.tertiaryText
                    )
                    
                    Spacer()
                    HStack{
                        KFImage(URL(string: convertImagetoSenceImage(url: board.boardActive.summary.storyAvatar, scene: .small)))
                            .cacheMemoryOnly()
                            .fade(duration: 0.25)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 16, height: 16)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.theme.border, lineWidth: 0.5)
                            )
                        Text("故事：")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.theme.primaryText)
                        Button(action: {
                            selectedStoryId = board.boardActive.summary.storyID
                            Task { @MainActor in
                                isShowingStoryView = true
                            }
                        }) {
                            Text(board.boardActive.summary.storyTitle)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.theme.primaryText)
                        }
                    }
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
                        icon: "heart",
                        count: Int(board.boardActive.totalLikeCount),
                        iconColor: Color.theme.accent,
                        countColor: Color.theme.tertiaryText
                    )
                    
                    StatLabel(
                        icon: "bubble.left",
                        count: Int(board.boardActive.totalCommentCount),
                        iconColor: Color.theme.accent,
                        countColor: Color.theme.tertiaryText
                    )
                    
                    StatLabel(
                        icon: "signpost.right.and.left",
                        count: Int(board.boardActive.totalForkCount),
                        iconColor: Color.theme.accent,
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
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                // 角色头像
                KFImage(URL(string: convertImagetoSenceImage(url: role.role.characterAvatar, scene: .small)))
                    .cacheMemoryOnly()
                    .fade(duration: 0.25)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.theme.border, lineWidth: 0.5)
                    )
                
                // 角色信息
                VStack(alignment: .leading, spacing: 8) {
                    // 角色名称
                    Text(role.role.characterName)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Color.theme.primaryText)
                    
                    // 故事信息
                    HStack(spacing: 4) {
                        Text("参与故事：")
                            .font(.system(size: 14))
                            .foregroundColor(Color.theme.tertiaryText)
                        Text(role.role.characterName)
                            .font(.system(size: 14))
                            .foregroundColor(Color.theme.accent)
                            .lineLimit(1)
                    }
                    
                    // 角色描述
                    Text(role.role.characterDescription)
                        .font(.system(size: 14))
                        .foregroundColor(Color.theme.secondaryText)
                        .lineLimit(2)
                    
                    // 创建时间
                    Text("创建于：\(formatDate(timestamp: role.role.ctime))")
                        .font(.system(size: 12))
                        .foregroundColor(Color.theme.tertiaryText)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            
            Divider()
                .background(Color.theme.divider)
                .padding(.horizontal,16)
        }
        .background(Color.theme.background)
        .contentShape(Rectangle())
        .onTapGesture {
            showRoleDetail = true
        }
        .fullScreenCover(isPresented: $showRoleDetail) {
            NavigationStack {
                StoryRoleDetailView(
                    roleId: role.role.roleID,
                    userId: viewModel.user?.userID ?? 0,
                    role: role
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            // 关闭当前 NavigationStack
                            showRoleDetail = false
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(Color.theme.primaryText)
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showRoleDetail)
            }
        }
    }
    
    private func formatDate(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
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
                .font(.system(size: 14))
                .foregroundColor(countColor)
        }
    }
}



struct StatItem: View {
    let count: Int
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Text("\(count)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct StatItemShortCut: View {
    let count: Int
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color.theme.buttonText)
            
            Text("\(count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.theme.buttonText)
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
    @Binding var selectedStoryId: Int64?
    @Binding var isShowingStoryView: Bool

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if isLoading && viewModel.storyboards.isEmpty {
                    VStack {
                        Spacer()
                        VStack(spacing: 12) {
                            HStack {
                                ActivityIndicatorView(isVisible: .constant(true), type: .growingArc(.cyan))
                                    .frame(width: 64, height: 64)
                                    .foregroundColor(.cyan)
                            }
                            .frame(height: 50)
                            Text("加载中......")
                                .foregroundColor(Color.theme.secondaryText)
                                .font(.system(size: 14))
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    }
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
                            StoryboardCell(
                                board: board,
                                selectedStoryId: $selectedStoryId,
                                isShowingStoryView: $isShowingStoryView
                            )
                            .frame(maxWidth: .infinity)
                            if board.id != viewModel.storyboards.last?.id {
                                Divider()
                                    .background(Color.theme.divider)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .background(Color.theme.background)
    }
}

// 角色标签页
private struct RolesTab: View {
    @ObservedObject var viewModel: ProfileViewModel
    let isLoading: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if viewModel.storyRoles.isEmpty {
                    EmptyStateView(
                        image: "person.circle",
                        title: "还没有角色",
                        message: "创建你的第一个角色吧"
                    )
                    .padding(.top, 8)
                } else {
                    ForEach(viewModel.storyRoles) { role in
                        ProfileRoleCell(role: role, viewModel: viewModel)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.top, 16)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
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
                .foregroundColor(Color.theme.secondaryText)
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(Color.theme.secondaryText)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Color.theme.secondaryText)
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
    @ObservedObject var viewModel: UnpublishedStoryViewModel
    @State private var isRefreshing = false
    @State private var lastLoadedBoardId: Int64? = nil
    
    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.unpublishedStoryboards.isEmpty {
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        HStack {
                            ActivityIndicatorView(isVisible: .constant(true), type: .growingArc(.cyan))
                                .frame(width: 64, height: 64)
                                .foregroundColor(.cyan)
                        }
                        .frame(height: 50)
                        Text("加载中......")
                            .foregroundColor(Color.theme.secondaryText)
                            .font(.system(size: 14))
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
            } else if viewModel.unpublishedStoryboards.isEmpty {
                emptyStateView
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        UnPublishedstoryBoardsListView
                            .id("storyboardList")
                        Button {
                                        
                        } label: {
                            Text("加载更多")
                                .font(.footnote)
                                .foregroundColor(.black)
                                .fontWeight(.bold)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    .onChange(of: viewModel.unpublishedStoryboards) { newBoards in
                        if let lastId = lastLoadedBoardId,
                           let _ = newBoards.firstIndex(where: { $0.id == lastId }) {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if self.$viewModel.unpublishedStoryboards.wrappedValue.isEmpty {
                Task {
                    await viewModel.fetchUnpublishedStoryboards()
                }
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
            Spacer()
        }
        .frame(minHeight: 300)
    }
    
    private var UnPublishedstoryBoardsListView: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.unpublishedStoryboards) { board in
                UnpublishedBoardCellWrapper(
                    board: board,
                    userId: viewModel.userId,
                    viewModel: viewModel
                )
                Divider()
                    .padding(.horizontal,16)
            }
            if viewModel.isLoading && viewModel.unpublishedStoryboards.count > 0 {
                loadingOverlay(isLoading: true)
            }
            if !viewModel.hasMorePages && !viewModel.unpublishedStoryboards.isEmpty {
                HStack {
                    Spacer()
                    Text("没有更多草稿了")
                        .font(.system(size: 13))
                        .foregroundColor(Color.theme.secondaryText)
                        .padding(.vertical, 8)
                    Spacer()
                }
            }
        }
    }
}

private struct UnpublishedBoardCellWrapper: View {
    let board: StoryBoardActive
    let userId: Int64
    @ObservedObject var viewModel: UnpublishedStoryViewModel

    var body: some View {
        VStack(spacing: 0) {
            UnpublishedStoryBoardCellView(
                board: board,
                userId: userId,
                viewModel: viewModel
            )
            .id(board.boardActive.storyboard.storyBoardID)
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
    @State private var isAnimating = false
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
            // 顶部：标题与草稿标记同行对齐
            HStack(alignment: .firstTextBaseline) {
                Text(board.boardActive.storyboard.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.theme.primaryText)
                    .lineLimit(2)
                Spacer()
                StoryboardStatusView(status: board.boardStatus())
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)

            // 标题和内容区域
            VStack(alignment: .leading, spacing: 8) {
                // 故事信息
                HStack(spacing: 4) {
                    Text("故事：")
                        .font(.system(size: 14))
                        .foregroundColor(Color.theme.tertiaryText)
                    Text(board.boardActive.summary.storyTitle)
                        .font(.system(size: 14))
                        .foregroundColor(Color.theme.accent)
                }
                // 内容
                Text(board.boardActive.storyboard.content)
                    .font(.system(size: 15))
                    .foregroundColor(Color.theme.secondaryText)
                    .lineLimit(3)
                if !self.sceneMediaContents.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(self.sceneMediaContents, id: \ .id) { sceneContent in
                                LazyVStack(alignment: .leading, spacing: 2) {
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
                                        .lineLimit(3)
                                        .frame(width: 140)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)

            // 底部：按钮与时间下沿对齐
            HStack(alignment: .lastTextBaseline) {
                HStack(spacing: 4) {
                    Button(action: { showingEditView = true }) {
                        InteractionStatItem(
                            icon: "paintbrush.pointed",
                            text: "编辑",
                            color: Color.theme.inputText
                        )
                        .cornerRadius(2)
                    }
                    Button(action: { showingPublishAlert = true }) {
                        InteractionStatItem(
                            icon: "mountain.2",
                            text: "发布",
                            color: Color.theme.inputText
                        )
                        .cornerRadius(2)
                    }
                    Button(action: { showingDeleteAlert = true }) {
                        InteractionStatItem(
                            icon: "trash",
                            text: "删除",
                            color: Color.theme.inputText
                        )
                        .cornerRadius(2)
                    }
                }
                .font(.system(size: 15)) // 保证和时间字号一致
                Spacer()
                Text(formatDate(board.boardActive.storyboard.ctime))
                    .font(.system(size: 13))
                    .foregroundColor(Color.theme.tertiaryText)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color.theme.secondaryBackground)
        .overlay(errorToastOverlay)
        .fullScreenCover(isPresented: $showingEditView) {
            NavigationStack {
                EditStoryBoardView(
                    userId: userId,
                    storyId: board.boardActive.storyboard.storyID,
                    boardId: board.boardActive.storyboard.storyBoardID,
                    viewModel: StoryViewModel(storyId: board.boardActive.storyboard.storyID,  userId: userId),
                    isPresented: $showingEditView,
                )
                .transition(.move(edge: .bottom))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showingEditView)
                .navigationTitle(board.boardActive.summary.storyTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            showingEditView = false
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
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
    
    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Interaction Stat Item
private struct InteractionStatItem: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }
}

private struct UnpublishedToastView: View {
    let message: String
    
    var body: some View {
        VStack {
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Color.theme.primaryText)
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

// 用户状态优先级逻辑
private var userStatus: String {
    // 这里可根据业务逻辑和用户选择返回一个状态
    // 示例：优先级顺序
    let all = ["忙碌", "勿扰", "有屏障", "AI存在中"]
    // 假设有 user.statusList: [String]，这里只取第一个
    // return user.statusList.first ?? ""
    return all.first ?? ""
}



private struct StoryboardStatusView: View {
    let status: StoryboardStatus
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .bold))
            Text(statusText)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .cornerRadius(8)
    }
    private var iconName: String {
        switch status {
        case .draft: return "doc.plaintext"
        case .scene: return "rectangle.3.offgrid"
        case .image: return "photo.on.rectangle"
        case .finished: return "checkmark.seal"
        case .published: return "paperplane"
        }
    }
    private var statusText: String {
        switch status {
        case .draft: return "草稿"
        case .scene: return "场景"
        case .image: return "图片"
        case .finished: return "完成"
        case .published: return "已发布"
        }
    }
    private var statusColor: Color {
        switch status {
        case .draft: return .gray
        case .scene: return .orange
        case .image: return .blue
        case .finished: return .green
        case .published: return .green
        }
    }
}



