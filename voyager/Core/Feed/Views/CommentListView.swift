import SwiftUI
import Kingfisher

struct CommentListView: View {
    let storyId: Int64
    let storyboardId: Int64?
    let userId: Int64
    @StateObject private var viewModel = CommentsViewModel()
    @State private var commentText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 评论列表
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.comments) { comment in
                        CommentItemView(comment: comment)
                        
                        if comment.id != viewModel.comments.last?.id {
                            Divider()
                                .padding(.leading, 64)
                        }
                    }
                }
            }
            
            // 评论输入区域
            CommentInputView(
                commentText: $commentText,
                onSend: {
                    Task {
                        if !commentText.isEmpty {
                            if let boardId = storyboardId {
                                let err = await viewModel.submitCommentForStoryboard(
                                    storyId: storyId,
                                    storyboardId: boardId,
                                    userId: userId,
                                    content: commentText
                                )
                                if err == nil {
                                    await viewModel.fetchStoryboardComments(storyboardId: boardId, userId: userId)
                                }
                            } else {
                                let err = await viewModel.submitCommentForStory(
                                    storyId: storyId,
                                    userId: userId,
                                    content: commentText,
                                    prevId: 0
                                )
                                if err == nil {
                                    await viewModel.fetchStoryComments(storyId: storyId, userId: userId)
                                }
                            }
                            commentText = ""
                        }
                    }
                }
            )
        }
        .onAppear {
            Task {
                if let boardId = storyboardId {
                    await viewModel.fetchStoryboardComments(storyboardId: boardId, userId: userId)
                } else {
                    await viewModel.fetchStoryComments(storyId: storyId, userId: userId)
                }
            }
        }
    }
}

// 单个评论项视图
private struct CommentItemView: View {
    let comment: Comment
    @State private var isLiked = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 用户头像
            KFImage(URL(string: comment.commentUser.avatar))
                .placeholder { CommentAvatarPlaceholder() }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                // 用户名和时间
                HStack {
                    Text(comment.commentUser.name)
                        .font(.system(size: 14, weight: .medium))
                    
                    Spacer()
                    
//                    Text(formatTimeAgo(timestamp: comment.realComment.ctime))
//                        .font(.system(size: 12))
//                        .foregroundColor(.theme.tertiaryText)
                }
                
                // 评论内容
                Text(comment.realComment.content)
                    .font(.system(size: 14))
                    .foregroundColor(.theme.primaryText)
                
                // 评论操作栏
                HStack(spacing: 16) {
                    Button(action: { isLiked.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 12))
                            Text("\(comment.realComment.likeCount)")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(isLiked ? .theme.error : .theme.tertiaryText)
                    }
                    
                    Button(action: {}) {
                        Text("回复")
                            .font(.system(size: 12))
                            .foregroundColor(.theme.tertiaryText)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func formatTimeAgo(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// 评论输入视图
private struct CommentInputView: View {
    @Binding var commentText: String
    let onSend: () -> Void
    @State private var showImagePicker = false
    @State private var showEmojiPicker = false
    
    var body: some View {
        HStack(spacing: 6) {
            TextField("说点什么...", text: $commentText)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.theme.tertiaryBackground)
                .cornerRadius(16)
            
            Button(action: { showImagePicker = true }) {
                Image(systemName: "photo")
                    .foregroundColor(.theme.tertiaryText)
                    .frame(width: 24, height: 24)
            }
            
            Button(action: {}) {
                Image(systemName: "at")
                    .foregroundColor(.theme.tertiaryText)
                    .frame(width: 24, height: 24)
            }
            
            Button(action: { showEmojiPicker = true }) {
                Image(systemName: "face.smiling")
                    .foregroundColor(.theme.tertiaryText)
                    .frame(width: 24, height: 24)
            }
            
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(commentText.isEmpty ? .theme.tertiaryText : .theme.primary)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .padding(.bottom, 2)
        .background(Color.theme.secondaryBackground)
    }
}

// 头像占位图
private struct CommentAvatarPlaceholder: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.theme.tertiaryBackground)
            
            Image(systemName: "person.fill")
                .foregroundColor(Color.theme.tertiaryText)
                .font(.system(size: 20))
        }
    }
} 
