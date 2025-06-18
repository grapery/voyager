//
//  StoryRoleDetailView.swift
//  voyager
//
//  Created by grapestree on 2024/10/20.
//

import SwiftUI
import Kingfisher
import PhotosUI
import ActivityIndicatorView


struct CharacterCell: View {
    var character: StoryRole
    var viewModel: StoryDetailViewModel
    @State private var showingDetail = false
    @State private var showingAvatarPreview = false

    var body: some View {
        HStack(spacing: 2) {
            // 角色头像
            if !character.role.characterAvatar.isEmpty {
                KFImage(URL(string: convertImagetoSenceImage(url: character.role.characterAvatar, scene: .small)))
                    .cacheMemoryOnly()
                    .fade(duration: 0.25)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                KFImage(URL(string: convertImagetoSenceImage(url: defaultAvator, scene: .small)))
                    .cacheMemoryOnly()
                    .fade(duration: 0.25)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Spacer()
            // 角色信息
            VStack(alignment: .leading, spacing: 8) {
                Text(character.role.characterName)
                    .font(.headline)
                
                Text(character.role.characterDescription)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                Divider()
                // 操作按钮
                HStack(spacing: 4) {
                    // 点赞按钮
                    Spacer()
                    Button(action: {
                        if character.role.currentUserStatus.isLiked {
                            Task{
                                await self.viewModel.unlikeStoryRole(roleId: character.role.roleID)
                                character.role.currentUserStatus.isLiked  = false
                            }
                        }else{
                            Task{
                                await self.viewModel.likeStoryRole(roleId: character.role.roleID)
                                character.role.currentUserStatus.isLiked  = true
                            }
                        }
                    }) {
                        if character.role.currentUserStatus.isLiked {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 16))
                        }else{
                            Image(systemName: "heart")
                                .font(.system(size: 16))
                        }
                    }
                    .foregroundColor(.red)
                    Spacer()
                    // 关注按钮
                    Button(action: {
                        if character.role.currentUserStatus.isFollowed {
                            Task{
                                await self.viewModel.followStoryRole(userId: self.viewModel.userId,
                                                                     roleId: self.character.role.roleID,
                                                                     storyId: self.character.role.storyID)
                                character.role.currentUserStatus.isFollowed = false
                            }
                        }else{
                            Task{
                                await self.viewModel.unfollowStoryRole(userId: self.viewModel.userId,
                                                                       roleId: self.character.role.roleID,
                                                                       storyId: self.character.role.storyID)
                                character.role.currentUserStatus.isFollowed = true
                            }
                        }
                    }) {
                        if character.role.currentUserStatus.isFollowed {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 16))
                        }else{
                            Image(systemName: "bell")
                                .font(.system(size: 16))
                        }
                    }
                    .foregroundColor(.blue)
                    Spacer()
                    // 详情按钮
                    Button(action: {
                        showingDetail = true
                    }) {
                        Image(systemName: "info")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.blue)
                    .navigationDestination(isPresented: $showingDetail) {
                        StoryRoleDetailView(
                            roleId: character.role.roleID,
                            userId: character.role.creatorID,
                            role: character
                        )
                    }
                    Spacer()
                }
            }
        }
        .padding(4)
        .background(Color.theme.secondaryBackground)
        .cornerRadius(4)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}


// MARK: - Main View
struct StoryRoleDetailView: View {
    // MARK: - Properties
    let roleId: Int64
    let userId: Int64
    
    @State private var role: StoryRole?
    // MARK: - State
    @StateObject private var viewModel: StoryRoleModel
    @State private var selectedTab = 0
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showChatView = false
    @State private var showPosterView = false
    
    // MARK: - Initialization
    init(roleId: Int64, userId: Int64, role: StoryRole? = nil) {
        self.roleId = roleId
        self.userId = userId
        self._viewModel = StateObject(wrappedValue: StoryRoleModel(userId: userId, roleId: roleId))

        if let role = role {
            print("init role")
            self._role = State(initialValue: role)
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 10) { // 更紧凑
                        if let role = role {
                            RoleProfileSection(
                                role: role,
                                onAvatarTap: { showImagePicker = true }
                            )
                            .padding(.top, 4)
                            .padding(.bottom, 2)
                            HStack(alignment: .center, spacing: 8) {
                                RoleStatsCard(role: role)
                                    .frame(height: 64)

                                VStack(spacing: 12) {
                                    StoryRoleActionButton(
                                        title: "聊天",
                                        icon: "bubble.left.and.bubble.right.fill",
                                        color: Color.blue,
                                        action: { showChatView = true }
                                    )
                                    StoryRoleActionButton(
                                        title: "海报",
                                        icon: "photo.on.rectangle.angled",
                                        color: Color.green,
                                        action: { showPosterView = true }
                                    )
                                }
                                .frame(height: 64)
                            }
                            .padding(.horizontal, 4)

                            CustomTabSelector(selectedTab: $selectedTab)
                                .padding(.horizontal, 4)
                                .padding(.bottom, 2)

                            RoleTabContent(
                                role: $role,
                                viewModel: viewModel,
                                selectedTab: $selectedTab
                            )
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                ActivityIndicatorView(isVisible: $isLoading, type: .growingArc(.cyan))
                            .frame(width: 64, height: 64)
                            .foregroundColor(.cyan)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .background(Color.theme.secondaryBackground)
            .sheet(isPresented: $showImagePicker) {
                SingleImagePicker(image: $selectedImage)
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    Task { await uploadAvatar(image) }
                }
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("错误"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("确定"))
                )
            }
            .fullScreenCover(isPresented: $showChatView) {
                if let role = role {
                    MessageContextView(userId: userId, roleId: roleId, role: role)
                }
            }
            .fullScreenCover(isPresented: $showPosterView) {
                if let role = role {
                    PosterView(role: role,viewModel:viewModel)
                }
            }
        }
        .task {
            if role == nil {
                await loadRoleDetails()
            }
        }
    }
    
    // MARK: - Methods
    private func loadRoleDetails() async {
        print("loadRoleDetails started - roleId: \(roleId)")
        isLoading = true
        let (fetchedRole, error) = await viewModel.fetchStoryRoleDetail(roleId: roleId)
        
        await MainActor.run {
            isLoading = false
            if let error = error {
                print("Error loading role details: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                showError = true
            } else if let fetchedRole = fetchedRole {
                print("Successfully fetched role - name: \(fetchedRole.role.characterName)")
                self.role = fetchedRole
            } else {
                print("No role data returned and no error")
                errorMessage = "无法获取角色信息"
                showError = true
            }
        }
    }
    
    private func uploadAvatar(_ image: UIImage) async {
        isLoading = true
        do {
            let imageUrl = try AliyunClient.UploadImage(image: image)
            let error = await viewModel.updateRoleAvatar(userId: userId, roleId: roleId, avatar: imageUrl)
            await MainActor.run {
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
                    showError = true
                } else {
                    // Refresh role details after successful upload
                    Task {
                        await loadRoleDetails()
                    }
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Profile Section
struct RoleProfileSection: View {
    let role: StoryRole
    let onAvatarTap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: onAvatarTap) {
                KFImage(URL(string: role.role.characterAvatar.isEmpty ? defaultAvator : convertImagetoSenceImage(url: role.role.characterAvatar, scene: .small)))
                    .cacheMemoryOnly()
                    .fade(duration: 0.25)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.theme.border, lineWidth: 1))
            }
            
                Text(role.role.characterName)
                    .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.theme.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.theme.secondaryBackground)
        .cornerRadius(12)
    }
}

// MARK: - Action Buttons
struct RoleActionButtons: View {
    let onChat: () -> Void
    let onPoster: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            Spacer()
            StoryRoleActionButton(
                title: "聊天",
                icon: "message.fill",
                color: Color.theme.accent,
                action: onChat
            )
            Spacer()
            StoryRoleActionButton(
                title: "海报",
                icon: "photo.fill",
                color: Color.theme.primary,
                action: onPoster
            )
            Spacer()
        }
    }
}

struct StoryRoleActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(width: 64, height: 24)
            .background(color)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Stats Card
struct RoleStatsCard: View {
    let role: StoryRole
    
    var body: some View {
        HStack(spacing: 20) {
            StoryRoleStatItem(
                icon: "heart.fill",
                color: Color.theme.error,
                value: role.role.likeCount,
                title: "点赞"
            )
            
            StoryRoleStatItem(
                icon: "person.2.fill",
                color: Color.theme.accent,
                value: role.role.followCount,
                title: "关注"
            )
            
            StoryRoleStatItem(
                icon: "book.fill",
                color: Color.theme.success,
                value: role.role.storyboardNum,
                title: "故事"
            )
        }
        .padding(12)
        .background(Color.theme.secondaryBackground)
        .cornerRadius(12)
    }
}

struct StoryRoleStatItem: View {
    let icon: String
    let color: Color
    let value: Int64
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text("\(value)")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.theme.primaryText)
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Color.theme.secondaryText)
        }
    }
}

// MARK: - Tab Content
struct RoleTabContent: View {
    @Binding var role: StoryRole?
    let viewModel: StoryRoleModel
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(spacing: 0) {
            if let role = role {
                TabView(selection: $selectedTab) {
                    // 简介 Tab
                    RoleInfoTab(role: role, viewModel: viewModel, onRoleUpdate: { updatedRole in
                        self.role = updatedRole
                    })
                        .tag(0)
                    
                    // 详情 Tab
                    RoleDetailTab(role: role, onRoleUpdate: { updatedRole in
                        self.role = updatedRole
                    })
                        .tag(1)
                    
                    // 参与 Tab
                    RoleParticipationTab(viewModel: viewModel)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(minHeight: 400)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Info Tab
struct RoleInfoTab: View {
    let role: StoryRole
    let viewModel: StoryRoleModel
    let onRoleUpdate: (StoryRole) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                RoleSummarySection(role: role, viewModel: viewModel, onRoleUpdate: onRoleUpdate)
                    .padding(.horizontal, 8)

            }
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Participation Tab
struct RoleParticipationTab: View {
    @ObservedObject var viewModel: StoryRoleModel
    @State private var didAppear = false
    // 需要传入当前角色id和storyId
    var roleId: Int64 {
        viewModel.roleId
    }
    var storyId: Int64 {
        viewModel.storyId
    }
    
    var body: some View {
        Group {
            if viewModel.roleStoryboards.isEmpty && !viewModel.isLoadingMore && !viewModel.isRefreshing {
                VStack {
                    Spacer()
                    Image(systemName: "retarder.brakesignal.and.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundColor(Color.theme.error)
                    Spacer()
                        .font(.system(size: 10))
                    Text("这个故事角色是NPC么?!")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.roleStoryboards, id: \ .id) { board in
                            ParticipationCell(board: board)
                                .padding(.horizontal, 8)
                                .onAppear {
                                    // 上滑加载更多
                                    if board.id == viewModel.roleStoryboards.last?.id {
                                        Task {
                                            await viewModel.loadMoreRoleStoryboards(roleId: roleId, storyId: storyId)
                                        }
                                    }
                                }
                        }
                        if viewModel.isLoadingMore {
                            ProgressView("加载更多...")
                                .padding()
                        }
                    }
                    .padding(.vertical, 16)
                }
                .refreshable {
                    await viewModel.refreshRoleStoryboards(roleId: roleId, storyId: storyId)
                }
            }
        }
        .onAppear {
            if !didAppear {
                didAppear = true
                Task {
                    await viewModel.loadInitialRoleStoryboards(roleId: roleId, storyId: storyId)
                }
            }
        }
    }
}

// MARK: - Participation Cell
struct ParticipationCell: View {
    let board: StoryBoardActive
    @State private var showStoryboardSummary = false
    @State private var showChildNodes = false
    // 可选：传入 userId/viewModel 以支持点赞等操作
    // let userId: Int64
    // @ObservedObject var viewModel: StoryRoleModel
    // ...如需支持交互可解开

    // 解析场景图片内容
    var sceneMediaContents: [SceneMediaContent] {
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
        return tempSceneContents
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部信息
            HStack(spacing: 8) {
                // 故事缩略图和名称
                HStack(spacing: 4) {
                    HStack(spacing: 8) {
                        KFImage(URL(string: convertImagetoSenceImage(url: board.boardActive.summary.storyAvatar, scene: .small)))
                            .cacheMemoryOnly()
                            .fade(duration: 0.25)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.theme.border, lineWidth: 0.5))
                        Text(board.boardActive.summary.storyTitle)
                            .font(.system(size: 15))
                            .foregroundColor(Color.theme.accent)
                    }
                    Divider()
                    HStack{
                        KFImage(URL(string: convertImagetoSenceImage(url: board.boardActive.creator.userAvatar, scene: .small)))
                            .cacheMemoryOnly()
                            .fade(duration: 0.25)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 20, height: 20)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.theme.border, lineWidth: 0.5))
                        Text(board.boardActive.creator.userName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.theme.primaryText)
                        Text("创建")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.theme.primaryText)
                    }
                }
                Spacer()
                Text(formatTimeAgo(timestamp: board.boardActive.storyboard.ctime))
                    .font(.system(size: 12))
                    .foregroundColor(Color.theme.tertiaryText)
            }
            .padding(.horizontal)

            // 内容
            VStack(alignment: .leading, spacing: 8) {
                Text(board.boardActive.storyboard.content)
                    .font(.system(size: 15))
                    .foregroundColor(Color.theme.primaryText)
                    .lineLimit(3)
                if !self.sceneMediaContents.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 2) {
                                ForEach(self.sceneMediaContents, id: \.id) { sceneContent in
                                    LazyVStack(alignment: .leading, spacing: 2) {
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
                                                .cornerRadius(6)
                                                .contentShape(Rectangle())
                                        }
                                        Text(sceneContent.sceneTitle)
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.theme.secondaryText)
                                            .lineLimit(2)
                                            .frame(width: 140)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(.horizontal)

            // 交互按钮
            HStack(spacing: 24) {
                HStack(spacing: 4) {
                    Image(systemName: board.boardActive.isliked ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                    Text("\(board.boardActive.totalLikeCount)")
                        .font(.system(size: 14))
                }
                .foregroundColor(board.boardActive.isliked ? Color.red : Color.theme.tertiaryText)
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 16))
                    Text("\(board.boardActive.totalCommentCount)")
                        .font(.system(size: 14))
                }
                .foregroundColor(Color.theme.tertiaryText)
                HStack(spacing: 4) {
                    Image(systemName: "signpost.right.and.left")
                        .font(.system(size: 16))
                    Text("\(board.boardActive.totalForkCount)")
                        .font(.system(size: 14))
                }
                .foregroundColor(Color.theme.tertiaryText)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 6)
        .background(Color.theme.secondaryBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.theme.border, lineWidth: 0.5)
        )
        .shadow(color: Color.theme.primaryText.opacity(0.05), radius: 4, y: 2)
    }
}

struct StoryRoleInteractionButton: View {
    let icon: String
    let color: Color
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(text)
                    .font(.system(size: 14))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Detail Section
struct RoleSummarySection: View {
    let role: StoryRole
    let viewModel: StoryRoleModel
    let onRoleUpdate: (StoryRole) -> Void
    @State private var showingDescriptionEditor = false
    @State private var showingPromptEditor = false
    @State private var isExpanded = false
    
    // 获取当前用户ID
    var currentUserId: Int64 { viewModel.userId }
    // 角色创建者ID
    var roleCreatorId: Int64 { role.role.creatorID }
    // 故事创建者ID
    var storyCreatorId: Int64 { role.role.creator.userID }
    // 是否有编辑权限
    var canEdit: Bool { currentUserId == roleCreatorId || currentUserId == storyCreatorId }
    
    var body: some View {
        VStack(spacing: 16) {
            // Character Description Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("角色描述")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.theme.primaryText)
                    
                    Spacer()
                    
                    if canEdit {
                        Button(action: { showingDescriptionEditor = true }) {
                            Image(systemName: "pencil.circle")
                                .foregroundColor(Color.theme.accent)
                        }
                    }
                }
                
                Text(role.role.characterDescription.isEmpty ? "角色比较神秘，没有介绍！" : role.role.characterDescription)
                    .font(.system(size: 14))
                    .foregroundColor(role.role.characterDescription.isEmpty ? Color.theme.tertiaryText : Color.theme.primaryText)
                    .lineLimit(isExpanded ? nil : 3)
                    .multilineTextAlignment(.leading)
                
                if !role.role.characterDescription.isEmpty {
                    Button(action: { isExpanded.toggle() }) {
                        Text(isExpanded ? "收起" : "展开")
                            .font(.system(size: 14))
                            .foregroundColor(Color.theme.accent)
                    }
                }
            }
            .background(Color.theme.secondaryBackground)
            .sheet(isPresented: $showingDescriptionEditor) {
                EditDescriptionView(role: role, viewModel: viewModel, onRoleUpdate: onRoleUpdate)
            }
            .padding()
            Divider()
                .padding()
            // Character Prompt Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("角色提示词")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.theme.primaryText)
                    
                    Spacer()
                    
                    if canEdit {
                        Button(action: { showingPromptEditor = true }) {
                            Image(systemName: "pencil.circle")
                                .foregroundColor(Color.theme.accent)
                        }
                    }
                }
                
                Text(role.role.characterPrompt.isEmpty ? "提示词为空" : role.role.characterPrompt)
                    .font(.system(size: 14))
                    .foregroundColor(role.role.characterPrompt.isEmpty ? Color.theme.tertiaryText : Color.theme.primaryText)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                }
            .background(Color.theme.secondaryBackground)
            .sheet(isPresented: $showingPromptEditor) {
                EditPromptView(role: role, viewModel: viewModel, onRoleUpdate: onRoleUpdate)
            }
            .padding()
            Divider()
                .padding()
            // Other Information Section
            VStack(alignment: .leading, spacing: 8) {
                Text("其他信息")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.theme.primaryText)
                
                VStack(spacing: 12) {
                    InfoRow(icon: "person.fill", title: "创建者", value: "\(role.role.creator.name)")
                    InfoRow(icon: "clock.fill", title: "创建时间", value: formatDate(timestamp: role.role.ctime))
                    InfoRow(icon: "number", title: "角色ID", value: "\(role.role.roleID)")
                    if role.role.mtime != 0 {
                        InfoRow(icon: "clock.arrow.circlepath", title: "最后修改", value: formatDate(timestamp: role.role.mtime))
                    }
                }
            }
            .background(Color.theme.secondaryBackground)
            .padding()
            Divider()
                .padding()
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatDate(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// 信息行组件
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
                Image(systemName: icon)
                .foregroundColor(Color.theme.accent)
                .frame(width: 20)
            
                Text(title)
                .font(.system(size: 14))
                .foregroundColor(Color.theme.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(Color.theme.primaryText)
        }
    }
}

// MARK: - Edit Description View
struct EditDescriptionView: View {
    let role: StoryRole
    let viewModel: StoryRoleModel
    let onRoleUpdate: (StoryRole) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var detail: Common_CharacterDetail
    @State private var isGenerating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedTab = 0 // 0: 描述, 1: 图片

    init(role: StoryRole, viewModel: StoryRoleModel, onRoleUpdate: @escaping (StoryRole) -> Void) {
        self.role = role
        self.viewModel = viewModel
        self.onRoleUpdate = onRoleUpdate
        _detail = State(initialValue: role.role.characterDetail)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 标题
                Text("编辑角色信息")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.theme.primaryText)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Tab 切换栏
                HStack(spacing: 0) {
                    TabButton(title: "描述", selected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    TabButton(title: "图片", selected: selectedTab == 1) {
                        selectedTab = 1
                    }
                }
                .background(Color.theme.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.theme.border, lineWidth: 2)
                )
                .cornerRadius(12)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 8)

                // Tab 内容
                HStack {
                    TabView(selection: $selectedTab) {
                        // 描述 Tab
                        VStack{
                            DescriptionEditTab(
                                detail: $detail,
                                isGenerating: $isGenerating,
                                onAIGenerate: generateAll
                            )
                            // AI生成按钮
                            Button(action: { generateAll() }) {
                                HStack {
                                    Image(systemName: "wand.and.stars")
                                    Text("AI一键生成")
                                }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.theme.accent)
                                .cornerRadius(12)
                            }
                            .padding(.vertical, 12)
                            .disabled(isGenerating)
                        }
                        .tag(0)
                        // 图片 Tab
                        RoleImageGenView(viewModel: viewModel)
                            .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { Task { await save() } }
                        .foregroundColor(Color.theme.accent)
                }
            }
            .alert("生成失败", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    /// AI一键生成所有维度
    private func generateAll() {
        isGenerating = true
        Task{
            let (newDetail, error) = await viewModel.generateRoleDescription(
                storyId: role.role.storyID,
                roleId: role.role.roleID,
                userId: viewModel.userId,
                sampleDesc: detail.description_p
            )
            await MainActor.run {
                isGenerating = false
                if let error = error {
                    errorMessage = error.localizedDescription
                    showError = true
                } else if let newDetail = newDetail {
                    self.detail = newDetail
                }
            }
        }
    }

    /// 保存角色信息
    private func save() async {
        let error = await viewModel.updateRoleDescription(
            roleId: role.role.roleID,
            userId: viewModel.userId,
            desc: detail
        )
        if let error = error {
            errorMessage = error.localizedDescription
            showError = true
        } else {
            var updatedRole = role
            updatedRole.role.characterDetail = detail
            onRoleUpdate(updatedRole)
            dismiss()
        }
    }
}

// MARK: - Tab 切换按钮
private struct TabButton: View {
    let title: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: selected ? .bold : .regular))
                .foregroundColor(selected ? Color.theme.accent : Color.theme.tertiaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selected ? Color.theme.accent.opacity(0.08) : Color.clear)
                .cornerRadius(8)
        }
    }
}

// MARK: - 描述编辑Tab内容
private struct DescriptionEditTab: View {
    @Binding var detail: Common_CharacterDetail
    @Binding var isGenerating: Bool
    let onAIGenerate: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            if isGenerating {
                ProgressView("AI生成中...")
                    .padding(.bottom, 8)
            }

            // 内容区
            ScrollView {
                VStack(spacing: 4) {
                    DescriptionEditField(emoji: "📝", title: "角色描述", text: $detail.description_p)
                    DescriptionEditField(emoji: "🎯", title: "短期目标", text: $detail.shortTermGoal)
                    DescriptionEditField(emoji: "🏆", title: "长期目标", text: $detail.longTermGoal)
                    DescriptionEditField(emoji: "😃", title: "性格特征", text: $detail.personality)
                    DescriptionEditField(emoji: "📖", title: "背景故事", text: $detail.background)
                    DescriptionEditField(emoji: "🤝", title: "处事方式", text: $detail.handlingStyle)
                    DescriptionEditField(emoji: "👀", title: "认知范围", text: $detail.cognitionRange)
                    DescriptionEditField(emoji: "💡", title: "能力特点", text: $detail.abilityFeatures)
                    DescriptionEditField(emoji: "👤", title: "外貌特征", text: $detail.appearance)
                    DescriptionEditField(emoji: "👗", title: "着装偏好", text: $detail.dressPreference)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 24)
            }
        }
        .background(Color.theme.secondaryBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.theme.border, lineWidth: 2)
        )
        .cornerRadius(12)
    }
}

// MARK: - 单个维度编辑卡片
private struct DescriptionEditField: View {
    let emoji: String
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(emoji) \(title)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.theme.primaryText)
                Spacer()
            }
            TextEditor(text: $text)
                .font(.system(size: 15))
                .foregroundColor(Color.theme.primaryText)
                .frame(minHeight: 60, maxHeight: 120)
                .background(Color.theme.inputBackground)
                .cornerRadius(8)
        }
        .padding(14)
        .background(Color.theme.secondaryBackground)
        .cornerRadius(14)
    }
}

// MARK: - Edit Prompt View
struct EditPromptView: View {
    let role: StoryRole
    let viewModel: StoryRoleModel
    let onRoleUpdate: (StoryRole) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var prompt: String
    @State private var isGenerating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(role: StoryRole, viewModel: StoryRoleModel, onRoleUpdate: @escaping (StoryRole) -> Void) {
        self.role = role
        self.viewModel = viewModel
        self.onRoleUpdate = onRoleUpdate
        _prompt = State(initialValue: role.role.characterPrompt)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Text("编辑角色提示词")
                    .font(.system(size: 16, weight: .medium))
                    .padding(.top)
                
                Text("提示词将用于AI对话中塑造角色性格")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                // AI生成按钮
                Button(action: {
                    Task {
                        await generatePrompt()
                    }
                }) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("AI生成提示词")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(20)
                }
                .disabled(isGenerating)
                
                if isGenerating {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("正在生成提示词...")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                TextEditor(text: $prompt)
                    .font(.system(size: 14))
                    .padding(8)
                    .frame(maxHeight: 300)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            await savePrompt()
                        }
                    }
                }
            }
            .alert("生成失败", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func generatePrompt() async {
        isGenerating = true
        let (newPrompt, error) = await viewModel.generateRolePrompt(
            storyId: role.role.storyID,
            roleId: role.role.roleID,
            userId: viewModel.userId,
            samplePrompt: prompt
        )
        
        await MainActor.run {
            isGenerating = false
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
            } else if let newPrompt = newPrompt {
                prompt = newPrompt
            }
        }
    }
    
    private func savePrompt() async {
        do {
            let error = await viewModel.updateRolePrompt(
                userId: viewModel.userId,
                roleId: role.role.roleID,
                prompt: prompt
            )
            
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
            } else {
                var updatedRole = role
                updatedRole.role.characterPrompt = prompt
                onRoleUpdate(updatedRole)
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Edit Info View
struct EditInfoView: View {
    let role: StoryRole
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
    init(role: StoryRole, onSave: @escaping () -> Void) {
        self.role = role
        self.onSave = onSave
        _name = State(initialValue: role.role.characterName)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    HStack {
                        Text("角色名称")
                        Spacer()
                        TextField("输入角色名称", text: $name)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Button(action: { showImagePicker = true }) {
                        HStack {
                            Text("更换头像")
                            Spacer()
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            } else {
                                KFImage(URL(string: convertImagetoSenceImage(url: role.role.characterAvatar, scene: .small)))
                                    .cacheMemoryOnly()
                                    .fade(duration: 0.25)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                
                Section(header: Text("其他信息")) {
                    HStack {
                        Text("创建时间")
                        Spacer()
                        Text(formatDate(timestamp: role.role.ctime))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("角色ID")
                        Spacer()
                        Text("\(role.role.roleID)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        // TODO: 实现保存逻辑
                        onSave()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                SingleImagePicker(image: $selectedImage)
            }
        }
    }
}

struct PosterView: View {
    let role: StoryRole?
    @Environment(\.dismiss) private var dismiss
    let defaultPosterImage = "https://grapery-1301865260.cos.ap-shanghai.myqcloud.com/poster/default_role_poster.png"
    @State private var isImageLoaded = false

    // 新增
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    @State private var isAIGenerating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    @State public var viewModel: StoryRoleModel

    // 你需要根据实际业务传入当前用户ID和角色/故事创建者ID
    var currentUserId: Int64 = 0
    var creatorId: Int64? { role?.role.creatorID } // 假设有这个字段
    var storyCreatorId: Int64? { role?.role.creator.userID } // 假设有这个字段

    var canEdit: Bool {
        guard let creatorId = creatorId, let storyCreatorId = storyCreatorId else { return false }
        return currentUserId == creatorId || currentUserId == storyCreatorId
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.theme.background,
                        Color.theme.secondaryBackground
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )

                // 海报图片
                KFImage(URL(string: convertImagetoSenceImage(url: role?.role.characterAvatar ?? "", scene: .content)))
                    .cacheMemoryOnly()
                    .fade(duration: 0.25)
                    .placeholder {
                        Rectangle()
                            .fill(Color.theme.secondaryBackground)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 30))
                                    .foregroundColor(Color.theme.tertiaryText)
                            )
                    }
                    .loadDiskFileSynchronously()
                    .cacheMemoryOnly()
                    .fade(duration: 0.25)
                    .onSuccess { _ in
                        isImageLoaded = true
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                // 渐变遮罩
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )

                // 角色信息叠加层
                VStack(spacing: 0) {
                    // 顶部导航栏
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(8)
                        }
                        Spacer()
                        // 右上角按钮
                        if canEdit {
                            HStack(spacing: 8) {
                                Button(action: {
                                    Task { await handleAIGenerate() }
                                }) {
                                    Text(isAIGenerating ? "生成中..." : "AI更新")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.8))
                                        .cornerRadius(8)
                                }
                                .disabled(isAIGenerating)
                                Button(action: {
                                    showImagePicker = true
                                }) {
                                    Text(isUploading ? "上传中..." : "上传更新")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.green.opacity(0.8))
                                        .cornerRadius(8)
                                }
                                .disabled(isUploading)
                            }
                        }
                    }
                    .padding(.top, geometry.safeAreaInsets.top + 16)
                    .padding(.horizontal, 16)

                    Spacer()

                    // 底部角色信息
                    VStack(alignment: .leading, spacing: 12) {
                        Text(role?.role.characterName ?? "未知角色")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Text(role?.role.characterDescription ?? "暂无描述")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(20)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0),
                                Color.black.opacity(0.8)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .edgesIgnoringSafeArea(.all)
            .sheet(isPresented: $showImagePicker) {
                SingleImagePicker(image: $selectedImage)
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    Task { await handleUpload(image: image) }
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // AI生成
    private func handleAIGenerate() async {
        isAIGenerating = true
        defer { isAIGenerating = false }
        print("handleAIGenerate self.role ", self.role as Any)
        do{
            // TODO: 调用你的AI生成接口
            let result = await viewModel.generateStoryRolePoster(
                userId: (self.role?.role.storyID)!,
                roleId: self.role!.role.roleID,
                storyId: self.role!.role.storyID)
            // 更新图片逻辑
            if result.1 == nil {
                self.role?.role.posterImageURL = result.0!
            }else{
                errorMessage = "AI生成失败：" + result.1!.localizedDescription
                showError = true
            }
            
        } catch {
            errorMessage = "AI生成失败：" + error.localizedDescription
            showError = true
        }
    }

    // 上传图片
    private func handleUpload(image: UIImage) async {
        isUploading = true
        defer { isUploading = false }
        print("handleUpload self.role ", self.role as Any)
        do {
            
            let url = try AliyunClient.UploadImage(image: image)
            if url.isEmpty {
                errorMessage = "上传失败：获取图片URL失败"
                showError = true
                return
            }
            let err = await viewModel.updateStoryRolePoster(
                userId: (self.role?.role.storyID)!,
                roleId: self.role!.role.roleID,
                posterUrl: url)
            if err == nil {
                self.role?.role.posterImageURL = url
            }else{
                errorMessage = "AI生成失败：" + err!.localizedDescription
                showError = true
            }
        } catch {
            errorMessage = "上传失败：" + error.localizedDescription
            showError = true
        }
    }
}

// 自定义 Tab 选择器
struct CustomTabSelector: View {
    @Binding var selectedTab: Int
    private let tabs = ["简介", "详情", "参与"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tabs[index])
                            .font(.system(size: 15))
                            .foregroundColor(selectedTab == index ? Color.theme.accent : Color.theme.tertiaryText)
                        
                        Rectangle()
                            .fill(selectedTab == index ? Color.theme.accent : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color.theme.secondaryBackground)
    }
}

private struct DescriptionField: View {
    let emoji: String
    let title: String
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {              
                Text(emoji)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.theme.primaryText)
            }
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Color.theme.primaryText)
        }
    }
}

// MARK: - Detail Tab
struct RoleDetailTab: View {
    let role: StoryRole
    let onRoleUpdate: (StoryRole) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                DescriptionField(emoji: "📝", title: "角色描述", text: role.role.characterDetail.description_p)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.theme.secondaryBackground)
                    .cornerRadius(2)
                Divider()
                    .padding()
                DescriptionField(emoji: "🎯", title: "短期目标", text: role.role.characterDetail.shortTermGoal)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.theme.secondaryBackground)
                    .cornerRadius(2)
                Divider()
                    .padding()
                DescriptionField(emoji: "🏆", title: "长期目标", text: role.role.characterDetail.longTermGoal)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.theme.secondaryBackground)
                    .cornerRadius(2)
                Divider()
                    .padding()
                DescriptionField(emoji: "😃", title: "性格特征", text: role.role.characterDetail.personality)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.theme.secondaryBackground)
                    .cornerRadius(2)
                Divider()
                    .padding()
                DescriptionField(emoji: "📖", title: "背景故事", text: role.role.characterDetail.background)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.theme.secondaryBackground)
                    .cornerRadius(2)
                Divider()
                    .padding()
                DescriptionField(emoji: "🤝", title: "处事方式", text: role.role.characterDetail.handlingStyle)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.theme.secondaryBackground)
                    .cornerRadius(2)
                Divider()
                    .padding()
                DescriptionField(emoji: "👀", title: "认知范围", text: role.role.characterDetail.cognitionRange)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.theme.secondaryBackground)
                    .cornerRadius(2)
                Divider()
                    .padding()
                DescriptionField(emoji: "💡", title: "能力特点", text: role.role.characterDetail.abilityFeatures)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.theme.secondaryBackground)
                    .cornerRadius(2)
                Divider()
                    .padding()
                DescriptionField(emoji: "👤", title: "外貌特征", text: role.role.characterDetail.appearance)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.theme.secondaryBackground)
                    .cornerRadius(2)
                Divider()
                    .padding()
                DescriptionField(emoji: "👗", title: "着装偏好", text: role.role.characterDetail.dressPreference)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.theme.secondaryBackground)
                    .cornerRadius(2)
                Divider()
                    .padding()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DetailSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.theme.primaryText)
            
            Text(content.isEmpty ? "暂无内容" : content)
                .font(.system(size: 14))
                .foregroundColor(content.isEmpty ? Color.theme.tertiaryText : Color.theme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.theme.background)
                .cornerRadius(8)
        }
    }
}


