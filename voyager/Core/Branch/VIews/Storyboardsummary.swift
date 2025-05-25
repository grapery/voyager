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
        .navigationBarHidden(true)
        .onAppear {
            if currentStoryboard == nil {
                loadStoryboard()
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
            HStack(spacing: 4) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                        .imageScale(.large)
                }
                Spacer()
                // 故事板标题和内容
                HStack(alignment: .center) {
                    Text(storyboard.storyboard.title)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.theme.primaryText)
                }
                .padding(.horizontal, 16)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // 新的故事信息和创建者信息区域
            HStack(alignment: .center) {
                // 故事图片+title（左对齐）
                HStack(spacing: 8) {
                    KFImage(URL(string: convertImagetoSenceImage(url: storyboard.summary.storyAvatar, scene: .small)))
                        .cacheMemoryOnly()
                        .fade(duration: 0.25)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                    Text(String(storyboard.summary.storyTitle.prefix(5)))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.theme.primaryText)
                        .lineLimit(1)
                }
                // 左侧内容靠左
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 创建者信息靠右
                HStack(spacing: 4) {
                    Label("创建者:", systemImage: "person.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.theme.secondaryText)
                    KFImage(URL(string: storyboard.creator.userAvatar))
                        .cacheMemoryOnly()
                        .fade(duration: 0.25)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                    Text(storyboard.creator.userName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.theme.primaryText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.top, 8)
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
            Text(storyboard.storyboard.content)
                .font(.system(size: 14))
                .foregroundColor(.theme.secondaryText)
                .padding(.horizontal, 16)
            
            // 场景列表
            ScenesListView(
                scenes: storyboard.storyboard.sences.list,
                currentIndex: currentSceneIndex
            )
            .padding(.horizontal, 16)
            
            
            HStack(spacing: 4) {
                // 交互按钮
                InteractionButtonsView(
                    storyboard: storyboard,
                    userId: userId,
                    viewModel: viewModel
                )
            }
            .frame( alignment: .leading)
            .padding(.horizontal, 16)
            // 创建时间
            HStack(spacing: 4) {
                Spacer()
                    .font(.system(size: 12))
                    .foregroundColor(.theme.secondaryText)
                Text(formatCtime(storyboard.storyboard.ctime))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.theme.primaryText)
                    .lineLimit(1)
            }
            .frame(alignment: .trailing)
            .padding(.horizontal, 16)
            
            Divider()
                .padding(.vertical, 4)
            
            // 评论列表
            CommentListView(
                storyId: storyboard.storyboard.storyID,
                storyboardId: storyboard.storyboard.storyBoardID,
                userId: userId,
                totalCommentNum: Int(storyboard.totalCommentCount)
            )
            .padding(.horizontal, 16)
        }
        .padding(.top, 12)
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
                                        .fill(Color.white)
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
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
        viewModel: FeedViewModel
    ) -> some View {
        HStack(spacing: 24) {
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
                color: Color.red
            )
            
            // 评论按钮
            InteractionButton(
                icon: "bubble.left",
                count: Int(storyboard.totalCommentCount),
                isActive: false,
                action: {
                    print("add some comment")
                },
                color: Color.red
            )
            
            // 分支按钮
            InteractionButton(
                icon: "arrow.triangle.branch",
                count: Int(storyboard.totalForkCount),
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
    
    private func formatCtime(_ ctime: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(ctime))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
        return formatter.string(from: date)
    }
}

