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
    var pageSize: Int64
    var pageNum: Int64
    @Published var comments = [Comment]()
    init(user: User? = nil) {
        self.user = user
        self.pageSize = 10
        self.pageNum = 0
    }
    
    func uploadComment(commentText: String) async {
        
    }
    
    func fetchComments() async {
        
    }
    
    func fetchCommentsUserInfo() async {
        for i in 0..<comments.count {
            let comment = comments[i]
            let user = await APIClient.shared.fetchUser(withUid: comment.realComment.userID)
            comments[i].commentUser = user
        }
    }
}



