//
//  StoryboardForkListView.swift
//  voyager
//
//  Created by grapestree on 2025/4/10.
//

import SwiftUI
import Kingfisher

struct StoryboardForkListView: View {
    @ObservedObject var viewModel: StoryViewModel
    @State var showingStoryBoard: Bool
    @State var selectedBoard: StoryBoardActive?
    let currentBoard: StoryBoardActive
    let userId: Int64
    @State private var apiClient = APIClient()
    
    init(userId:Int64, currentBoard: StoryBoardActive, viewModel: StoryViewModel, showingStoryBoard: Bool = false, selectedBoard: StoryBoardActive? = nil) {
        self.viewModel = viewModel
        self.showingStoryBoard = showingStoryBoard
        self.selectedBoard = selectedBoard
        self.currentBoard = currentBoard
        self.userId = userId
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {            
            // 分支列表
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    let boardId = currentBoard.boardActive.storyboard.storyBoardID
                    let forkList = viewModel.getForkList(for: boardId)
                    
                    ForEach(forkList) { board in
                        ForkStoryBoardCard(board: board)
                            .onTapGesture {
                                selectedBoard = board
                                showingStoryBoard = true
                            }
                    }
                    
                    // 如果有更多数据，显示加载更多按钮
                    if viewModel.hasMoreForkList(for: boardId) && !viewModel.isLoadingForkList(for: boardId) {
                        Button(action: {
                            Task {
                                await viewModel.loadMoreForkStoryboards(
                                    userId: userId,
                                    storyId: currentBoard.boardActive.summary.storyID,
                                    boardId: boardId
                                )
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("加载更多")
                            }
                            .font(.system(size: 12))
                            .foregroundColor(Color.theme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.theme.secondaryBackground)
                            .cornerRadius(16)
                        }
                    }
                    
                    // 加载状态指示器
                    if viewModel.isLoadingForkList(for: boardId) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .task {
            await viewModel.fetchStoryboardForkList(
                userId: userId,
                storyId: currentBoard.boardActive.summary.storyID,
                boardId: currentBoard.boardActive.storyboard.storyBoardID
            )
        }
    }
}

// 分支故事卡片视图
private struct ForkStoryBoardCard: View {
    let board: StoryBoardActive
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 故事板封面图
            if let firstScene = board.boardActive.storyboard.sences.list.first,
               let data = firstScene.genResult.data(using: .utf8),
               let urls = try? JSONDecoder().decode([String].self, from: data),
               let firstImageUrl = urls.first,
               let url = URL(string: firstImageUrl) {
                KFImage(url)        
                    .cacheMemoryOnly()
                    .fade(duration: 0.25)
                    .placeholder {
                        Rectangle()
                            .fill(Color.theme.tertiaryBackground)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 180)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.theme.tertiaryBackground)
                    .frame(width: 140, height: 180)
                    .cornerRadius(8)
            }
            
            // 故事板标题
            Text(board.boardActive.storyboard.title)
                .font(.system(size: 15))
                .foregroundColor(Color.theme.primaryText)
                .lineLimit(2)
                .frame(width: 140, alignment: .leading)
            
            // 统计信息
            HStack(spacing: 8) {
               
                Label("\(board.boardActive.totalLikeCount)", systemImage: "heart.fill")
                Label("\(board.boardActive.totalCommentCount)", systemImage: "bubble.left.fill")
                Label("\( board.boardActive.totalForkCount)", systemImage: "bubble.left.fill")
            }
            .font(.system(size: 12))
            .foregroundColor(Color.theme.tertiaryText)
        }
        .frame(width: 140)
        .background(Color.theme.background)
    }
}

struct FeedStoryboardForkListView: View {
    @ObservedObject var viewModel: FeedViewModel
    @State private var showingStoryBoard = false
    @State private var selectedBoard: StoryBoardActive?
    let currentBoard: StoryBoardActive
    let userId: Int64
    
    init(userId: Int64, currentBoard: StoryBoardActive, viewModel: FeedViewModel) {
        self.viewModel = viewModel
        self.currentBoard = currentBoard
        self.userId = userId
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack() {
                let boardId = currentBoard.boardActive.storyboard.storyBoardID
                let forkList = viewModel.getForkList(for: boardId)
                
                ForEach(forkList) { board in
                    FeedForkStoryBoardCard(board: board)
                        .onTapGesture {
                            selectedBoard = board
                            showingStoryBoard = true
                        }
                }
                
                // 如果有更多数据，显示加载更多按钮
                if viewModel.hasMoreForkList(for: boardId) && !viewModel.isLoadingForkList(for: boardId) {
                    Button(action: {
                        Task {
                            await viewModel.loadMoreForkStoryboards(
                                userId: userId,
                                storyId: currentBoard.boardActive.summary.storyID,
                                boardId: boardId
                            )
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("加载更多")
                        }
                        .font(.system(size: 12))
                        .foregroundColor(Color.theme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.theme.secondaryBackground)
                        .cornerRadius(16)
                    }
                }
                
                // 加载状态指示器
                if viewModel.isLoadingForkList(for: boardId) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal, 16)
        }
        .onDisappear {
            viewModel.clearForkList(for: currentBoard.boardActive.storyboard.storyBoardID)
        }
    }
}

// 分支故事板卡片
private struct FeedForkStoryBoardCard: View {
    let board: StoryBoardActive
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // 故事板内容预览
            Text(board.boardActive.storyboard.content)
                .font(.system(size: 14))
                .foregroundColor(Color.theme.primaryText)
                .lineLimit(5)
                .frame(width: 80)
                .frame(height: 150)
                .padding(.bottom, 4)
            
            // 创建者信息
            HStack(spacing: 4) {
                KFImage(URL(string: convertImagetoSenceImage(url: defaultAvator, scene: .small)))
                    .cacheMemoryOnly()
                    .fade(duration: 0.25)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
                
                Text(board.boardActive.creator.userName)
                    .font(.system(size: 12))
                    .foregroundColor(Color.theme.secondaryText)
            }
            
            // 互动信息
            HStack(spacing: 16) {
                Label("\(board.boardActive.totalLikeCount)", systemImage: "heart")
                Label("\(board.boardActive.totalCommentCount)", systemImage: "bubble.left")
                Label("\(board.boardActive.totalForkCount)", systemImage: "signpost.right.and.left")
            }
            .font(.system(size: 12))
            .foregroundColor(Color.theme.tertiaryText)
        }
        .padding(12)
        .frame(width: 220)
        .background(Color.theme.background)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.theme.border, lineWidth: 0.5)
        )
    }
}

