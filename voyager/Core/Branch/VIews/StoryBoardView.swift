//
//  StoryBoardView.swift
//  voyager
//
//  Created by grapestree on 2024/9/24.
//

import SwiftUI
import Kingfisher
import Combine

struct StoryBoardView: View {
    @State var board: StoryBoardActive?
    @State var userId: Int64
    @State var groupId: Int64
    @State var storyId: Int64
    @State private var currentSceneIndex = 0
    @State var viewModel: StoryViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var commentText = ""
    @State private var isLiked = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack(spacing: 12) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                        .imageScale(.large)
                }
                HStack(spacing: 8) {
                    KFImage(URL(string: convertImagetoSenceImage(url: (board?.boardActive.creator.userAvatar)!, scene: .small)))
                        .cacheMemoryOnly()
                        .fade(duration: 0.25)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text((board?.boardActive.creator.userName)!)
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                }
                Spacer()
                Button(action: {}) {
                    Text("关注")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.theme.error)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            // 内容区
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 标题和内容
                    Text(board?.boardActive.storyboard.title ?? "")
                        .font(.system(size: 16, weight: .medium))
                    Text(board?.boardActive.storyboard.content ?? "")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    // 图片区
                    if let scenes = board?.boardActive.storyboard.sences.list, !scenes.isEmpty {
                        ZStack(alignment: .bottom) {
                            TabView(selection: $currentSceneIndex) {
                                ForEach(Array(scenes.enumerated()), id: \.offset) { index, scene in
                                    if let data = scene.genResult.data(using: .utf8),
                                       let urls = try? JSONDecoder().decode([String].self, from: data),
                                       let firstUrl = urls.first {
                                        KFImage(URL(string: convertImagetoSenceImage(url: firstUrl, scene: .content)))
                                            .cacheMemoryOnly()
                                            .fade(duration: 0.25)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 400)
                                            .clipped()
                                            .tag(index)
                                    }
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            VStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    ForEach(0..<scenes.count, id: \.self) { index in
                                        Capsule()
                                            .fill(Color.white)
                                            .frame(height: 4)
                                            .opacity(currentSceneIndex == index ? 1.0 : 0.3)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                                let scene = scenes[currentSceneIndex]
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
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    // 交互栏
                    HStack(spacing: 8) {
                        Button(action: {
                            Task {
                                let err = await self.viewModel.likeStoryBoard(storyId: self.storyId, boardId: (self.board?.boardActive.storyboard.storyBoardID)!, userId: userId)
                                if err != nil {
                                    withAnimation(.spring()) {
                                        isLiked = true
                                        board?.boardActive.totalLikeCount = (board?.boardActive.totalLikeCount ?? 0) + 1
                                    }
                                }
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .foregroundColor(isLiked ? .theme.error : .theme.tertiaryText)
                                Text("\(board?.boardActive.totalLikeCount ?? 0)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.theme.tertiaryText)
                            }
                        }
                        Button(action: {
                            // TODO: 处理查看分支事件
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.branch")
                                    .foregroundColor(.theme.tertiaryText)
                                Text("\(board?.boardActive.totalForkCount ?? 0)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.theme.tertiaryText)
                            }
                        }
                    }
                    .padding(.top, 8)
                    // 评论列表
                    CommentListView(
                        storyId: self.storyId,
                        storyboardId: self.board?.boardActive.storyboard.storyBoardID ?? 0,
                        userId: self.userId,
                        totalCommentNum: Int(self.board?.boardActive.totalCommentCount ?? 0)
                    )
                    
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            isLiked = board?.boardActive.storyboard.currentUserStatus.isLiked ?? false
        }
    }
    
    private func formatTimeAgo(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// 交互按钮组件
private struct StoryboardDetailInteractionButton: View {
    let icon: String
    let count: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(count)
                    .font(.system(size: 12))
            }
        }
    }
}

