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
    @State public var story: Story
    
    var userId: Int64
    
    // 新增的状态变量
    @State private var generatedStory: Common_RenderStoryDetail?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    
    @State private var isShowingNewStoryBoard = false
    @State private var isShowingCommentView = false
    @State private var isForkingStory = false
    @State private var isLiked = false
    
    @State private var selectedBoard: StoryBoard?
    @State private var isShowingBoardDetail = false
    
    // 添加错误处理相关状态
    @State private var showingErrorToast = false
    @State private var showingErrorAlert = false
    
    init(story: Story, userId: Int64) {
        self.story = story
        self.userId = userId
        self.storyId = story.storyInfo.id
        _viewModel = StateObject(wrappedValue: StoryViewModel(story: story, userId: userId))
    }
    
    
    
    var body: some View {
        VStack(spacing: 0) {
            // Story Info Header
            VStack(alignment: .leading, spacing: 12) {
                // 用户信息部分
                NavigationLink(destination: StoryDetailView(storyId: self.storyId, story: self.viewModel.story!, userId: self.userId)) {
                    HStack(spacing: 12) {
                        KFImage(URL(string: self.viewModel.story?.storyInfo.avatar ?? ""))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 66, height: 66)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(self.viewModel.story?.storyInfo.name ?? "")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            if let createdAt = self.viewModel.story?.storyInfo.ctime {
                                Text(formatDate(timestamp: createdAt))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                }
                
                // 故事简介部分
                VStack(alignment: .leading, spacing: 8) {
                    Text(self.viewModel.story?.storyInfo.origin ?? "")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
                
                // 交互按钮栏
                HStack(spacing: 24) {
                    StoryInteractionButton(
                        count: "10",
                        icon: "heart",
                        color: .red,
                        action: {
                            // 处理点赞事件
                            print("Like button tapped")
                            Task {
                                let err = await self.viewModel.likeStory(storyId: self.storyId, userId: self.userId)
                                if let error = err {
                                    DispatchQueue.main.async {
                                        self.errorMessage = error.localizedDescription
                                        self.showingErrorToast = true
                                        // 2秒后自动隐藏
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            self.showingErrorToast = false
                                        }
                                    }
                                }
                            }
                        }
                    )
                    
                    StoryInteractionButton(
                        count: "1",
                        icon: "bell",
                        color: .blue,
                        action: {
                            // 处理关注事件
                            print("Follow button tapped")
                            Task {
                                let err = await self.viewModel.watchStory(storyId: self.storyId, userId: self.userId)
                                if let error = err {
                                    DispatchQueue.main.async {
                                        self.errorMessage = error.localizedDescription
                                        self.showingErrorToast = true
                                        // 2秒后自动隐藏
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            self.showingErrorToast = false
                                        }
                                    }
                                }
                            }
                        }
                    )
                    
                    StoryInteractionButton(
                        count: "分享",
                        icon: "square.and.arrow.up",
                        color: .green,
                        action: {
                            // 处理分享事件
                            print("Share button tapped")
                            Task {
                                let err = await self.viewModel.likeStory(storyId: self.storyId, userId: self.userId)
                                if let error = err {
                                    DispatchQueue.main.async {
                                        self.errorMessage = error.localizedDescription
                                        self.showingErrorAlert = true
                                    }
                                }
                            }
                        }
                    )
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(Color(.systemBackground))
            
            StoryTabView(selectedTab: $selectedTab)
                .padding(.top, 2) // 减少顶部间距
            Divider()
            GeometryReader { geometry in
                    VStack(spacing: 0) {
                        if selectedTab == 0 {
                            storyLineView
                        }else if selectedTab == 1 {
                            storyRolesListView
                        }
                    }
                    .frame(minHeight: geometry.size.height)
            }
            .padding(.top, 0) // 移除 GeometryReader 的顶部间距
        }
        .navigationTitle("故事")
        .task {
            if viewModel.storyboards == nil {
                await viewModel.fetchStory(withBoards: true)
                print("task fetchStory :",viewModel.storyboards as Any)
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
        .alert("操作失败", isPresented: $showingErrorAlert) {
            Button("确定", role: .cancel) {
                showingErrorAlert = false
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var storyRolesListView: some View {
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
            } else if let roles = viewModel.storyRoles {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(roles, id: \.role.roleID) { role in
                            RoleCard(role: role,userid: self.userId)
                        }
                    }
                }
            } else {
                Text("暂无角色")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .onAppear{
            Task{
                await self.viewModel.getStoryRoles(storyId: self.storyId, userId: self.userId)
            }
        }
    }
    
    private var storyLineView: some View {
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
                                HStack{
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
        .sheet(isPresented: $isShowingNewStoryBoard) {
            NavigationView {
                NewStoryBoardView(
                    userId: userId,
                    storyId: storyId,
                    boardId: -1,
                    prevBoardId: 0,
                    viewModel: viewModel,
                    roles: [StoryRole](),
                    isPresented: $isShowingNewStoryBoard
                )
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


// 角色卡片视图
struct RoleCard: View {
    let role: StoryRole
    let userid: Int64
    @State private var isLiked = false
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 角色信息区域 - 添加点击手势
            Button(action: {
                showingDetail = true
            }) {
                HStack(alignment: .top, spacing: 12) { // 改为顶部对齐
                    // 角色头像
                    KFImage(URL(string: role.role.characterAvatar))
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
                            KFImage(URL(string: defaultAvator))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 16, height: 16)
                                .clipShape(Circle())
                            
                            Text("创建者ID: \(role.role.creatorID)")
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
                    icon: isLiked ? "heart.fill" : "heart",
                    count: "\(role.role.likeCount)",
                    color: isLiked ? Color.theme.error : Color.theme.tertiaryText,
                    action: {
                        withAnimation(.spring()) {
                            isLiked.toggle()
                        }
                    }
                )
                
                // 关注按钮
                StorySubViewInteractionButton(
                    icon: "person.badge.plus",
                    count: "关注",
                    color: Color.theme.tertiaryText,
                    action: {
                        // TODO: 处理关注事件
                    }
                )
                
                // 分享按钮
                StorySubViewInteractionButton(
                    icon: "square.and.arrow.up",
                    count: "分享",
                    color: Color.theme.tertiaryText,
                    action: {
                        // TODO: 处理分享事件
                    }
                )
                
                // 聊天按钮
                StorySubViewInteractionButton(
                    icon: "message",
                    count: "聊天",
                    color: Color.theme.tertiaryText,
                    action: {
                        // TODO: 处理聊天事件
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
