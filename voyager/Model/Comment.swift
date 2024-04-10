//
//  Comment.swift
//  voyager
//
//  Created by grapestree on 2024/3/25.
//

import Foundation

class Comment: Identifiable{
    var id: String
    var realComment: Common_CommentInfo
    var commentUser: User
    init(id: String, realComment: Common_CommentInfo, commentUser: User) {
        self.id = UUID().uuidString
        self.realComment = realComment
        self.commentUser = commentUser
    }
}
