//
//  StoryBoardDetail.swift
//  voyager
//
//  Created by grapestree on 2025/3/1.
//


import SwiftUI
import Kingfisher
import Combine
import AVKit


// 媒体项目类型
struct MediaItem: Identifiable {
    let id: String
    let type: MediaType
    let url: URL
    let thumbnail: URL?
}

// 添加场景媒体项目结构
struct SceneMediaContent: Identifiable {
    let id: String
    let sceneTitle: String
    let mediaItems: [MediaItem]
}

struct StoryBoardCellView: View {
    var board: StoryBoard?
    var userId: Int64
    var groupId: Int64
    var storyId: Int64
    @State var viewModel: StoryViewModel
    @State private var isShowingBoardDetail = false
    
    @State var isShowingNewStoryBoard = false
    @State var isShowingCommentView = false
    @State var isForkingStory = false
    @State var isLiked = false
    @State var showingDeleteAlert = false
    
    // 添加评论相关状态
    @State private var commentText: String = ""
    @State var commentViewModel = CommentsViewModel()
    
    let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    // 将 sceneMediaContents 改为普通属性而不是 @State
    let sceneMediaContents: [SceneMediaContent]
    
    
    init(board: StoryBoard? = nil, userId: Int64, groupId: Int64, storyId: Int64, isShowingBoardDetail: Bool = false, viewModel: StoryViewModel) {
        self.board = board
        self.userId = userId
        self.groupId = groupId
        self.storyId = storyId
        self.viewModel = viewModel
        self.isShowingBoardDetail = isShowingBoardDetail
        
        // 初始化 sceneMediaContents
        var tempSceneContents: [SceneMediaContent] = []
        
        if let scenes = board?.boardInfo.sences.list {
            
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
        }
        
        self.sceneMediaContents = tempSceneContents
    }
    
    private var storyboardCellHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(board?.boardInfo.title ?? "无标题故事章节")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(formatDate(timestamp: (board?.boardInfo.ctime)!))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
    
    private var senceDetails: some View {
        let allMediaItems = sceneMediaContents.flatMap { content in
            content.mediaItems
        }
        
        return VStack(alignment: .leading, spacing: 8) {
            // 文字描述
            if let content = board?.boardInfo.content {
                Text(content)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .padding(.bottom, 4)
            }
            
            // 场景图片网格 - 最多显示4张图片
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 4),
                GridItem(.flexible(), spacing: 4)
            ], spacing: 4) {
                ForEach(Array(allMediaItems.prefix(min(4, allMediaItems.count)).enumerated()), id: \.element.id) { index, item in
                    if index == 3 && allMediaItems.count > 4 {
                        // 如果是第4个位置且有更多图片，显示+N
                        ZStack {
                            KFImage(item.url)
                                .resizable()
                                .scaledToFill()
                                .frame(height: (UIScreen.main.bounds.width - 48) / 2)
                                .clipped()
                            
                            Rectangle()
                                .fill(Color.black.opacity(0.6))
                            
                            Text("+\(allMediaItems.count - 3)")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .cornerRadius(8)
                    } else {
                        KFImage(item.url)
                            .resizable()
                            .scaledToFill()
                            .frame(height: (UIScreen.main.bounds.width - 48) / 2)
                            .clipped()
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 2)
            
            // 场景数量提示
            HStack {
                Image(systemName: "photo.stack")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                Text("共\(sceneMediaContents.count)个场景")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
    }
    
    var body: some View {
        NavigationLink(destination: StoryBoardView(board: board!, userId: userId, groupId: self.groupId, storyId: self.storyId, viewModel: self.viewModel)) {
            VStack(alignment: .leading, spacing: 8) {
                storyboardCellHeader
                
                // Content
                VStack {
                    if sceneMediaContents.count <= 0 {
                        Text((board?.boardInfo.content)!)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                            .lineLimit(3)
                    } else {
                        senceDetails
                    }
                }
                
                // Action buttons
                HStack(spacing: 24) {
                    StoryActionButton(icon: "pencil.circle", action: {
                        self.isShowingNewStoryBoard = true
                    })
                    .frame(width: 32, height: 32)
                    
                    StoryActionButton(icon: "signpost.right.and.left.circle", action: {
                        self.isForkingStory = true
                    })
                    .frame(width: 32, height: 32)
                    
                    StoryActionButton(icon: "heart.circle", action: {
                        self.isLiked = true
                        Task {
                            await self.viewModel.likeStoryBoard(storyId: self.storyId, boardId: (self.board?.boardInfo.storyBoardID)!, userId: self.userId)
                        }
                    })
                    .frame(width: 32, height: 32)
                    
                    if self.board?.boardInfo.creator == self.userId {
                        StoryActionButton(icon: "trash.circle", action: {
                            showingDeleteAlert = true
                        })
                        .frame(width: 32, height: 32)
                        .alert("确认删除", isPresented: $showingDeleteAlert) {
                            Button("取消", role: .cancel) { }
                            Button("删除", role: .destructive) {
                                Task {
                                    await self.viewModel.deleteStoryBoard(
                                        storyId: self.storyId,
                                        boardId: (self.board?.boardInfo.storyBoardID)!,
                                        userId: self.userId
                                    )
                                }
                            }
                        } message: {
                            Text("确定要删除这个故事板吗？此操作无法撤销。")
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(4)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .fullScreenCover(isPresented: $isShowingNewStoryBoard) {
            
            NavigationStack {
                NewStoryBoardView(
                    storyId: viewModel.storyId,
                    boardId: (board?.boardInfo.storyBoardID)!,
                    prevBoardId: (board?.boardInfo.prevBoardID)!,
                    viewModel: $viewModel,
                    roles: [StoryRole](),
                    isForkingStory: false,
                    isPresented: $isShowingNewStoryBoard  // 新增
                )
                .navigationBarItems(leading: Button(action: {
                    isShowingNewStoryBoard = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                })
            }
        }
        .fullScreenCover(isPresented: $isForkingStory) {
            NavigationStack {
                NewStoryBoardView(
                    storyId: viewModel.storyId,
                    boardId: (board?.boardInfo.storyBoardID)!,
                    prevBoardId: (board?.boardInfo.prevBoardID)!,
                    viewModel: $viewModel,
                    roles: [StoryRole](),
                    isForkingStory: true,
                    isPresented: $isForkingStory  // 新增
                )
                .navigationBarItems(leading: Button(action: {
                    isForkingStory = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                })
            }
        }
    }
    
    private func formatDate(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return DateFormatter.shortDate.string(from: date)
    }
    
    // 添加提交评论的方法
    private func submitComment() async {
        guard !commentText.isEmpty else { return }
        
        do {
            // 调用评论 API
            let err = await self.commentViewModel.submitCommentForStoryboard(
                commentText: commentText,
                storyId: storyId,
                boardId: board?.boardInfo.storyBoardID ?? 0,
                userId:  self.userId
            )
            
            if err != nil{
                // 处理错误
                print("Error submitting comment: \(String(describing: err))")
            } else {
                // 清空评论文本
                commentText = ""
                // 可能需要刷新评论列表
                await self.commentViewModel.fetchStoryboardComments()
            }
        }
    }
    
}

struct StoryActionButton: View {
    let icon: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                action()
                withAnimation {
                    isPressed = false
                }
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
    }
}
