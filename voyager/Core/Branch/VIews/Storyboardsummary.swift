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
    @StateObject private var viewModel: FeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentSceneIndex = 0
    @State private var storyBoardActive: StoryBoardActive?
    @State private var isLoading = true
    @State private var errorMessage: String = ""
    @State private var apiClient = APIClient()
    
    init(storyBoardId: Int64, userId: Int64, viewModel: FeedViewModel) {
        self.storyBoardId = storyBoardId
        self.userId = userId
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        Group {
            if let storyboard = storyBoardActive {
                StoryboardContentView(
                    storyboard: storyboard,
                    userId: userId,
                    viewModel: viewModel,
                    currentSceneIndex: $currentSceneIndex,
                    dismiss: dismiss
                )
            } else {
                LoadingErrorView(
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                    onRetry: loadStoryboard
                )
            }
        }
        .navigationBarHidden(true)
        .task {
            loadStoryboard()
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
                        self.storyBoardActive = storyboard
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
}

// MARK: - Loading and Error View
private struct LoadingErrorView: View {
    let isLoading: Bool
    let errorMessage: String
    let onRetry: () -> Void
    
    var body: some View {
        if isLoading {
            ProgressView()
        } else if !errorMessage.isEmpty {
            VStack {
                Text(errorMessage)
                    .foregroundColor(.red)
                Button("重试", action: onRetry)
            }
        }
    }
}

// MARK: - Main Content View
private struct StoryboardContentView: View {
    @State var storyboard: StoryBoardActive
    let userId: Int64
    let viewModel: FeedViewModel
    @Binding var currentSceneIndex: Int
    let dismiss: DismissAction
    
    init(storyboard: StoryBoardActive, userId: Int64, viewModel: FeedViewModel, currentSceneIndex: Binding<Int>, dismiss: DismissAction) {
        self.storyboard = storyboard
        self.userId = userId
        self.viewModel = viewModel
        self._currentSceneIndex = currentSceneIndex
        self.dismiss = dismiss
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                StoryboardHeaderView(
                    storyboard: storyboard,
                    dismiss: dismiss
                )
                StoryboardSummaryDetailsView(
                    storyboard: $storyboard,
                    userId: userId,
                    viewModel: viewModel,
                    currentSceneIndex: $currentSceneIndex
                )
            }
        }
    }
}

// MARK: - Header View
private struct StoryboardHeaderView: View {
    let storyboard: StoryBoardActive
    let dismiss: DismissAction
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primary)
                    .imageScale(.large)
            }
            
            // 用户信息
            HStack(spacing: 8) {
                // 故事头像
                KFImage(URL(string: convertImagetoSenceImage(url: storyboard.boardActive.summary.storyAvatar, scene: .small)))
                    .cacheMemoryOnly()
                    .fade(duration: 0.25)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                Text(storyboard.boardActive.summary.storyTitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.theme.primaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}


// MARK: - Details View
private struct StoryboardSummaryDetailsView: View {
    @Binding var storyboard: StoryBoardActive
    let userId: Int64
    let viewModel: FeedViewModel
    @Binding var currentSceneIndex: Int
    @State private var isShowingUserProfile = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 故事板标题和内容
            HStack{
                Text(storyboard.boardActive.storyboard.title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.theme.primaryText)
            }
            .padding(.horizontal, 16)
            
            Text(storyboard.boardActive.storyboard.content)
                .font(.system(size: 14))
                .foregroundColor(.theme.secondaryText)
                .padding(.horizontal, 16)
            
            // 场景列表
            ScenesListView(
                scenes: storyboard.boardActive.storyboard.sences.list,
                currentIndex: $currentSceneIndex
            )
            .padding(.horizontal, 16)
            
            HStack(spacing: 8) {
                // 交互按钮
                InteractionButtonsView(
                    storyboard: $storyboard,
                    userId: userId,
                    viewModel: viewModel
                )
                
                Spacer()
                
                // 创建者信息区域
                HStack(alignment: .center, spacing: 8) {
                    Label("创建者:", systemImage: "person.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.theme.secondaryText)
                    
                      Button(action: { isShowingUserProfile = true }) {
                        HStack(spacing: 4) {
                            KFImage(URL(string: storyboard.boardActive.creator.userAvatar))
                                .cacheMemoryOnly()
                                .fade(duration: 0.25)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                            Text("\(storyboard.boardActive.creator.userName)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.theme.primaryText)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            
            Divider()
                .padding(.vertical, 4)
            
            // 评论列表
            CommentListView(
                storyId: storyboard.boardActive.storyboard.storyID,
                storyboardId: storyboard.boardActive.storyboard.storyBoardID,
                userId: userId
            )
            .padding(.horizontal, 16)
        }
        .padding(.top, 12)
        .fullScreenCover(isPresented: $isShowingUserProfile) {
            NavigationView {
                UserProfileView(user: User(
                    userID: storyboard.boardActive.creator.userID,
                    name: storyboard.boardActive.creator.userName,
                    avatar: storyboard.boardActive.creator.userAvatar
                ))
                .navigationBarItems(leading: Button(action: {
                    isShowingUserProfile = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.theme.primaryText)
                })
            }
        }
    }
}

// MARK: - Scenes List View
private struct ScenesListView: View {
    let scenes: [Common_StoryBoardSence]
    @Binding var currentIndex: Int
    
    var body: some View {
        if !scenes.isEmpty {
            ZStack(alignment: .bottom) {
                TabView(selection: $currentIndex) {
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
                                .fill(Color.white)
                                .frame(height: 4)
                                .opacity(currentIndex == index ? 1.0 : 0.3)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                    
                    // 场景描述
                    let scene = scenes[currentIndex]
                    Text(scene.content)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
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
        }
    }
}

// MARK: - Scene View
private struct SceneView: View {
    let scene: Common_StoryBoardSence
    
    var body: some View {
        if let data = scene.genResult.data(using: .utf8),
           let urls = try? JSONDecoder().decode([String].self, from: data),
           let firstUrl = urls.first {
            KFImage(URL(string: convertImagetoSenceImage(url: firstUrl, scene: .content)))
                .cacheMemoryOnly()
                .fade(duration: 0.25)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 400)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .clipped()
        }
    }
}

// MARK: - Interaction Buttons View
private struct InteractionButtonsView: View {
    @Binding var storyboard: StoryBoardActive
    let userId: Int64
    let viewModel: FeedViewModel
    
    var body: some View {
        HStack(spacing: 24) {
            // 点赞按钮
            InteractionButton(
                icon: storyboard.boardActive.storyboard.currentUserStatus.isLiked ? "heart.fill" : "heart",
                count: Int(storyboard.boardActive.totalLikeCount),
                isActive: storyboard.boardActive.storyboard.currentUserStatus.isLiked,
                action: {
                    Task {
                        if !storyboard.boardActive.storyboard.currentUserStatus.isLiked {
                            await viewModel.likeStoryBoard(
                                storyId: storyboard.boardActive.storyboard.storyID,
                                boardId: storyboard.boardActive.storyboard.storyBoardID,
                                userId: userId
                            )
                            storyboard.boardActive.storyboard.currentUserStatus.isLiked = true
                            storyboard.boardActive.totalLikeCount = storyboard.boardActive.totalLikeCount + 1
                        }else{
                            await viewModel.unlikeStoryBoard(
                                storyId: storyboard.boardActive.storyboard.storyID,
                                boardId: storyboard.boardActive.storyboard.storyBoardID,
                                userId: userId
                            )
                            storyboard.boardActive.storyboard.currentUserStatus.isLiked = false
                            storyboard.boardActive.totalLikeCount = storyboard.boardActive.totalLikeCount - 1
                        }
                    }
                },
                color: Color.red
            )
            
            // 评论按钮
            InteractionButton(
                icon: "bubble.left",
                count: Int(storyboard.boardActive.totalCommentCount),
                isActive: false,
                action: {
                    print("add some comment")
                },
                color: Color.red
            )
            
            // 分支按钮
            InteractionButton(
                icon: "arrow.triangle.branch",
                count: Int(storyboard.boardActive.totalForkCount),
                isActive: false,
                action: {
                    print("add some comment")
                },
                color: Color.red
            )
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

