//
//  CommentViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/3/30.
//

import Foundation

@MainActor
class CommentsViewModel: ObservableObject {
    var user: User?
    var item: StoryItem?
    var pageSize: Int64
    var pageNum: Int64
    @Published var comments = [Comment]()
    init(user: User? = nil, item: StoryItem? = nil, comments: [Comment] = [Comment]()) {
        self.user = user
        self.item = item
        self.comments = comments
        self.pageSize = 10
        self.pageNum = 0
    }
    
    func uploadComment(commentText: String) async throws {
        let newComment = Common_CommentInfo()
        let comment = Comment(id: UUID().uuidString, realComment: newComment, commentUser: self.user!)
        
        self.comments.insert(comment, at: 0)
        await APIClient.shared.createCommentForItems(userId: self.user!.userID, projectId: self.item!.projectId, itemId: self.item!.itemId, info: newComment)
    }
    
    func fetchComments() async throws {
        var pageSize = pageSize
        let pageNum = pageNum
        if pageSize == 0 {
            pageSize = 10
        }
        (self.comments,self.pageSize,self.pageNum ) = await APIClient.shared.fetchItemsComment(userId: self.user!.userID, projectId: self.item!.projectId, itemId: self.item!.itemId, filter: [String](), pageSize: pageSize, pageNum: pageNum)
        try await fetchCommentsUserInfo()
    }
    
    func fetchCommentsUserInfo() async throws {
        for i in 0..<comments.count {
            let comment = comments[i]
            let user = await APIClient.shared.fetchUser(withUid: comment.realComment.userID)
            comments[i].commentUser = user
        }
    }
}



