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
    
    func submitCommentForStory(storyId: Int64,userId:Int64,content: String,prevId:Int64) async -> Error?{
        let err = await APIClient.shared.CreateStoryComment(storyId: storyId, userId: userId, content: content)
        if err != nil{
            print("submitCommentForStory failed: ",err!)
            return err
        }
        print("submitCommentForStory success")
        return nil
    }
    
    func submitCommentForStoryboard(storyId: Int64,storyboardId: Int64,userId:Int64,content: String) async -> Error?{
        let err = await APIClient.shared.CreateStoryBoardComment(storyBoardId: storyboardId, user_id: userId, content: content)
        if err != nil{
            print("submitCommentForStoryboard failed: ",err!)
            return err
        }
        print("submitCommentForStoryboard success")
        return nil
    }
    
    func fetchStoryComments(storyId: Int64, userId: Int64) async -> ([Comment]?, Error?) {
        let (comments, total, pageNum, pageSize, err) = await APIClient.shared.GetStoryComments(storyId: storyId, user_id: userId, page: Int(self.pageNum), page_size: Int(self.pageSize))
        
        if err != nil {
            print("fetchStoryComments failed: ", err!)
            return (nil, err)
        }
        
        self.pageSize = 10
        self.pageNum = self.pageNum + 1
        print("fetchStoryComments success")
        // 将 Common_StoryComment 列表转换为 Comment 列表
        if let storyComments = comments {
            let convertedComments = storyComments.map { storyComment in
                Comment(
                    id: "\(storyComment.commentID)",
                    realComment: storyComment,
                    commentUser: User(userID: storyComment.creator.userID, name: storyComment.creator.name, avatar: storyComment.creator.avatar)
                )
            }
            return (convertedComments, nil)
        }
        
        return (nil, nil)
    }
    
    func fetchStoryboardComments(storyboardId: Int64, userId: Int64) async -> ([Comment]?, Error?) {
        let (comments, total, pageNum, pageSize, err) = await APIClient.shared.GetStoryBoardComments(storyBoardId: storyboardId, user_id: userId, page: self.pageNum, page_size: self.pageSize)
        
        if err != nil {
            print("fetchStoryboardComments failed: ", err!)
            return (nil, err)
        }
        
        self.pageSize = 10
        self.pageNum = self.pageNum + 1
        print("fetchStoryboardComments success")
        
        // 将 Common_StoryComment 列表转换为 Comment 列表
        if let boardComments = comments {
            let convertedComments = boardComments.map { boardComment in
                Comment(
                    id: "\(boardComment.commentID)",
                    realComment: boardComment,
                    commentUser: User(userID: boardComment.creator.userID, name: boardComment.creator.name, avatar: boardComment.creator.avatar)
                )
            }
            return (convertedComments, nil)
        }
        
        return (nil, nil)
    }
    
    
    func likeComments(userId: Int64,commentId:Int64) async ->Error? {
        let err = await APIClient.shared.LikeComment(commentId: commentId, user_id: userId)
        if err != nil {
            print("like Comment err: ",err as Any)
        }
        print("like comments success")
        return nil
    }
    
    func dislikeComment(userId: Int64,commentId:Int64) async -> Error?{
        let err = await APIClient.shared.DislikeComment(commentId: commentId, user_id: userId)
        if err != nil {
            print("dislike Comment err: ",err as Any)
        }
        print("dislike comments success")
        return nil
    }
}



