//
//  comments.swift
//  voyager
//
//  Created by grapestree on 2025/3/31.
//

import PhotosUI
import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import Connect
import SwiftUI


extension APIClient {
    func CreateStoryComment(storyId: Int64, userId: Int64,content: String) async -> (Int64?,Error?) {
        let authClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_CreateStoryCommentRequest.with {
            $0.storyID = storyId
            $0.userID = userId
            $0.content = content
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        
        let resp = await authClient.createStoryComment(request: request, headers: header)
        
        if resp.message?.code != Common_ResponseCode.ok {
            // If the response code is not 1, it indicates an error
            return (0,NSError(domain: "CreateStoryComment", code: -1, userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"]))
        }
        return (resp.message?.comment.commentID,nil)
    }

    func GetStoryComments(storyId: Int64,user_id: Int64,page: Int,page_size: Int) async -> ([Common_StoryComment]?,total: Int64?,page: Int64?,page_size: Int64?,Error?) {
        let authClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_GetStoryCommentsRequest.with {
            $0.storyID = storyId
            $0.userID = user_id
            $0.offset = Int64(page)
            $0.pageSize = Int64(page_size)
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let resp = await authClient.getStoryComments(request: request, headers: header)
        if resp.message?.code != Common_ResponseCode.ok {
            return (nil,0,0,0,NSError(domain: "GetStoryComments", code: -1, userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"]))
        }
        return (resp.message?.comments, resp.message?.total, resp.message?.offset, resp.message?.pageSize, nil)
    }

    func DeleteStoryComment(commentId: Int64,user_id: Int64) async -> (Error?) {
        let authClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_DeleteStoryCommentRequest.with {
            $0.commentID = commentId
            $0.userID = user_id
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let resp = await authClient.deleteStoryComment(request: request, headers: header)
        if resp.message?.code != Common_ResponseCode.ok {
            return NSError(domain: "DeleteStoryComment", code: -1, userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
        }
        return nil
    }

    func GetStoryCommentReplies(commentId: Int64,user_id: Int64,page: Int,page_size: Int) async -> ([Common_StoryComment]?,total: Int64?,page: Int64?,page_size: Int64?,Error?) {
        let authClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_GetStoryCommentRepliesRequest.with {
            $0.commentID = commentId
            $0.userID = user_id
            $0.offset = Int64(page)
            $0.pageSize = Int64(page_size)
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let resp = await authClient.getStoryCommentReplies(request: request, headers: header)
        if resp.message?.code != Common_ResponseCode.ok {
            return (nil,0,0,0,NSError(domain: "GetStoryCommentReplies", code: -1, userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"]))
        }
        return (resp.message?.replies, resp.message?.total, resp.message?.offset, resp.message?.pageSize, nil)
    }

    func CreateStoryCommentReply(commentId: Int64,user_id: Int64,content: String) async -> (Int64?,Error?) {
        let authClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_CreateStoryCommentReplyRequest.with {
            $0.commentID = commentId
            $0.userID = user_id
            $0.content = content
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let resp = await authClient.createStoryCommentReply(request: request, headers: header)
        if resp.message?.code != Common_ResponseCode.ok {
            return (0,NSError(domain: "CreateStoryCommentReply", code: -1, userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"]))
        }
        return (resp.message?.comment.commentID,nil)
    }

    func DeleteStoryCommentReply(commentId: Int64,user_id: Int64) async -> (Error?) {
        let authClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_DeleteStoryCommentReplyRequest.with {
            $0.replyID = commentId
            $0.userID = user_id
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let resp = await authClient.deleteStoryCommentReply(request: request, headers: header)
        if resp.message?.code != Common_ResponseCode.ok {
            return NSError(domain: "DeleteStoryCommentReply", code: -1, userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
        }
        return nil
    }

    func GetStoryBoardComments(storyBoardId: Int64,user_id: Int64,page: Int64,page_size: Int64) async -> ([Common_StoryComment]?,total: Int64?,page: Int64?,page_size: Int64?,Error?) {
        let authClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_GetStoryBoardCommentsRequest.with {
            $0.boardID = storyBoardId
            $0.userID = user_id
            $0.offset = Int64(page)
            $0.pageSize = Int64(page_size)
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let resp = await authClient.getStoryBoardComments(request: request, headers: header)
        if resp.message?.code != Common_ResponseCode.ok {
            return (nil,0,0,0,NSError(domain: "GetStoryBoardComments", code: -1, userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"]))
        }
        return (resp.message?.comments, resp.message?.total, resp.message?.offset, resp.message?.pageSize, nil)
    }

    func CreateStoryBoardComment(storyBoardId: Int64,user_id: Int64,content: String) async -> (Int64?,Error?){
        let authClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_CreateStoryBoardCommentRequest.with {
            $0.boardID = storyBoardId
            $0.userID = user_id
            $0.content = content
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let resp = await authClient.createStoryBoardComment(request: request, headers: header)
        if resp.message?.code != Common_ResponseCode.ok {
            return (0,NSError(domain: "CreateStoryBoardComment", code: -1, userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"]))
        }
        return (resp.message?.comment.commentID,nil)
    }

    func DeleteStoryBoardComment(commentId: Int64,user_id: Int64) async -> (Error?) {
        let authClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_DeleteStoryBoardCommentRequest.with {
            $0.commentID = commentId
            $0.userID = user_id
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let resp = await authClient.deleteStoryBoardComment(request: request, headers: header)
        if resp.message?.code != Common_ResponseCode.ok {
            return NSError(domain: "DeleteStoryBoardComment", code: -1, userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
        }
        return nil
    }

    func GetStoryBoardCommentReplies(commentId: Int64,user_id: Int64,page: Int64,page_size: Int64) async -> ([Common_StoryComment]?,total: Int64?,page: Int64?,page_size: Int64?,Error?) {
        let authClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_GetStoryBoardCommentRepliesRequest.with {
            $0.commentID = commentId
            $0.userID = user_id
            $0.offset = Int64(page)
            $0.pageSize = page_size
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let resp = await authClient.getStoryBoardCommentReplies(request: request, headers: header)
        if resp.message?.code != Common_ResponseCode.ok {
            return (nil,0,0,0,NSError(domain: "GetStoryBoardCommentReplies", code: -1, userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"]))
        }
        return (resp.message?.replies, resp.message?.total, resp.message?.offset, resp.message?.pageSize, nil)
    }

    // func CreateStoryBoardCommentReply(commentId: Int64,user_id: Int64,content: String) async -> (Error?) {
    //     let authClient = Common_TeamsApiClient(client: self.client!)
    //     let request = Common_CreateStoryBoardCommentReplyRequest.with {
    //         $0.commentID = commentId
    //         $0.userID = user_id
    //         $0.content = content
    //     }
    //     var header = Connect.Headers()
    //     header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
    //     let resp = await authClient.createStoryBoardCommentReply(request: request, headers: header) 
    //     if resp.message?.code != Common_ResponseCode.ok {
    //         return NSError(domain: "CreateStoryBoardCommentReply", code: -1, userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
    //     }
    //     return nil
    // }
    
    func LikeComment(commentId: Int64,user_id: Int64) async -> (Error?) {
        let authClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_LikeCommentRequest.with {
            $0.commentID = commentId
            $0.userID = user_id
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let resp = await authClient.likeComment(request: request, headers: header)
        if resp.message?.code != Common_ResponseCode.ok {
            return NSError(domain: "LikeComment", code: -1, userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
        }
        return nil
    }

    func DislikeComment(commentId: Int64,user_id: Int64) async -> (Error?) {
        let authClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_DislikeCommentRequest.with {
            $0.commentID = commentId
            $0.userID = user_id
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let resp = await authClient.dislikeComment(request: request, headers: header)
        if resp.message?.code != Common_ResponseCode.ok {
            return NSError(domain: "DislikeComment", code: -1, userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
        }
        return nil
    }
    
}
