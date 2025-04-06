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
    let storyboard: StoryBoardActive
    let userId: Int64
    let viewModel: FeedViewModel
    @Binding var currentSceneIndex: Int
    let dismiss: DismissAction
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                StoryboardHeaderView(
                    storyboard: storyboard,
                    dismiss: dismiss
                )
                
                StoryboardStatsView(storyboard: storyboard)
                
                StoryboardSummaryDetailsView(
                    storyboard: storyboard,
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
            
            VStack(alignment: .leading, spacing: 4) {
                Text(storyboard.boardActive.storyboard.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.theme.primaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Stats View
private struct StoryboardStatsView: View {
    let storyboard: StoryBoardActive
    
    var body: some View {
        HStack(spacing: 24) {
            // 总点赞数
            StatItem(
                count: Int(storyboard.boardActive.totalLikeCount),
                title: "点赞",
                icon: "heart.fill"
            )
            
            // 总评论数
            StatItem(
                count: Int(storyboard.boardActive.totalCommentCount),
                title: "评论",
                icon: "heart.fill"
            )
            
            // 总分支数
            StatItem(
                count: Int(storyboard.boardActive.totalForkCount),
                title: "分支",
                icon: "heart.fill"
            )
        }
        .padding(.vertical, 16)
        .background(Color.theme.secondaryBackground)
    }
}

// MARK: - Details View
private struct StoryboardSummaryDetailsView: View {
    let storyboard: StoryBoardActive
    let userId: Int64
    let viewModel: FeedViewModel
    @Binding var currentSceneIndex: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 故事板标题和内容
            Text(storyboard.boardActive.storyboard.title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.theme.primaryText)
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
            
            // 交互按钮
            InteractionButtonsView(
                storyboard: storyboard,
                userId: userId,
                viewModel: viewModel
            )
            
            // 评论列表
            CommentListView(
                storyId: storyboard.boardActive.storyboard.storyID,
                storyboardId: storyboard.boardActive.storyboard.storyBoardID,
                userId: userId
            )
        }
        .padding(.top, 16)
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
                    .padding(.bottom, 8)
                    
                    // 场景描述
                    let scene = scenes[currentIndex]
                    Text(scene.content)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
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
            KFImage(URL(string: firstUrl))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 400)
                .clipped()
        }
    }
}

// MARK: - Interaction Buttons View
private struct InteractionButtonsView: View {
    let storyboard: StoryBoardActive
    let userId: Int64
    let viewModel: FeedViewModel
    
    var body: some View {
        HStack(spacing: 24) {
            // 点赞按钮
            InteractionButton(
                icon: storyboard.boardActive.isliked ? "heart.fill" : "heart",
                count: Int(storyboard.boardActive.totalLikeCount),
                isActive: storyboard.boardActive.isliked
            ) {
                Task {
                    await viewModel.likeStoryBoard(
                        storyId: storyboard.boardActive.storyboard.storyID,
                        boardId: storyboard.boardActive.storyboard.storyBoardID,
                        userId: userId
                    )
                }
            }
            
            // 评论按钮
            InteractionButton(
                icon: "bubble.left",
                count: Int(storyboard.boardActive.totalCommentCount),
                isActive: false
            ) {
                // 评论操作
            }
            
            // 分支按钮
            InteractionButton(
                icon: "arrow.triangle.branch",
                count: Int(storyboard.boardActive.totalForkCount),
                isActive: false
            ) {
                // 分支操作
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

