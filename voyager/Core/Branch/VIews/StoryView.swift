//
//  StoryView.swift
//  voyager
//
//  Created by grapestree on 2024/9/24.
//

import SwiftUI
import Kingfisher
import Combine
import AVKit

struct StoryView: View {
    @StateObject var viewModel: StoryViewModel
    @State private var isEditing: Bool = false
    @State public var storyId: Int64
    @State private var selectedTab: Int64 = 0
    @State public var story: Story = Story()
    
    var userId: Int64
    
    // 新增的状态变量
    @State private var generatedStory: Common_RenderStoryDetail?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    
    @State private var isShowingNewStoryBoard = false
    @State private var isShowingCommentView = false
    @State private var isForkingStory = false
    @State private var isLiked = false
    @State private var isShowingNewRole = false
    
    @State private var selectedBoard: StoryBoard?
    @State private var isShowingBoardDetail = false
    
    // 添加错误处理相关状态
    @State private var showingErrorToast = false
    @State private var showingErrorAlert = false
    
    @State private var showingParticipants = false
    
    init(story: Story, userId: Int64) {
        self.story = story
        self.userId = userId
        self.storyId = story.storyInfo.id
        _viewModel = StateObject(wrappedValue: StoryViewModel(story: story, userId: userId))
    }

    init(storyId: Int64, userId: Int64) {
        self.storyId = storyId
        self.userId = userId
        _viewModel = StateObject(wrappedValue: StoryViewModel(storyId: storyId, userId: userId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Story Info Header
            StoryHeaderView(
                story: story,
                userId: userId,
                viewModel: viewModel,
                errorMessage: $errorMessage,
                showingErrorToast: $showingErrorToast
            )
            
            StoryTabView(selectedTab: $selectedTab)
                .padding(.top, 2)
            
            Divider()
            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    if selectedTab == 0 {
                        StoryStreamView
                    } else if selectedTab == 1 {
                        StoryRolesListView
                    }
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .navigationTitle("故事")
        .task {
            if viewModel.storyboards == nil {
                await viewModel.fetchStory(withBoards: true)
            }
        }
        .overlay(
            Group {
                if showingErrorToast {
                    ToastView(message: errorMessage ?? "")
                        .animation(.easeInOut)
                        .transition(.move(edge: .top))
                }
            }
        )
        .animation(.spring(), value: showingParticipants)
        .alert("操作失败", isPresented: $showingErrorAlert) {
            Button("确定", role: .cancel) {
                showingErrorAlert = false
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var StoryRolesListView: some View {
        VStack {
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(2.0)
                            .padding()
                        Text("加载中......")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
            } else if let roles = viewModel.storyRoles, !roles.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(roles, id: \.role.roleID) { role in
                            RoleCard(role: role,userid: self.userId,viewModel: self.viewModel)
                        }
                    }
                }
            } else {
                // 角色列表为空，显示创建新角色的按钮
                VStack {
                    Spacer()
                    Button(action: {
                        isShowingNewRole = true
                    }) {
                        VStack {
                            Image(systemName: "plus")
                                .font(.system(size: 30))
                                .foregroundColor(Color.theme.tertiaryText)
                        }
                        .frame(width: 120, height: 120)
                        .background(Color.theme.tertiaryBackground)
                        .cornerRadius(12)
                    }
                    Text("创建新的角色")
                        .font(.system(size: 16))
                        .foregroundColor(Color.theme.secondaryText)
                        .padding(.top, 8)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear{
            Task{
                await self.viewModel.getStoryRoles(storyId: self.storyId, userId: self.userId)
            }
        }
        .sheet(isPresented: $isShowingNewRole) {
            NavigationView {
                NewStoryRole(
                    storyId: self.storyId,
                    userId: self.userId,
                    viewModel: StoryDetailViewModel(story: story, storyId: storyId, userId: userId),
                )
            }
        }
    }
    
    private var StoryStreamView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if let boards = viewModel.storyboards, !boards.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(boards, id: \.id) { board in
                            NavigationLink(destination: StoryBoardView(
                                board: board,
                                userId: userId,
                                groupId: self.viewModel.story?.storyInfo.groupID ?? 0,
                                storyId: storyId,
                                viewModel: self.viewModel
                            )) {
                                StoryBoardCellView(
                                    board: board,
                                    userId: userId,
                                    groupId: self.viewModel.story?.storyInfo.groupID ?? 0,
                                    storyId: storyId,
                                    viewModel: self.viewModel
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } else {
                VStack {
                    Spacer()
                    Button(action: {
                        isShowingNewStoryBoard = true
                    }) {
                        VStack {
                            Image(systemName: "plus")
                                .font(.system(size: 30))
                                .foregroundColor(Color.theme.tertiaryText)
                        }
                        .frame(width: 120, height: 120)
                        .background(Color.theme.tertiaryBackground)
                        .cornerRadius(12)
                    }
                    Text("创建新的故事板")
                        .font(.system(size: 16))
                        .foregroundColor(Color.theme.secondaryText)
                        .padding(.top, 8)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(.systemBackground))
        .fullScreenCover(isPresented: $isShowingNewStoryBoard) {
            NavigationStack{
                NewStoryBoardView(
                    userId: userId,
                    storyId: storyId,
                    boardId: -1,
                    prevBoardId: 0,
                    viewModel: viewModel,
                    roles: [StoryRole](),
                    isPresented: $isShowingNewStoryBoard,
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            // 关闭当前 NavigationStack
                            isShowingNewStoryBoard = false
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                Text("返回")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
                .navigationTitle("故事的开始")
                .navigationBarTitleDisplayMode(.inline)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isShowingNewStoryBoard)
                .onDisappear {
                    Task {
                        //await refreshGroupData()
                    }
                }
            }
            
        }
    }
    
    private func generateStory() {
        isGenerating = true
        errorMessage = nil
        Task { @MainActor in
            let result = await self.viewModel.genStory(storyId: self.storyId, userId: self.userId)
            
            if let error = result.1 {
                self.errorMessage = error.localizedDescription
                self.generatedStory = nil
            } else {
                self.generatedStory = result.0
                self.errorMessage = nil
            }
            
            self.isGenerating = false
        }
    }
    
    private func getGenerateStory() {
        errorMessage = nil
        //DispatchQueue.global().asyncAfter(deadline: .now() + 30) {
            Task { @MainActor in
                let result = await self.viewModel.getGenStory(storyId: self.storyId, userId: self.userId)
                if let error = result.1 {
                    self.errorMessage = error.localizedDescription
                    self.generatedStory = nil
                } else {
                    self.generatedStory = result.0
                    self.errorMessage = nil
                }
            }
        //}
    }
    
    private func formatDate(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return DateFormatter.shortDate.string(from: date)
    }
    
    // 添加 Toast 视图
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

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

// Story Tab View
struct StoryTabView: View {
    @Binding var selectedTab: Int64
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach([0, 1], id: \.self) { tab in
                Button(action: { selectedTab = Int64(tab) }) {
                    VStack(spacing: 8) {
                        Text(tab == 0 ? "故事" : "人物")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(selectedTab == Int64(tab) ? Color.theme.primaryText : Color.theme.tertiaryText)
                        
                        Rectangle()
                            .fill(selectedTab == Int64(tab) ? Color.theme.accent : Color.clear)
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

struct StorySubViewInteractionButton: View {
    let icon: String
    let count: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(count)
                    .font(.system(size: 14))
            }
            .foregroundColor(color)
        }
    }
}

// Story Interaction Button
struct StoryInteractionButton: View {
    let count: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(count)
                    .font(.system(size: 14))
            }
            .foregroundColor(color)
        }
    }
}

// MARK: - Story Header View
private struct StoryHeaderView: View {
    let story: Story
    let userId: Int64
    @ObservedObject var viewModel: StoryViewModel
    @Binding var errorMessage: String?
    @Binding var showingErrorToast: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 用户信息部分
            NavigationLink(destination: StoryDetailView(storyId: story.storyInfo.id, story: story, userId: userId)) {
                UserInfoSection(story: story)
            }
            
            // 故事简介部分
            StoryDescriptionSection(description: story.storyInfo.origin)
            
            // 交互按钮栏
            InteractionButtonsSection(
                story: story,
                userId: userId,
                viewModel: viewModel,
                errorMessage: $errorMessage,
                showingErrorToast: $showingErrorToast
            )
        }
        .padding(16)
        .background(Color(.systemBackground))
    }
}

// MARK: - User Info Section
private struct UserInfoSection: View {
    let story: Story
    
    var body: some View {
        HStack(spacing: 12) {
            KFImage(URL(string: convertImagetoSenceImage(url: story.storyInfo.avatar, scene: .small)))
                .cacheMemoryOnly()
                .fade(duration: 0.25)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 66, height: 66)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(story.storyInfo.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(formatDate(timestamp: story.storyInfo.ctime))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}

// MARK: - Story Description Section
private struct StoryDescriptionSection: View {
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(description)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .lineLimit(3)
        }
    }
}

// MARK: - Interaction Buttons Section
private struct InteractionButtonsSection: View {
    let story: Story
    let userId: Int64
    @ObservedObject var viewModel: StoryViewModel
    @Binding var errorMessage: String?
    @Binding var showingErrorToast: Bool
    
    var body: some View {
        HStack(spacing: 24) {
            // 点赞按钮
            StoryInteractionButton(
                count: "\(story.storyInfo.likeCount)",
                icon: story.storyInfo.currentUserStatus.isLiked  ? "heart.fill" : "heart",
                color: .red ,
                action: handleLike
            )
            
            // 关注按钮
            StoryInteractionButton(
                count: "\(story.storyInfo.followCount)",
                icon:  story.storyInfo.currentUserStatus.isFollowed  ?"bell.fill":"bell",
                color: .blue,
                action: handleWatch
            )
            
            // 参与人员数
            StoryInteractionButton(
                count: "\(story.storyInfo.totalMembers)",
                icon: "person.bust",
                color: .blue,
                action: {
                    
                }
            )
            
            // 角色数
            StoryInteractionButton(
                count: "\(story.storyInfo.totalRoles)",
                icon: "person.text.rectangle",
                color: .blue,
                action: {
                    
                }
            )
            
            // 故事版数
            StoryInteractionButton(
                count: "\(story.storyInfo.totalBoards)",
                icon: "list.clipboard",
                color: .blue,
                action: {
                    
                }
            )
        }
        .padding(.top, 4)
    }
    
    private func handleLike() {
        Task {
            if story.storyInfo.currentUserStatus.isLiked {
                if let err = await viewModel.unlikeStory(storyId: story.storyInfo.id, userId: userId) {
                    await showError(err.localizedDescription)
                } else {
                    story.storyInfo.currentUserStatus.isLiked = false
                    viewModel.story?.storyInfo.likeCount = story.storyInfo.likeCount - 1
                }
            }else{
                if let err = await viewModel.likeStory(storyId: story.storyInfo.id, userId: userId) {
                    await showError(err.localizedDescription)
                } else {
                    story.storyInfo.currentUserStatus.isLiked = true
                    viewModel.story?.storyInfo.likeCount = story.storyInfo.likeCount + 1
                }
            }
            
        }
    }
    
    private func handleWatch() {
        if story.storyInfo.currentUserStatus.isFollowed {
            Task {
                if story.storyInfo.currentUserStatus.isFollowed {
                    if let err = await viewModel.unlikeStory(storyId: story.storyInfo.id, userId: userId) {
                        await showError(err.localizedDescription)
                    } else {
                        viewModel.story?.storyInfo.followCount = story.storyInfo.followCount - 1
                        viewModel.story?.storyInfo.currentUserStatus.isFollowed = false
                    }
                }else{
                    if let err = await viewModel.likeStory(storyId: story.storyInfo.id, userId: userId) {
                        await showError(err.localizedDescription)
                    } else {
                        viewModel.story?.storyInfo.followCount = story.storyInfo.followCount - 1
                        viewModel.story?.storyInfo.currentUserStatus.isFollowed = false
                    }
                }
            }
        }
    }
    
    private func showError(_ message: String) async {
        await MainActor.run {
            errorMessage = message
            showingErrorToast = true
            // 2秒后自动隐藏
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showingErrorToast = false
            }
        }
    }
}

// 角色卡片视图
struct RoleCard: View {
    let role: StoryRole
    let userid: Int64
    @State var viewModel: StoryViewModel
    @State private var showingDetail = false
    init(role: StoryRole, userid: Int64,viewModel: StoryViewModel) {
        self.role = role
        self.userid = userid
        self.viewModel = viewModel
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 角色信息区域 - 添加点击手势
            Button(action: {
                showingDetail = true
            }) {
                HStack(alignment: .top, spacing: 12) { // 改为顶部对齐
                    // 角色头像
                    KFImage(URL(string: convertImagetoSenceImage(url: role.role.characterAvatar, scene: .small)))
                        .cacheMemoryOnly()
                        .fade(duration: 0.25)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // 右侧信息区域
                    VStack(alignment: .leading, spacing: 12) { // 增加间距
                        // 1. 角色名称
                        Text(role.role.characterName)
                            .font(.system(size: 20, weight: .semibold)) // 增大字号
                            .foregroundColor(Color.theme.primaryText)
                            .lineLimit(1)
                        
                        // 2. 角色描述
                        Text(role.role.characterDescription)
                            .font(.system(size: 14))
                            .foregroundColor(Color.theme.secondaryText)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                        
                        Spacer() // 添加弹性空间
                        
                        // 3. 创建者信息
                        HStack(spacing: 8) {
                            // 创建者头像
                            KFImage(URL(string: convertImagetoSenceImage(url: role.role.creator.avatar, scene: .small)))
                                .cacheMemoryOnly()
                                .fade(duration: 0.25)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 16, height: 16)
                                .clipShape(Circle())
                            
                            Text("创建者: \(role.role.creator.name)")
                                .font(.system(size: 12))
                                .foregroundColor(Color.theme.tertiaryText)
                            
                            Spacer()
                            
                            Text(formatDate(timestamp: role.role.ctime))
                                .font(.system(size: 12))
                                .foregroundColor(Color.theme.tertiaryText)
                        }
                    }
                    .frame(height: 120, alignment: .top) // 固定高度，确保与头像等高
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // 交互栏
            HStack(spacing: 24) {
                // 喜欢按钮
                StorySubViewInteractionButton(
                    icon: self.role.role.currentUserStatus.isLiked ? "heart.fill" : "heart",
                    count: "\(role.role.likeCount)",
                    color: self.role.role.currentUserStatus.isLiked ? Color.red: Color.theme.tertiaryText,
                    action: {
                        Task{
                            if self.role.role.currentUserStatus.isLiked{
                                await self.viewModel.unlikeStoryRole(roleId: self.role.role.roleID)
                                self.role.role.currentUserStatus.isLiked = false
                                self.role.role.likeCount -= 1
                            }else{
                                await self.viewModel.likeStoryRole(roleId: self.role.role.roleID)
                                self.role.role.currentUserStatus.isLiked = true
                                self.role.role.likeCount += 1
                            }
                        }
                    }
                )
                
                // 关注按钮
                StorySubViewInteractionButton(
                    icon: self.role.role.currentUserStatus.isFollowed ?  "bell.fill":"bell",
                    count: "\(role.role.followCount)",
                    color: self.role.role.currentUserStatus.isFollowed ? Color.red: Color.theme.tertiaryText,
                    action: {
                        Task{
                            if self.role.role.currentUserStatus.isFollowed{
                                await self.viewModel.unfollowStoryRole(roleId: self.role.role.roleID)
                                self.role.role.currentUserStatus.isFollowed = false
                                self.role.role.followCount -= 1
                            }else{
                                await self.viewModel.followStoryRole(roleId: self.role.role.roleID)
                                self.role.role.currentUserStatus.isFollowed = true
                                self.role.role.followCount += 1
                            }
                        }
                    }
                )

                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(Color.theme.secondaryBackground)
        .navigationDestination(isPresented: $showingDetail) {
            StoryRoleDetailView(
                roleId: role.role.roleID,
                userId: userid,
                role: role
            )
        }
        Divider()
    }
    
    private func formatDate(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// 参与者头像组件
private struct ParticipantAvatar: View {
    let avatarUrl: String
    let isCreator: Bool
    
    var body: some View {
        KFImage(URL(string: convertImagetoSenceImage(url: avatarUrl, scene: .small)))
            .cacheMemoryOnly()
            .fade(duration: 0.25)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        isCreator ? Color.theme.accent.opacity(0.3) : Color.clear,
                        lineWidth: 2
                    )
            )
            .background(
                isCreator ? Color.theme.accent.opacity(0.1) : Color.clear
            )
            .clipShape(Circle())
    }
}

// 参与者项组件
private struct ParticipantItem: View {
    let member: User
    let isCreator: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ParticipantAvatar(avatarUrl: member.avatar, isCreator: isCreator)
            
            Text(member.name)
                .font(.system(size: 16))
                .foregroundColor(.theme.primaryText)
            
            Spacer()
            
            if isCreator {
                Text("创建者")
                    .font(.system(size: 12))
                    .foregroundColor(.theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.theme.accent.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 16)
    }
}

// 参与者列表组件
private struct ParticipantsList: View {
    let story: Story
    @ObservedObject var viewModel: StoryViewModel
    let userId: Int64
    let storyId: Int64
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var members: [User] = []
    
    init(story: Story, viewModel: StoryViewModel, userId: Int64, storyId: Int64, members: [User] = []) {
        self.story = story
        self.viewModel = viewModel
        self.userId = userId
        self.storyId = storyId
        self.members = members
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                Text("加载中...")
                    .foregroundColor(.theme.secondaryText)
                    .padding(.top, 8)
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                Text(error)
                    .foregroundColor(.theme.error)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else if members.isEmpty {
                Spacer()
                Text("暂无参与者")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.theme.secondaryText)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(members, id: \.userID) { member in
                            ParticipantItem(
                                member: member,
                                isCreator: member.userID == story.storyInfo.creatorID
                            )
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
        }
        .task {
            await loadParticipants()
        }
    }
    
    private func loadParticipants() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 直接调用 viewModel 方法并使用其返回类型
            let (users, error) = await viewModel.getStoryMembers(storyId: storyId, userId: userId)
            
            if let error = error {
                errorMessage = error.localizedDescription
            } else if let users = users {
                members = users
            } else {
                errorMessage = "获取参与者失败"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// 标题栏组件
private struct ParticipantsHeader: View {
    let storyName: String
    let onClose: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            // 标题文本居中
            Image(systemName: "person.text.rectangle")
                    .font(.system(size: 16))
            Text("\(storyName)的参与者")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.theme.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            
            // 关闭按钮放在右上角
            VStack {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.theme.primaryText)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                Spacer()
            }
        }
        .frame(height: 44)
        .background(Color.theme.secondaryBackground)
    }
}

// 主视图组件
struct StoryParticipantsView: View {
    let story: Story
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: StoryViewModel
    let userId: Int64
    let storyId: Int64
    
    var body: some View {
        VStack(spacing: 0) {
            ParticipantsHeader(
                storyName: story.storyInfo.name,
                onClose: { isPresented = false }
            )
            
            ParticipantsList(
                story: story,
                viewModel: viewModel,
                userId: userId,
                storyId: storyId,
                members: [User]()
            )
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height * 0.6) // 使用屏幕高度的60%
        .background(Color.theme.background)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}
