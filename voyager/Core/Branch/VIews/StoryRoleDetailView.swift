//
//  StoryRoleDetailView.swift
//  voyager
//
//  Created by grapestree on 2024/10/20.
//

import SwiftUI
import Kingfisher


struct CharacterCell: View {
    let character: StoryRole
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
                    .frame(width: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                KFImage(URL(string: defaultAvator))
                    .cacheMemoryOnly()
                    .fade(duration: 0.25)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Divider()
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
                        // TODO: 实现点赞功能
                    }) {
                        Image(systemName: "heart")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.orange)
                    Spacer()
                    // 关注按钮
                    Button(action: {
                        // TODO: 实现关注功能
                    }) {
                        Image(systemName: "bell")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.orange)
                    Spacer()
                    // 聊天按钮
                    Button(action: {
                        // TODO: 跳转到聊天界面
                    }) {
                        Image(systemName: "message")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.orange)
                    Spacer()
                    // 详情按钮
                    Button(action: {
                        showingDetail = true
                    }) {
                        Image(systemName: "info")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.orange)
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
        .background(Color(.systemBackground))
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
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    init(roleId: Int64, userId: Int64, role: StoryRole? = nil) {
        self.roleId = roleId
        self.userId = userId
        self._viewModel = StateObject(wrappedValue: StoryRoleModel(userId: userId))
        
        // 如果提供了初始角色数据，使用它
        if let role = role {
            self._role = State(initialValue: role)
        } else {
            print("No initial role data, will fetch from API")
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        if let role = role {
                            // Profile Section
                            RoleProfileSection(
                                role: role,
                                onAvatarTap: { showImagePicker = true }
                            )
                            
                            // Action Buttons
                            RoleActionButtons(
                                onChat: { showChatView = true },
                                onPoster: { showPosterView = true }
                            )
                            .padding(.horizontal, 16)
                            
                            // Stats Card
                            RoleStatsCard(role: role)
                                .padding(.horizontal, 16)
                            CustomTabSelector(selectedTab: $selectedTab)
                                .padding(.horizontal, 16)
                            // Tab Content
                            RoleTabContent(
                                role: role,
                                viewModel: viewModel,
                                selectedTab: $selectedTab
                            )
                        }
                    }
                    .padding(.vertical, 16)
                }
                
                if isLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(Color.theme.primaryText)
            })
            .sheet(isPresented: $showImagePicker) {
                SingleImagePicker(image: $selectedImage)
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    Task {
                        await uploadAvatar(image)
                    }
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
                    PosterView(role: role)
                }
            }
        }
        .task {
            // 只有在没有初始角色数据时才从API获取
            if role == nil {
                print("Starting loadRoleDetails task")
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
            let imageUrl = try await AliyunClient.UploadImage(image: image)
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
        HStack(spacing: 12) {
            StoryRoleActionButton(
                title: "聊天",
                icon: "message.fill",
                color: Color.theme.accent,
                action: onChat
            )
            
            StoryRoleActionButton(
                title: "海报",
                icon: "photo.fill",
                color: Color.theme.primary,
                action: onPoster
            )
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
            Label(title, systemImage: icon)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(height: 32)
                .frame(width: 120)
                .background(color)
                .cornerRadius(16)
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
    let role: StoryRole?
    let viewModel: StoryRoleModel
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(spacing: 0) {
            if let role = role {
                TabView(selection: $selectedTab) {
                    // 简介 Tab
                    RoleInfoTab(role: role, viewModel: viewModel)
                        .tag(0)
                    
                    // 参与 Tab
                    RoleParticipationTab(viewModel: viewModel)
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(minHeight: 400) // 增加高度以显示更多内容
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DetailSection(role: role, viewModel: viewModel)
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Participation Tab
struct RoleParticipationTab: View {
    @ObservedObject var viewModel: StoryRoleModel
    
    var body: some View {
        if viewModel.roleStoryboards.isEmpty {
            VStack {
                Spacer()
                Image(systemName: "retarder.brakesignal.and.exclamationmark")
                    .font(.system(size: 50))
                    .foregroundColor(Color.theme.error)
                Text("这个故事角色是NPC么?!")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.roleStoryboards, id: \.id) { board in
                        ParticipationCell(board: board)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
            }
        }
    }
}

// MARK: - Participation Cell
struct ParticipationCell: View {
    let board: StoryBoardActive
    @State private var isLiked = false
    @State private var showDetail = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Content Section
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    KFImage(URL(string: convertImagetoSenceImage(url: board.boardActive.creator.userAvatar, scene: .small)))
                        .cacheMemoryOnly()
                        .fade(duration: 0.25)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(board.boardActive.creator.userName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.theme.primaryText)
                        
                        Text(formatDate(timestamp: board.boardActive.storyboard.ctime))
                            .font(.system(size: 12))
                            .foregroundColor(Color.theme.tertiaryText)
                    }
                    
                    Spacer()
                }
                
                // Title and Content
                Text(board.boardActive.storyboard.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.theme.primaryText)
                    .lineLimit(2)
                
                Text(board.boardActive.storyboard.content)
                    .font(.system(size: 14))
                    .foregroundColor(Color.theme.secondaryText)
                    .lineLimit(3)
            }
            .padding(16)
            .background(Color.theme.secondaryBackground)
            
            // Interaction Bar
            HStack(spacing: 0) {
                // Like Button
                StoryRoleInteractionButton(
                    icon: isLiked ? "heart.fill" : "heart",
                    color: isLiked ? Color.theme.error : Color.theme.tertiaryText,
                    text: "\(board.boardActive.totalLikeCount)",
                    action: {
                        withAnimation(.spring()) {
                            isLiked.toggle()
                        }
                    }
                )
                
                Divider()
                    .frame(height: 24)
                    .background(Color.theme.divider)
                
                // Comment Button
                StoryRoleInteractionButton(
                    icon: "bubble.left",
                    color: Color.theme.tertiaryText,
                    text: "\(board.boardActive.totalCommentCount)",
                    action: { showDetail = true }
                )
                
                Divider()
                    .frame(height: 24)
                    .background(Color.theme.divider)
                
                // Share Button
                StoryRoleInteractionButton(
                    icon: "square.and.arrow.up",
                    color: Color.theme.tertiaryText,
                    text: "\(board.boardActive.totalForkCount)",
                    action: { }
                )
            }
            .frame(height: 44)
            .background(Color.theme.secondaryBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
    
    private func formatDate(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
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
struct DetailSection: View {
    let role: StoryRole
    let viewModel: StoryRoleModel
    @State private var showingDescriptionEditor = false
    @State private var showingPromptEditor = false
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Character Description Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("角色描述")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.theme.primaryText)
                    
                    Spacer()
                    
                    Button(action: { showingDescriptionEditor = true }) {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(Color.theme.accent)
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
            .padding(12)
            .background(Color.theme.background)
            .cornerRadius(8)
            .sheet(isPresented: $showingDescriptionEditor) {
                EditDescriptionView(role: role, viewModel: viewModel)
            }
            
            // Character Prompt Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("角色提示词")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.theme.primaryText)
                    
                    Spacer()
                    
                    Button(action: { showingPromptEditor = true }) {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(Color.theme.accent)
                    }
                }
                
                Text(role.role.characterPrompt.isEmpty ? "提示词为空" : role.role.characterPrompt)
                    .font(.system(size: 14))
                    .foregroundColor(role.role.characterPrompt.isEmpty ? Color.theme.tertiaryText : Color.theme.primaryText)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                }
            .padding(12)
            .background(Color.theme.background)
            .cornerRadius(8)
            .sheet(isPresented: $showingPromptEditor) {
                EditPromptView(role: role, viewModel: viewModel)
            }
            
            // Other Information Section
            VStack(alignment: .leading, spacing: 8) {
                Text("其他信息")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.theme.primaryText)
                
                VStack(spacing: 12) {
                    InfoRow(icon: "person.fill", title: "创建者", value: "\(role.role.creatorID)")
                    InfoRow(icon: "clock.fill", title: "创建时间", value: formatDate(timestamp: role.role.ctime))
                    InfoRow(icon: "number", title: "角色ID", value: "\(role.role.roleID)")
                    if role.role.mtime != 0 {
                        InfoRow(icon: "clock.arrow.circlepath", title: "最后修改", value: formatDate(timestamp: role.role.mtime))
                    }
                }
            }
            .padding(12)
            .background(Color.theme.background)
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity) // 确保占满宽度
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
    @Environment(\.dismiss) private var dismiss
    @State private var description: String
    @State private var isGenerating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(role: StoryRole, viewModel: StoryRoleModel) {
        self.role = role
        self.viewModel = viewModel
        _description = State(initialValue: role.role.characterDescription)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Text("编辑角色描述")
                    .font(.system(size: 16, weight: .medium))
                    .padding(.top)
                
                // AI生成按钮
                Button(action: {
                    Task {
                        await generateDescription()
                    }
                }) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("AI生成角色描述")
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
                        Text("正在生成描述...")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                TextEditor(text: $description)
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
                            await saveDescription()
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
    
    private func generateDescription() async {
        isGenerating = true
            let (newDescription, error) = await viewModel.generateRoleDescription(
                storyId: role.role.storyID,
                roleId: role.role.roleID,
                userId: viewModel.userId,
                sampleDesc: description
            )
            
            await MainActor.run {
            isGenerating = false
                if let error = error {
                    errorMessage = error.localizedDescription
                    showError = true
                } else if let newDescription = newDescription {
                    description = newDescription
                }
        }
    }
    
    private func saveDescription() async {
        do {
            let error = await viewModel.updateRoleDescription(
                roleId: role.role.roleID,
                userId: viewModel.userId,
                desc: description
            )
            
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
            } else {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Edit Prompt View
struct EditPromptView: View {
    let role: StoryRole
    let viewModel: StoryRoleModel
    @Environment(\.dismiss) private var dismiss
    @State private var prompt: String
    @State private var isGenerating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(role: StoryRole, viewModel: StoryRoleModel) {
        self.role = role
        self.viewModel = viewModel
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
    
    init(role: StoryRole?, isImageLoaded: Bool = false) {
        self.role = role
        self.isImageLoaded = isImageLoaded
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
                KFImage(URL(string: defaultPosterImage))
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
        }
    }
}

// 自定义 Tab 选择器
struct CustomTabSelector: View {
    @Binding var selectedTab: Int
    private let tabs = ["简介", "参与"]
    
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


