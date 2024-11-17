//
//  FeedCellViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/3/29.
//

import Foundation


class FeedCellViewModel: ObservableObject {
    @Published var user: User?
    let storyId: Int64
    let storyboardId: Int64
    let roleId: Int64
    
    init(user: User? = nil) {
        self.user = user
        self.storyId = 0
        self.storyboardId = 0
        self.roleId = 0
    }
    init(user: User? = nil,storyId:Int64) {
        self.user = user
        self.storyId = storyId
        self.storyboardId = 0
        self.roleId = 0
    }
    
    init(user: User? = nil,storyId:Int64,storyboardId:Int64) {
        self.user = user
        self.storyId = storyId
        self.storyboardId = storyboardId
        self.roleId = 0
    }
    
    init(user: User? = nil,storyId:Int64,roleId:Int64) {
        self.user = user
        self.storyId = storyId
        self.storyboardId = 0
        self.roleId = roleId
    }
    
    func likeStory() async{
        let err = await APIClient.shared.LikeStory(storyId: self.storyId, userId: self.user!.userID)
        if err != nil{
            print("likeStoryboard failed: ",err!)
        }
    }
    
    func unlikeStory() async{
        let err = await APIClient.shared.UnLikeStory(storyId: self.storyId, userId: self.user!.userID)
        if err != nil{
            print("likeStoryboard failed: ",err!)
        }
    }
    
    func likeStoryboard() async{
        let err = await APIClient.shared.LikeStoryboard(boardId: self.storyboardId, storyId: self.storyId, userId: self.user!.userID)
        if err != nil{
            print("likeStoryboard failed: ",err!)
        }
    }
    
    func unlikeStoryboard() async{
        let err = await APIClient.shared.UnLikeStoryboard(boardId: self.storyboardId, storyId: self.storyId, userId: self.user!.userID)
        if err != nil{
            print("likeStoryboard failed: ",err!)
        }
    }
    
    func likeStoryRole() async{
        let err = await APIClient.shared.LikeStoryboard(boardId: self.storyboardId, storyId: self.storyId, userId: self.user!.userID)
        if err != nil{
            print("likeStoryboard failed: ",err!)
        }
    }
    
    func unlikeStoryRole() async{
        let err = await APIClient.shared.LikeStoryboard(boardId: self.storyboardId, storyId: self.storyId, userId: self.user!.userID)
        if err != nil{
            print("likeStoryboard failed: ",err!)
        }
    }
    
    func fetchStoryboardComments() async -> [Comment] {
        return [Comment]()
    }
    
    func addCommentForStoryboard(comment:Comment) async -> Void{
        return
    }
}


class MessageViewModel: ObservableObject{
    @Published var userId: Int64
    @Published var page: Int64
    @Published var pageSize: Int64
    @Published var msgCtxIds =  [Int64]()
    init(userId: Int64, page: Int64, pageSize: Int64) {
        self.userId = userId
        self.page = page
        self.pageSize = pageSize
    }
    func fetchLatestMessages() async ->Void{
        
    }
}

class MessageContextViewModel: ObservableObject{
    @Published var msg_ctx_id: Int64
    @Published var creatorId = -1
    @Published var users = [User]()
    @Published var roles = [StoryRole]()
    @Published var avator = defaultAvator
    @Published var currentId = 0
 
    var page = 0
    var size = 10
    @Published var messages = [Message]()
    init(msg_ctx_id: Int64) {
        self.msg_ctx_id = msg_ctx_id
    }
    
    func sendMessage() async -> Void{
        self.currentId = self.currentId + 1
        return
    }
    
    func recvMessage() async -> Void{
        self.currentId = self.currentId + 1
    }
    
    func fetchMessages() async -> Void{
        
    }
}

struct Message: Identifiable,Equatable {
    let id = UUID()
    var senderName: String
    var avatarName: String
    var content: String
    var timeAgo: String
    var isFromCurrentUser: Bool
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}
