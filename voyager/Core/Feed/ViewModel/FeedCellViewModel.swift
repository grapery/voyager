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
    @Published var msgContext: Common_ChatContext
    @Published var user: User?
    @Published var role: StoryRole?
    @Published var avator = defaultAvator
    
    var userId: Int64
    var roleId: Int64
 
    var page = 0
    var size = 10
    @Published var messages = [Message]()
    
    init(userId: Int64, roleId: Int64) {
        self.userId = userId
        self.roleId = roleId
        self.msgContext = Common_ChatContext()
        Task{
            let err = await self.getChatContext(userId: userId, roleId: roleId)
            if err != nil {
                print("MessageContextViewModel init error: ",err as Any)
            }
        }
    }
    
    func getChatContext(userId:Int64,roleId: Int64) async -> Error?{
        let (msgContext, err) = await APIClient.shared.createChatWithRoleContext(userId: userId, roleId: roleId)
        if let err = err {
            print("MessageContextViewModel init error: ", err)
            return err
        }
        print("msgContext: ",msgContext as Any)
        
        // 在主线程上更新 @Published 属性
        await MainActor.run {
            self.msgContext = msgContext!
        }
        
        return nil
    }
    
    func fetchMessages() async -> (Error?,Common_ChatMessage?){
        return (nil,nil)
    }
    
    func sendMessage(msg: Common_ChatMessage) async -> Error?{
        return nil
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
