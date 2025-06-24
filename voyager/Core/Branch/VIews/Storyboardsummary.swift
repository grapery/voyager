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
    @State private var isLoading = false
    @State private var errorMessage: String = ""
    @State private var showComments: Bool = false
    @State private var showBoardForks: Bool = false
    
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
                if isLoading {
                    ProgressView()
                } else if let storyboard = currentStoryboard {
                    StoryboardContentView(
                        storyboard: storyboard,
                        userId: userId,
                        viewModel: viewModel,
                        currentSceneIndex: $currentSceneIndex,
                        dismiss: dismiss
                    )
                } else {
                    Text(errorMessage.isEmpty ? "无法加载故事板信息" : errorMessage)
                        .foregroundColor(.red)
                }
            }
            .background(Color.theme.background)
            .onAppear {
                if currentStoryboard == nil {
                    loadStoryboard()
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    }
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
            VStack(alignment: .leading, spacing: 12) {
                CreatorHeaderView(creator: storyboard.creator, onFollow: {})
                
                StoryboardSummaryDetailsView(
                    storyboard: storyboard,
                    userId: userId,
                    viewModel: viewModel,
                    currentSceneIndex: currentSceneIndex
                )
            }
            .padding(.horizontal)
        }
        .background(Color.theme.background)
    }

    // MARK: - CreatorHeaderView
    private func CreatorHeaderView(creator: Common_StoryBoardActiveUser, onFollow: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            KFImage(URL(string: convertImagetoSenceImage(url: creator.userAvatar, scene: .small)))
                .resizable().scaledToFill().frame(width: 44, height: 44).clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(creator.userName).font(.system(size: 15, weight: .medium))
                Text("用户比较神秘，没有描述信息").font(.system(size: 13)).foregroundColor(.secondary).lineLimit(1)
            }
            
            Spacer()
            
            Button(action: onFollow) {
                Text("+ 关注")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Color.blue).clipShape(Capsule())
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
        VStack(alignment: .leading, spacing: 10) {
            Text(storyboard.storyboard.title)
                .font(.system(size: 20, weight: .bold))

            Text(storyboard.storyboard.content)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineSpacing(5)

            ScenesListView(scenes: storyboard.storyboard.sences.list, currentIndex: currentSceneIndex)

            InteractionButtonsView(
                storyboard: storyboard,
                userId: userId,
                viewModel: viewModel,
                onShowComments: { self.showComments = true }
            )

            Divider()

            Text(formatTimestamp(storyboard.storyboard.ctime))
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                KFImage(URL(string: convertImagetoSenceImage(url: storyboard.summary.storyAvatar, scene: .small)))
                    .resizable().frame(width: 24, height: 24).clipShape(Circle())
                Text("故事 · \(storyboard.summary.storyTitle)")
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 6).padding(.vertical, 4)
            .background(Color(UIColor.systemGray6))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.theme.border, lineWidth: 1)
            )
        }
        .sheet(isPresented: $showComments) {
            CommentListView(
                storyId: storyboard.storyboard.storyID,
                storyboardId: storyboard.storyboard.storyBoardID,
                userId: userId, userAvatarURL: defaultAvator,
                totalCommentNum: Int(storyboard.totalCommentCount)
            )
        }
        .fullScreenCover(isPresented: $showBoardForks) {
            StoryForkListView(
                initialStoryboardId: storyboard.storyboard.storyBoardID,
                userId: userId
            )
        }
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
    
    private func formatTimestamp(_ ctime: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(ctime))
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)

        if let day = components.day, day > 0 { return "\(day)天前" }
        if let hour = components.hour, hour > 0 { return "\(hour)小时前" }
        if let minute = components.minute, minute > 0 { return "\(minute)分钟前" }
        return "刚刚"
    }
}

