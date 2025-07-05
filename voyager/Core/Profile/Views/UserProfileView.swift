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
                        onShowBackgroundPicker: {
                            showingBackgroundPicker = true
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
            
            // 右上角更换背景按钮
            VStack {
                HStack {
                    Spacer()
                    Button(action: { showingBackgroundPicker = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "photo")
                                .font(.system(size: 14, weight: .medium))
                            Text("更换背景")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(Color.theme.primaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.theme.buttonBackground.opacity(0.85))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.theme.secondaryText.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(radius: 2)
                    }
                    .padding(.top, 18)
                    .padding(.trailing, 18)
                }
                Spacer()
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
        let onShowBackgroundPicker: () -> Void
        @ObservedObject var viewModel: ProfileViewModel
        let isCurrentUser: Bool

        // 头像尺寸常量
        private let avatarSize: CGFloat = 88
        // 统计区域宽度常量
        private let statsWidth: CGFloat = 260
        // 统计区域高度与头像一致
        private let statsHeight: CGFloat = 88
        // 默认头像URL
        private let defaultAvator = "https://grapery-dev.oss-cn-shanghai.aliyuncs.com/default.png"

        @State private var showStatsDetail: Bool = false // 控制统计详情弹窗

        var body: some View {
            ZStack(alignment: .top) {
                // 背景图片展示
                backgroundImageView
                
                // 参考设计图重构布局
                VStack(spacing: 20) {
                    // 主内容区：左头像，右用户名和描述
                    HStack(alignment: .center, spacing: 20) {
                        // 头像
                        RectProfileImageView(avatarUrl: user.avatar, size: .InContent)
                            .frame(width: avatarSize, height: avatarSize)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                            .shadow(radius: 3)
                        // 用户名和描述
                        VStack(alignment: .leading, spacing: 8) {
                            Text(user.name)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.theme.primaryText)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            let descText: String = {
                                if let desc = viewModel.user?.desc, !desc.isEmpty {
                                    return desc
                                } else {
                                    return "这个用户是NPC"
                                }
                            }()
                            Text(descText)
                                .font(.system(size: 13))
                                .foregroundColor(Color.theme.secondaryText)
                                .lineLimit(2)
                                .truncationMode(.tail)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // 统计区+按钮区同一行，防止超出边界
                    HStack(alignment: .center, spacing: 16) {
                        // 统计区，优先占空间，添加点击手势弹出详情
                        UserStatsView(
                            createdStoryNum: Int(viewModel.profile.createdStoryNum),
                            watchingStoryNum: Int(viewModel.profile.watchingStoryNum),
                            createdRoleNum: Int(viewModel.profile.createdRoleNum),
                            height: 48
                        )
                        .frame(height: 48)
                        .layoutPriority(1)
                        .onTapGesture {
                            showStatsDetail = true
                        }
                        Spacer(minLength: 8)
                        // 按钮区，宽度自适应且不会撑破父视图
                        if isCurrentUser {
                            Button(action: onEditProfile) {
                                Text("编辑资料")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(minWidth: 90, maxWidth: 140, minHeight: 44)
                                    .background(Color(UIColor.systemGray5))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .layoutPriority(0)
                        } else {
                            HStack(spacing: 8) {
                                Button(action: onFollow) {
                                    Text("+ 关注")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(minWidth: 70, maxWidth: 100, minHeight: 44)
                                        .background(Color.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                Button(action: onMessage) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "paperplane")
                                        Text("发私信")
                                    }
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(minWidth: 70, maxWidth: 100, minHeight: 44)
                                    .background(Color(UIColor.systemGray5))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                            .layoutPriority(0)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 28)
                .padding(.top, 70)
                // 统计详情弹窗内容，必须放在HeaderView struct内部，避免作用域问题
                .sheet(isPresented: $showStatsDetail) {
                    self.userStatsDetail
                }

                // 顶部按钮
                HStack {
                    if !isCurrentUser {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.title3.weight(.light))
                                .foregroundColor(.primary)
                                .clipShape(Circle())
                        }
                    }
                    Spacer()
                    if isCurrentUser {
                        Button(action: onShowBackgroundPicker) {
                            Image(systemName: "camera.metering.center.weighted.average")
                                .font(.title3.weight(.light))
                                .foregroundColor(.primary)
                                .clipShape(Rectangle())
                        }
                        Button(action: onShowSettings) {
                            Image(systemName: "gearshape.fill")
                                .font(.title3.weight(.light))
                                .foregroundColor(.primary)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 50)
            }
            .frame(height: 270)
        }
        
        // 背景图片展示视图
        private var backgroundImageView: some View {
            ZStack {
//                // 使用用户背景图片或默认图片
//                if let backgroundImageUrl = viewModel.user?.backgroundImage, !backgroundImageUrl.isEmpty {
//                    KFImage(URL(string: backgroundImageUrl))
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                        .frame(height: 270)
//                        .clipped()
//                        .overlay(backgroundGradient)
//                } else {
                    // 使用默认头像作为背景
                    KFImage(URL(string: defaultAvator))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 270)
                        .clipped()
                        .opacity(0.4) // 提升透明度，降低不透明度到60%
                        .overlay(backgroundGradient)
//                }
            }
        }
        
        // 背景渐变遮罩
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
        
        // 统计详情弹窗内容，现代风格，参考设计图
        private var userStatsDetail: some View {
            VStack(spacing: 0) {
                // 卡片内容（含统计项和按钮）
                VStack(spacing: 18) {
                    // 标题
                    Text("创建和关注")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.theme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 24)
                    // 统计项
                    VStack(spacing: 12) {
                        statsRow(icon: "globe.asia.australia", color: Color.theme.accent, text: "创建了故事", value: "\(viewModel.profile.createdStoryNum)")
                        statsRow(icon: "person.text.rectangle", color: Color.theme.accent, text: "创建了角色", value: "\(viewModel.profile.createdRoleNum)")
                        statsRow(icon: "list.clipboard", color: Color.theme.accent, text: "创建了故事版", value: "\(viewModel.profile.createdStoryNum)")
                        Divider().padding(.vertical, 2)
                        statsRow(icon: "person.2.fill", color: Color.theme.accent, text: "关注了故事", value: "\(viewModel.profile.watchingStoryNum)")
                        statsRow(icon: "person.text.rectangle", color: Color.theme.accent, text: "关注了角色", value: "\(viewModel.profile.watchingStoryNum)")
                        statsRow(icon: "atom", color: Color.theme.accent, text: "关注了小组", value: "\(viewModel.profile.watchingGroupNum)")
                    }
                    .padding(.horizontal, 16)
                    // 按钮放在卡片内部
                    Button(action: { showStatsDetail = false }) {
                        Text("了解")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.theme.accent)
                            .cornerRadius(16)
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 16)
                }
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
            .background(Color.theme.inputBackground)
            .ignoresSafeArea()
        }
        // 单行统计项视图，带虚线圆角包裹
        private func statsRow(icon: String, color: Color, text: String, value: String) -> some View {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 22)
                Text(text)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color.theme.primaryText)
                    .frame(minWidth: 70, alignment: .leading)
                Spacer()
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.theme.primaryText)
                    .frame(width: 28, alignment: .trailing)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundColor(Color.theme.accent.opacity(0.5))
            )
        }
    }

    /// 用户统计区域，带虚线圆角边框
    private struct UserStatsView: View {
        let createdStoryNum: Int
        let watchingStoryNum: Int
        let createdRoleNum: Int
        var height: CGFloat = 48 // 默认高度
        var body: some View {
            HStack(spacing: 0) {
                ProfileStatView(count: "\(createdStoryNum)", title: "故事")
                Divider().frame(height: height * 0.5)
                ProfileStatView(count: "\(watchingStoryNum)", title: "关注")
                Divider().frame(height: height * 0.5)
                ProfileStatView(count: "\(createdStoryNum)", title: "故事版")
                Divider().frame(height: height * 0.5)
                ProfileStatView(count: "\(createdRoleNum)", title: "故事角色")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                    .foregroundColor(Color.theme.secondaryText)
            )
        }
    }

    // 统计单项，字体减小变细
    private struct ProfileStatView: View {
        let count: String
        let title: String
        var body: some View {
            VStack(spacing: 2) {
                Text(count)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color.theme.primaryText)
                Text(title)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color.theme.secondaryText)
            }
            .frame(minWidth: 44)
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

