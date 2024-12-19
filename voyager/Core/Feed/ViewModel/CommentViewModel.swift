//
//  CommentViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/3/30.
//

import Foundation

@MainActor
class CommentsViewModel: ObservableObject {
    var pageSize: Int64
    var pageNum: Int64
    @Published var comments = [Comment]()
    init() {
        self.pageSize = 10
        self.pageNum = 0
    }
    
    func submitCommentForStory(commentText: String,storyId:Int64,userId:Int64) async -> Error?{
        return nil
    }
    
    func submitCommentForStoryboard(commentText: String,storyId:Int64,boardId: Int64,userId:Int64) async -> Error?{
        return nil
    }
    
    func submitCommentForStoryRole(commentText: String,storyId:Int64,roleId: Int64,userId:Int64) async -> Error?{
        return nil
    }
    
    func fetchStoryComments() async {
        for i in 0..<comments.count {
            let comment = comments[i]
            let user = await APIClient.shared.fetchUser(withUid: comment.realComment.userID)
            comments[i].commentUser = user
        }
    }
    
    func fetchStoryboardComments() async {
        for i in 0..<comments.count {
            let comment = comments[i]
            let user = await APIClient.shared.fetchUser(withUid: comment.realComment.userID)
            comments[i].commentUser = user
        }
    }
    
    func fetchStoryRoleComments() async {
        for i in 0..<comments.count {
            let comment = comments[i]
            let user = await APIClient.shared.fetchUser(withUid: comment.realComment.userID)
            comments[i].commentUser = user
        }
    }
}



