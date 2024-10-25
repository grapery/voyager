//
//  FeedCellViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/3/29.
//

import Foundation


class FeedCellViewModel: ObservableObject {
    @Published var user: User?
    init(user: User? = nil) {
        self.user = user
    }
    
    func like() async{
        //await APIClient.shared.
        print("like buttom is pressed")
    }
    
    func unlike() async{
        //await APIClient.shared.
        print("unlike buttom is pressed")
    }
    
    func fetchItemComments() async -> [Comment] {
        return [Comment]()
    }
    
    func addCommentForItem(comment:Comment) async -> Void{
        return
    }
    
    func share() async{
        //await APIClient.shared.
        print("share buttom is pressed")
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

struct Message: Identifiable {
    let id = UUID()
    var senderName: String
    var avatarName: String
    var content: String
    var timeAgo: String
    var isFromCurrentUser: Bool
}

func sampleMessages() -> [Message] {
    [
        Message(senderName: "豆瓣小组", avatarName: defaultAvator, content: "这个秋天，遇到了心软的神", timeAgo: "3天前", isFromCurrentUser: false),
        Message(senderName: "豆瓣豆品", avatarName: defaultAvator, content: "海獭鹦鹉小熊猫在线卖萌：快来带我回家！", timeAgo: "5个月前", isFromCurrentUser: false),
        Message(senderName: "豆瓣阅读", avatarName: defaultAvator, content: "如果男主迟迟没出现，就先学会当好自己...", timeAgo: "7个月前", isFromCurrentUser: true),
        Message(senderName: "豆瓣", avatarName: defaultAvator, content: "豆瓣2023年度报告发布", timeAgo: "9个月前", isFromCurrentUser: true),
    ]
}
