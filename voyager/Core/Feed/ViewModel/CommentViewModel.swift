//
//  CommentViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/3/30.
//

import Foundation
import SwiftUI

@MainActor
class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var hasMoreComments = false
    @Published var replyToComment: Comment? = nil
    private var pageNum: Int = 1
    private var pageSize: Int = 10
    private var totalCount: Int = 0
    @Published var replyToParentComment: Comment? = nil
    
    func resetPagination() {
        pageNum = 1
        comments = []
        hasMoreComments = false
        totalCount = 0
    }
    
    func submitCommentForStory(storyId: Int64,userId:Int64,content: String,prevId:Int64) async -> (Int64?,Error?){
        let (commentId,err) = await APIClient.shared.CreateStoryComment(storyId: storyId, userId: userId, content: content)
        if err != nil{
            print("submitCommentForStory err:", err as Any)
            return (-1,err)
        }
        print("submitCommentForStory ssuccess")
        return (commentId,nil)
    }
    
    func submitCommentForStoryboard(storyId: Int64,storyboardId: Int64,userId:Int64,content: String) async ->  (Int64?,Error?){
        let (commentId,err) = await APIClient.shared.CreateStoryBoardComment(storyBoardId: storyboardId, user_id: userId, content: content)
        if err != nil{
            print("submitCommentForStoryboard err:", err as Any)
            return (-1,err)
        }
        print("submitCommentForStoryboard ssuccess")
        return (commentId,nil)
    }
    
    

    func fetchStoryComments(storyId: Int64, userId: Int64) async -> ([Comment]?, Error?) {
        let (comments, total, pageNum, pageSize, err) = await APIClient.shared.GetStoryComments(storyId: storyId, user_id: userId, page: Int(self.pageNum), page_size: Int(self.pageSize))
        
        if err != nil {
            print("fetchStoryComments failed: ", err!)
            return (nil, err)
        }
        
        self.pageSize = 10
        self.totalCount = Int(total!)
        
        // 将 Common_StoryComment 列表转换为 Comment 列表
        if let storyComments = comments {
            let convertedComments = storyComments.map { storyComment in
                Comment(
                    id: "\(storyComment.commentID)",
                    realComment: storyComment,
                    commentUser: User(userID: storyComment.creator.userID, name: storyComment.creator.name, avatar: storyComment.creator.avatar)
                )
            }
            
            // 如果是第一页，替换列表；否则追加到现有列表
            if self.pageNum == 1 {
                self.comments = convertedComments
            } else {
                self.comments.append(contentsOf: convertedComments)
            }
            
            // 检查是否还有更多评论
            self.hasMoreComments = self.comments.count < self.totalCount
            
            // 更新页码
            if !convertedComments.isEmpty {
                self.pageNum += 1
            }
            
            return (convertedComments, nil)
        }
        
        return (nil, nil)
    }
    
    func fetchStoryboardComments(storyId: Int64, storyboardId: Int64, userId: Int64) async -> ([Comment]?, Error?) {
        let (comments, total, pageNum, pageSize, err) = await APIClient.shared.GetStoryBoardComments(storyBoardId: storyboardId, user_id: userId, page: Int64(self.pageNum), page_size: Int64(self.pageSize))
        
        if err != nil {
            print("fetchStoryboardComments failed: ", err!)
            return (nil, err)
        }
        
        self.pageSize = 10
        self.totalCount = Int(total!)
        
        // 将 Common_StoryComment 列表转换为 Comment 列表
        if let boardComments = comments {
            let convertedComments = boardComments.map { boardComment in
                Comment(
                    id: "\(boardComment.commentID)",
                    realComment: boardComment,
                    commentUser: User(userID: boardComment.creator.userID, name: boardComment.creator.name, avatar: boardComment.creator.avatar)
                )
            }
            
            // 如果是第一页，替换列表；否则追加到现有列表
            if self.pageNum == 1 {
                self.comments = convertedComments
            } else {
                self.comments.append(contentsOf: convertedComments)
            }
            
            // 检查是否还有更多评论
            self.hasMoreComments = self.comments.count < self.totalCount
            
            // 更新页码
            if !convertedComments.isEmpty {
                self.pageNum += 1
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
    
    func submitReplyForStoryComment(commentId: Int64, userId: Int64, content: String) async -> Error? {
        let (_,err) = await APIClient.shared.CreateStoryCommentReply(commentId: commentId, user_id: userId, content: content)
        if err != nil {
            print("submitReplyForComment failed: ", err!)
            return err
        }
        print("submitReplyForComment success")
        return nil
    }
    
    func fetchCommentReplies(commentId: Int64, userId: Int64) async -> ([Comment]?, Error?) {
        let (replies, _, _, _, err) = await APIClient.shared.GetStoryCommentReplies(
            commentId: commentId,
            user_id: userId,
            page: 1,
            page_size: 50
        )
        
        if err != nil {
            print("fetchCommentReplies failed: ", err!)
            return (nil, err)
        }
        
        if let commentReplies = replies {
            let convertedReplies = commentReplies.map { reply in
                Comment(
                    id: "\(reply.commentID)",
                    realComment: reply,
                    commentUser: User(
                        userID: reply.creator.userID,
                        name: reply.creator.name,
                        avatar: reply.creator.avatar
                    )
                )
            }
            return (convertedReplies, nil)
        }
        
        return (nil, nil)
    }
}



