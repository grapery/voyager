import SwiftUI
import Kingfisher

struct StoryBoardDetailShowView: View {
    let board: StoryBoardActive
    let userId: Int64
    @ObservedObject var viewModel: StoryViewModel
    @State private var commentText: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 头部信息
                StoryBoardHeaderView(board: board)
                
                // 故事板内容
                StoryBoardDetailContentView(board: board)
                
                // 交互栏
                StoryBoardInteractionBar(
                    board: board,
                    userId: userId,
                    viewModel: viewModel
                )
                
                // 评论列表
                if !board.boardActive.comments.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("评论")
                            .font(.headline)
                            .padding(.horizontal, 16)
                        
                        ForEach(board.boardActive.comments, id: \.comment.commentID) { comment in
                            CommentRowView(comment: comment)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.vertical, 16)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Header View
private struct StoryBoardHeaderView: View {
    let board: StoryBoardActive
    
    var body: some View {
        HStack(spacing: 12) {
            KFImage(URL(string: defaultAvator))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(board.boardActive.storyboard.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.theme.primaryText)
                
                Text(formatDate(timestamp: board.boardActive.storyboard.ctime))
                    .font(.system(size: 14))
                    .foregroundColor(Color.theme.tertiaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    private func formatDate(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Content View
private struct StoryBoardDetailContentView: View {
    let board: StoryBoardActive
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(board.boardActive.storyboard.content)
                .font(.system(size: 16))
                .foregroundColor(Color.theme.primaryText)
                .padding(.horizontal, 16)
            
            if !board.boardActive.storyboard.sences.list.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(board.boardActive.storyboard.sences.list, id: \.sceneID) { scene in
                            StoryboardSceneCardView(scene: scene)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Scene Card View
private struct StoryboardSceneCardView: View {
    let scene: Scene
    
    var body: some View {
        if let data = scene.genResult.data(using: .utf8),
           let urls = try? JSONDecoder().decode([String].self, from: data),
           let firstUrl = urls.first {
            VStack(alignment: .leading, spacing: 8) {
                KFImage(URL(string: firstUrl))
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
                    .frame(width: 200, height: 280)
                    .clipped()
                    .cornerRadius(12)
                
                Text(scene.content)
                    .font(.system(size: 14))
                    .foregroundColor(Color.theme.secondaryText)
                    .lineLimit(2)
                    .frame(width: 200)
            }
        }
    }
}

// MARK: - Interaction Bar
private struct StoryBoardInteractionBar: View {
    let board: StoryBoardActive
    let userId: Int64
    @ObservedObject var viewModel: StoryViewModel
    
    var body: some View {
        HStack(spacing: 24) {
            StoryboardShowInteractionButton(
                icon: board.boardActive.storyboard.currentUserStatus.isLiked ? "heart.fill" : "heart",
                count: "\(board.boardActive.totalLikeCount)",
                color: board.boardActive.storyboard.currentUserStatus.isLiked ? Color.theme.error : Color.theme.tertiaryText
            ) {
                Task {
                    if board.boardActive.storyboard.currentUserStatus.isLiked {
                        await viewModel.unlikeStoryBoard(
                            storyId: board.boardActive.storyboard.storyID,
                            boardId: board.boardActive.storyboard.storyBoardID,
                            userId: userId
                        )
                    } else {
                        await viewModel.likeStoryBoard(
                            storyId: board.boardActive.storyboard.storyID,
                            boardId: board.boardActive.storyboard.storyBoardID,
                            userId: userId
                        )
                    }
                }
            }
            
            StoryboardShowInteractionButton(
                icon: "bubble.left",
                count: "\(board.boardActive.totalCommentCount)",
                color: Color.theme.tertiaryText
            ) {
                // 评论功能
            }
            
            StoryboardShowInteractionButton(
                icon: "square.and.arrow.up",
                count: "\(board.boardActive.totalForkCount)",
                color: Color.theme.tertiaryText
            ) {
                // 分享功能
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Comment Row View
private struct CommentRowView: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            KFImage(URL(string: comment.commentUser.avatar))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(comment.commentUser.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.theme.primaryText)
                
                Text(comment.realComment.content)
                    .font(.system(size: 14))
                    .foregroundColor(Color.theme.secondaryText)
                
                Text(formatTimeAgo(timestamp: comment.realComment.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(Color.theme.tertiaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private func formatTimeAgo(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Interaction Button
private struct StoryboardShowInteractionButton: View {
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
