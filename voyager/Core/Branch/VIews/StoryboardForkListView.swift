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
    
    init(userId:Int64, currentBoard: StoryBoardActive, viewModel: StoryViewModel, showingStoryBoard: Bool = false, selectedBoard: StoryBoardActive? = nil) {
        self.viewModel = viewModel
        self.showingStoryBoard = showingStoryBoard
        self.selectedBoard = selectedBoard
        self.currentBoard = currentBoard
        self.userId = userId
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题
            Text("分支故事")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color.theme.primaryText)
                .padding(.horizontal, 16)
            
            // 分支列表
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(viewModel.forkStoryboards!) { board in
                        ForkStoryBoardCard(board: board)
                            .onTapGesture {
                                selectedBoard = board
                                showingStoryBoard = true
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .fullScreenCover(isPresented: $showingStoryBoard) {
            if let board = selectedBoard {
                NavigationStack {
                    StoryBoardView(
                        userId: (selectedBoard?.boardActive.creator.userID)!,
                        groupId: (selectedBoard?.boardActive.summary.storyID)!,
                        storyId: (selectedBoard?.boardActive.summary.storyID)!,
                        viewModel: viewModel
                    )
                }
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

