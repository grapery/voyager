import SwiftUI
import Kingfisher

struct CommentListView: View {
    let storyId: Int64
    let storyboardId: Int64?
    let userId: Int64
    let userAvatarURL: String?
    @StateObject private var viewModel = CommentsViewModel()
    @State private var commentText = ""
    @State private var isLoadingMore = false
    @FocusState private var isInputFocused: Bool
    public var totalCommentNum = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 评论输入区域
            CommentInputView(
                commentText: $commentText,
                replyToComment: viewModel.replyToComment,
                onSend: {
                    Task {
                        if !commentText.isEmpty {
                            if let replyTo = viewModel.replyToComment {
                                // 发送回复
                                let err = await viewModel.submitReplyForStoryComment(
                                    commentId: replyTo.realComment.commentID,
                                    userId: userId,
                                    content: commentText
                                )
                                if err == nil {
                                    // 重新加载回复列表
                                    _ = await viewModel.fetchCommentReplies(
                                        commentId: replyTo.realComment.commentID,
                                        userId: userId
                                    )
                                }
                                viewModel.replyToComment = nil
                                viewModel.replyToParentComment = nil
                            } else if let boardId = storyboardId {
                                let err = await viewModel.submitCommentForStoryboard(
                                    storyId: storyId,
                                    storyboardId: boardId,
                                    userId: userId,
                                    content: commentText
                                )
                                if err.1 == nil {
                                    // 重置页码并重新加载第一页
                                    viewModel.resetPagination()
                                    await viewModel.fetchStoryboardComments(storyId: storyId, storyboardId: boardId, userId: userId)
                                }
                            } else {
                                let err = await viewModel.submitCommentForStory(
                                    storyId: storyId,
                                    userId: userId,
                                    content: commentText,
                                    prevId: 0
                                )
                                if err.1 == nil {
                                    // 重置页码并重新加载第一页
                                    viewModel.resetPagination()
                                    await viewModel.fetchStoryComments(storyId: storyId, userId: userId)
                                }
                            }
                            commentText = ""
                            isInputFocused = false
                        }
                    }
                },
                onCancelReply: {
                    viewModel.replyToComment = nil
                    viewModel.replyToParentComment = nil
                    isInputFocused = false
                },
                isFocused: $isInputFocused,
                userAvatarURL: userAvatarURL
            )
            .padding(.horizontal, 12) // 输入区域左右留白
            .padding(.top, 8) // 顶部间距
            .padding(.bottom, 4) // 与下方信息条间距

            // "共 x 条评论"信息条
            HStack {
                Spacer()
                Text("共 \(totalCommentNum) 条评论")
                    .font(.system(size: 13))
                    .foregroundColor(.theme.tertiaryText)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.theme.tertiaryBackground)
            .cornerRadius(8)
            .padding(.bottom, 4) // 与评论列表间距
            // 评论列表
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.comments) { comment in
                        VStack(spacing: 0) {
                            CommentItemView(
                                comment: comment,
                                userId: userId,
                                viewModel: viewModel,
                                onReply: {
                                    viewModel.replyToComment = comment
                                    isInputFocused = true
                                }
                            )
                            
                            if comment.id != viewModel.comments.last?.id {
                                Divider()
                            }
                        }
                    }
                    
                    // 加载更多按钮
                    if viewModel.hasMoreComments {
                        Button(action: {
                            Task {
                                isLoadingMore = true
                                if let boardId = storyboardId {
                                    await viewModel.fetchStoryboardComments(storyId: storyId, storyboardId: boardId, userId: userId)
                                } else {
                                    await viewModel.fetchStoryComments(storyId: storyId, userId: userId)
                                }
                                isLoadingMore = false
                            }
                        }) {
                            HStack {
                                if isLoadingMore {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Text("加载更多评论")
                                        .font(.system(size: 12))
                                        .foregroundColor(.theme.tertiaryText)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .disabled(isLoadingMore)
                    }
                }
            }
            
            
        }
        .onAppear {
            Task {
                // 重置页码并加载第一页
                viewModel.resetPagination()
                if let boardId = storyboardId {
                    await viewModel.fetchStoryboardComments(storyId: storyId, storyboardId: boardId, userId: userId)
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
    @State private var isLiked: Bool
    @State private var replies: [Comment] = []
    @State private var isLoadingReplies = false
    @State private var showReplies = false
    let userId: Int64
    @ObservedObject var viewModel: CommentsViewModel
    let onReply: () -> Void
    
    init(comment: Comment, userId: Int64, viewModel: CommentsViewModel, onReply: @escaping () -> Void) {
        self.comment = comment
        self.userId = userId
        self.viewModel = viewModel
        self.onReply = onReply
        _isLiked = State(initialValue: (comment.realComment.isLiked != 0))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // 用户头像
                NavigationLink(destination: UserProfileView(user: User(
                    userID: comment.commentUser.userID,
                    name: comment.commentUser.name,
                    avatar: comment.commentUser.avatar
                ))) {
                    KFImage(URL(string: convertImagetoSenceImage(url: comment.commentUser.avatar, scene: .small)))
                        .cacheMemoryOnly()
                        .fade(duration: 0.25)
                        .placeholder { CommentAvatarPlaceholder() }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32) // 更大头像
                        .clipShape(Circle())
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // 用户名、时间和点赞按钮
                    HStack(alignment: .center) {
                        NavigationLink(destination: UserProfileView(user: User(
                            userID: comment.commentUser.userID,
                            name: comment.commentUser.name,
                            avatar: comment.commentUser.avatar
                        ))) {
                            Text(comment.commentUser.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.theme.primaryText)
                        }
                        Spacer()
                        Text(formatTimeAgo(timestamp: comment.realComment.createdAt))
                            .font(.system(size: 12))
                            .foregroundColor(.theme.tertiaryText)
                    }
                    // 评论内容
                    Text(comment.realComment.content)
                        .font(.system(size: 15))
                        .foregroundColor(.theme.primaryText)
                        .padding(.vertical, 2)
                    // 评论操作栏
                    HStack(spacing: 20) {
                        // 点赞按钮
                        Button(action: {
                            Task {
                                isLiked.toggle()
                                if isLiked {
                                    await viewModel.likeComments(userId: userId, commentId: comment.realComment.commentID)
                                } else {
                                    await viewModel.dislikeComment(userId: userId, commentId: comment.realComment.commentID)
                                }
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 15, weight: .bold))
                                    .scaleEffect(isLiked ? 1.2 : 1.0)
                                    .foregroundColor(isLiked ? .theme.error : .theme.tertiaryText)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isLiked)
                                Text("\(comment.realComment.likeCount)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(isLiked ? .theme.error : .theme.tertiaryText)
                            }
                        }
                        // 回复按钮
                        Button(action: onReply) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrowshape.turn.up.left")
                                    .font(.system(size: 14, weight: .medium))
                                Text("回复")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.theme.tertiaryText)
                        }
                        // 展开回复按钮
                        if comment.realComment.replyCount > 0 {
                            Button(action: {
                                if !showReplies {
                                    Task {
                                        isLoadingReplies = true
                                        if let fetchedReplies = try? await viewModel.fetchCommentReplies(
                                            commentId: comment.realComment.commentID,
                                            userId: userId
                                        ).0 {
                                            replies = fetchedReplies
                                        }
                                        isLoadingReplies = false
                                        showReplies.toggle()
                                    }
                                } else {
                                    showReplies.toggle()
                                }
                            }) {
                                Text("\(showReplies ? "收起" : "展开")\(comment.realComment.replyCount)条回复")
                                    .font(.system(size: 13))
                                    .foregroundColor(.theme.accent)
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            }
            // 回复列表
            if showReplies {
                if isLoadingReplies {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.top, 8)
                        .padding(.leading, 44)
                } else {
                    VStack(spacing: 0) {
                        ForEach(replies) { reply in
                            VStack(spacing: 0) {
                                ReplyItemView(
                                    reply: reply,
                                    userId: userId,
                                    viewModel: viewModel,
                                    onReply: {
                                        viewModel.replyToComment = reply
                                    }
                                )
                                if reply.id != replies.last?.id {
                                    Divider()
                                        .padding(.leading, 44)
                                }
                            }
                        }
                    }
                    .padding(.leading, 36)
                }
            }
        }
        // 卡片样式：圆角、阴影、背景色
        .padding(12)
        .background(Color.theme.secondaryBackground)
    }
    
    private func formatTimeAgo(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// 回复项视图
private struct ReplyItemView: View {
    let reply: Comment
    let userId: Int64
    @ObservedObject var viewModel: CommentsViewModel
    let onReply: () -> Void
    @State private var isLiked: Bool
    
    init(reply: Comment, userId: Int64, viewModel: CommentsViewModel, onReply: @escaping () -> Void) {
        self.reply = reply
        self.userId = userId
        self.viewModel = viewModel
        self.onReply = onReply
        _isLiked = State(initialValue: (reply.realComment.isLiked != 0))
    }
    
    var body: some View {
        Button(action: onReply) {
            HStack(alignment: .top, spacing: 12) { // 增加头像和内容之间的间距
                // 头像
                KFImage(URL(string: convertImagetoSenceImage(url: reply.commentUser.avatar, scene: .small)))
                    .cacheMemoryOnly()
                    .fade(duration: 0.25)
                    .placeholder { CommentAvatarPlaceholder() }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
                // 内容区域
                VStack(alignment: .leading, spacing: 4) { // 增加垂直间距
                    // 用户名、时间和点赞
                    HStack {
                        Text(reply.commentUser.name)
                            .font(.system(size: 12, weight: .medium)) // 增加字体大小
                            .foregroundColor(.theme.primaryText)
                        Spacer()
                        Text(formatTimeAgo(timestamp: reply.realComment.createdAt))
                            .font(.system(size: 12)) // 增加字体大小
                            .foregroundColor(.theme.tertiaryText)
                        // 点赞按钮
                        Button(action: {
                            Task {
                                isLiked.toggle()
                                if isLiked {
                                    await viewModel.likeComments(userId: userId, commentId: reply.realComment.commentID)
                                } else {
                                    await viewModel.dislikeComment(userId: userId, commentId: reply.realComment.commentID)
                                }
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 12))
                                if reply.realComment.likeCount > 0 {
                                    Text("\(reply.realComment.likeCount)")
                                        .font(.system(size: 12))
                                }
                            }
                            .foregroundColor(isLiked ? .theme.error : .theme.tertiaryText)
                            .animation(.easeInOut(duration: 0.2), value: isLiked)
                        }
                    }
                    // 评论内容
                    Text(reply.realComment.content)
                        .font(.system(size: 12)) // 增加字体大小
                        .foregroundColor(.theme.primaryText)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        // 保持与一级评论一致的上下间隔
        .padding(.vertical, 4)
    }
    
    private func formatTimeAgo(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
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

// 评论输入视图
private struct CommentInputView: View {
    @Binding var commentText: String
    let replyToComment: Comment?
    let onSend: () -> Void
    let onCancelReply: () -> Void
    var isFocused: FocusState<Bool>.Binding
    let userAvatarURL: String?

    private var placeholderText: String {
        if let replyTo = replyToComment {
            return "回复 @\(replyTo.commentUser.name)："
        }
        return "说点什么..."
    }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                // 头像
                if let url = userAvatarURL, let imageURL = URL(string: url) {
                    KFImage(imageURL)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                } else {
                    // 默认头像
                    CommentAvatarPlaceholder()
                        .frame(width: 36, height: 36)
                }
                // 输入框
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.theme.divider, lineWidth: 1)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
                        .frame(height: 40)
                    HStack(spacing: 0) {
                        TextField(placeholderText, text: $commentText)
                            .focused(isFocused)
                            .font(.system(size: 15))
                            .foregroundColor(.theme.primaryText)
                            .padding(.horizontal, 10)
                            .frame(height: 40)
                        if replyToComment != nil {
                            Button(action: onCancelReply) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.theme.tertiaryText)
                            }
                            .padding(.trailing, 6)
                        }
                    }
                }
                // 发布按钮
                Button(action: onSend) {
                    Text("发布")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(commentText.isEmpty ? .theme.tertiaryText : .white)
                        .frame(width: 52, height: 36)
                        .background(commentText.isEmpty ? Color.theme.tertiaryBackground : Color.theme.accent)
                        .cornerRadius(8)
                }
                .disabled(commentText.isEmpty)
            }
            // 表情、@按钮区
            HStack(spacing: 16) {
                Button(action: {
                    // TODO: 表情选择逻辑
                }) {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 20))
                        .foregroundColor(.theme.tertiaryText)
                }
                Button(action: {
                    // TODO: @逻辑
                }) {
                    Image(systemName: "at")
                        .font(.system(size: 20))
                        .foregroundColor(.theme.tertiaryText)
                }
                Spacer()
            }
            .padding(.leading, 44) // 与输入框左侧头像对齐
        }
        .padding(.vertical, 4)
    }
}
