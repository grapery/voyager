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
                titles: isCurrentUser ? ["故事", "角色"] : ["故事", "角色"]
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
                
                // if isCurrentUser {
                //     PendingTab(viewModel: unpublishedViewModel)
                //         .tag(2)
                //         .id("pending")
                //         .frame(maxWidth: .infinity)
                // }
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
                        VStack(alignment: .leading, spacing: 8) {
                            // Name and Badges
                            HStack {
                                Text(user.name)
                                    .font(.system(size: 20, weight: .bold))
                            }
                        }
                        .padding(.leading, 24) // 与头像offset一致，左对齐
                        
                        // Action Buttons
                        if isCurrentUser {
                            Button(action: onEditProfile) {
                                Text("编辑资料")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(Color(UIColor.systemGray5))
                                    .clipShape(Capsule())
                            }
                            .padding([.horizontal, .top], 12)
                        } else {
                            HStack(spacing: 12) {
                                Button(action: onFollow) {
                                    Text("+ 关注")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, minHeight: 40)
                                        .background(Color.blue)
                                        .clipShape(Capsule())
                                }
                                Button(action: onMessage) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "paperplane")
                                        Text("发私信")
                                    }
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(height: 40)
                                    .padding(.horizontal, 20)
                                    .background(Color(UIColor.systemGray5))
                                    .clipShape(Capsule())
                                }
                            }
                            .padding([.horizontal, .top], 12)
                        }
                    }
                    .padding(.vertical)
                    .background(Color.theme.background)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    //.padding(.horizontal, 8)
                    
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

