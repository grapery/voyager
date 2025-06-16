//
//  Storyboardsummary.swift
//  voyager
//
//  Created by grapestree on 2025/4/5.
//

import SwiftUI
import Kingfisher
import Combine
import AVKit

struct StoryboardSummary: View {
    let storyBoardId: Int64
    let userId: Int64
    @ObservedObject var viewModel: FeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentSceneIndex = 0
    @State private var isLoading = true
    @State private var errorMessage: String = ""
    @State private var showComments: Bool = false
    @State private var showBoardForks: Bool = false
    
    // 添加计算属性来获取当前故事板
    private var currentStoryboard: Common_StoryBoardActive? {
        viewModel.storyBoardActives.first { $0.storyboard.storyBoardID == storyBoardId }
    }
    
    init(storyBoardId: Int64, userId: Int64, viewModel: FeedViewModel) {
        self.storyBoardId = storyBoardId
        self.userId = userId
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let storyboard = currentStoryboard {
                    StoryboardContentView(
                        storyboard: storyboard,
                        userId: userId,
                        viewModel: viewModel,
                        currentSceneIndex: $currentSceneIndex,
                        dismiss: dismiss
                    )
                } else {
                    Text("无法加载故事板信息")
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .onAppear {
                if currentStoryboard == nil {
                    loadStoryboard()
                }
            }
        }
    }
    
    private func loadStoryboard() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let (storyboard, error) = await viewModel.fetchStoryboardDetail(storyboardId: storyBoardId)
                await MainActor.run {
                    if let error = error {
                        errorMessage = error.localizedDescription
                        isLoading = false
                        return
                    }
                    
                    if let storyboard = storyboard {
                        // 更新 viewModel 中的故事板数据
                        if let index = viewModel.storyBoardActives.firstIndex(where: { $0.storyboard.storyBoardID == storyBoardId }) {
                            viewModel.storyBoardActives[index] = storyboard.boardActive
                        } else {
                            viewModel.storyBoardActives.append(storyboard.boardActive)
                        }
                    } else {
                        errorMessage = "无法加载故事板信息"
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - StoryboardContentView
    private func StoryboardContentView(
        storyboard: Common_StoryBoardActive,
        userId: Int64,
        viewModel: FeedViewModel,
        currentSceneIndex: Binding<Int>,
        dismiss: DismissAction
    ) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                StoryboardHeaderView(
                    storyboard: storyboard,
                    dismiss: dismiss
                )
                StoryboardSummaryDetailsView(
                    storyboard: storyboard,
                    userId: userId,
                    viewModel: viewModel,
                    currentSceneIndex: currentSceneIndex
                )
            }
        }
    }
    
    // MARK: - StoryboardHeaderView
    private func StoryboardHeaderView(
        storyboard: Common_StoryBoardActive,
        dismiss: DismissAction
    ) -> some View {
        VStack{
            HStack(alignment: .center) {
                // 故事板标题和内容
                HStack(alignment: .center) {
                    Text(storyboard.summary.storyTitle)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.theme.primaryText)
                }
                .padding(.horizontal, 16)
            }
        }
        
    }
    
    // MARK: - StoryboardSummaryDetailsView
    private func StoryboardSummaryDetailsView(
        storyboard: Common_StoryBoardActive,
        userId: Int64,
        viewModel: FeedViewModel,
        currentSceneIndex: Binding<Int>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack{
                Text(storyboard.storyboard.content)
                    .font(.system(size: 14))
                    .foregroundColor(.theme.secondaryText)
            }
            .frame( alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            
            // 场景列表
            ScenesListView(
                scenes: storyboard.storyboard.sences.list,
                currentIndex: currentSceneIndex
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            
            // 新的故事信息和创建者信息区域
            HStack(alignment: .center) {
                // 故事图片+title（左对齐）
                HStack(spacing: 8) {
                    KFImage(URL(string: convertImagetoSenceImage(url: storyboard.summary.storyAvatar, scene: .small)))
                        .cacheMemoryOnly()
                        .fade(duration: 0.25)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                    Text(String(storyboard.summary.storyTitle.prefix(5)))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.theme.primaryText)
                        .lineLimit(1)
                }
                // 左侧内容靠左
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                // 创建者信息靠右
                VStack{
                    HStack(spacing: 4) {
                        Label("创建者:", systemImage: "person.circle")
                            .font(.system(size: 8))
                            .foregroundColor(.theme.secondaryText)
                        KFImage(URL(string: storyboard.creator.userAvatar))
                            .cacheMemoryOnly()
                            .fade(duration: 0.25)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 8, height: 8)
                            .clipShape(Circle())
                        Text(storyboard.creator.userName)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.theme.primaryText)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    // 创建时间
                    HStack(spacing: 4) {
                        Spacer()
                            .font(.system(size: 8))
                            .foregroundColor(.theme.secondaryText)
                        Text(formatCtime(storyboard.storyboard.ctime))
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.theme.primaryText)
                            .lineLimit(1)
                        }
                        .frame(alignment: .trailing)
                        .padding(.horizontal, 8)
                    }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
           
            //HStack() {
                // 交互按钮
                InteractionButtonsView(
                    storyboard: storyboard,
                    userId: userId,
                    viewModel: viewModel,
                    onShowComments: { self.showComments = true }
                )
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .padding(.horizontal, 8)
            
            Divider()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            // 评论列表弹窗
            .sheet(isPresented: $showComments) {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Text("评论列表")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.theme.primaryText)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    CommentListView(
                        storyId: storyboard.storyboard.storyID,
                        storyboardId: storyboard.storyboard.storyBoardID,
                        userId: userId,
                        userAvatarURL: defaultAvator,
                        totalCommentNum: Int(storyboard.totalCommentCount)
                    )
                }
                .background(Color.theme.background)
                .presentationDetents([.medium, .large])
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - ScenesListView
    private func ScenesListView(
        scenes: [Common_StoryBoardSence],
        currentIndex: Binding<Int>
    ) -> some View {
        if scenes.isEmpty {
            return AnyView(EmptyView())
        } else {
            return AnyView(
                VStack {
                    ZStack(alignment: .bottom) {
                        TabView(selection: currentIndex) {
                            ForEach(Array(scenes.enumerated()), id: \.offset) { index, scene in
                                SceneView(scene: scene)
                                    .tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        
                        // 进度指示器
                        VStack(spacing: 8) {
                            // 进度线
                            HStack(spacing: 4) {
                                ForEach(0..<scenes.count, id: \.self) { index in
                                    Capsule()
                                        .fill(Color.theme.secondaryText).colorInvert()
                                        .frame(height: 4)
                                        .opacity(currentIndex.wrappedValue == index ? 1.0 : 0.3)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 4)
                            
                            // 场景描述
                            let scene = scenes[currentIndex.wrappedValue]
                            Text(scene.content)
                                .font(.system(size: 14))
                                .foregroundColor(Color.theme.secondaryText).colorInvert()
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                                .lineLimit(2)
                        }
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0),
                                    Color.black.opacity(0.5)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .frame(height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            )
        }
    }
    
    // MARK: - SceneView
    private func SceneView(scene: Common_StoryBoardSence) -> some View {
        if let data = scene.genResult.data(using: .utf8),
           let urls = try? JSONDecoder().decode([String].self, from: data),
           let firstUrl = urls.first {
            return AnyView(
                KFImage(URL(string: convertImagetoSenceImage(url: firstUrl, scene: .content)))
                    .cacheMemoryOnly()
                    .fade(duration: 0.25)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .clipped()
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    
    // MARK: - InteractionButtonsView
    private func InteractionButtonsView(
        storyboard: Common_StoryBoardActive,
        userId: Int64,
        viewModel: FeedViewModel,
        onShowComments: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            // 点赞按钮
            InteractionButton(
                icon: storyboard.storyboard.currentUserStatus.isLiked ? "heart.fill" : "heart",
                count: Int(storyboard.totalLikeCount),
                isActive: storyboard.storyboard.currentUserStatus.isLiked,
                action: {
                    Task {
                        if !storyboard.storyboard.currentUserStatus.isLiked {
                            if let error = await viewModel.likeStoryBoard(
                                storyId: storyboard.storyboard.storyID,
                                boardId: storyboard.storyboard.storyBoardID,
                                userId: userId
                            ) {
                                errorMessage = error.localizedDescription
                            } else {
                                // 更新本地状态
                                if let index = viewModel.storyBoardActives.firstIndex(where: { $0.storyboard.storyBoardID == storyboard.storyboard.storyBoardID }) {
                                    viewModel.storyBoardActives[index].storyboard.currentUserStatus.isLiked = true
                                    viewModel.storyBoardActives[index].totalLikeCount += 1
                                }
                            }
                        } else {
                            if let error = await viewModel.unlikeStoryBoard(
                                storyId: storyboard.storyboard.storyID,
                                boardId: storyboard.storyboard.storyBoardID,
                                userId: userId
                            ) {
                                errorMessage = error.localizedDescription
                            } else {
                                // 更新本地状态
                                if let index = viewModel.storyBoardActives.firstIndex(where: { $0.storyboard.storyBoardID == storyboard.storyboard.storyBoardID }) {
                                    viewModel.storyBoardActives[index].storyboard.currentUserStatus.isLiked = false
                                    viewModel.storyBoardActives[index].totalLikeCount -= 1
                                }
                            }
                        }
                    }
                },
                color: Color.theme.likeIcon
            )
            
            // 评论按钮
            InteractionButton(
                icon: "bubble.left",
                count: Int(storyboard.totalCommentCount),
                isActive: false,
                action: {
                    onShowComments()
                },
                color: Color.theme.commentedIcon
            )
            
            // 分支按钮
            InteractionButton(
                icon: "signpost.right.and.left",
                count: Int(storyboard.totalForkCount),
                isActive: false,
                action: {
                    self.showBoardForks = !self.showBoardForks
                },
                color: Color.theme.forkedIcon
            )
            
            Spacer()
        }
    }
    
    private func formatCtime(_ ctime: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(ctime))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
        return formatter.string(from: date)
    }
}

