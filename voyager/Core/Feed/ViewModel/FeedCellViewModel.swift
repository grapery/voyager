//
//  FeedCellViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/3/29.
//

import Foundation


class FeedCellViewModel: ObservableObject {
    @Published var user: User?
    @Published var items: StoryItem?
    init(user: User? = nil, items: StoryItem? = nil) {
        self.user = user
        self.items = items
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

class MessageContext: ObservableObject{
    @Published var msg_ctx_id: Int64
    @Published var creatorId = -1
    @Published var users = [User]()
    @Published var roles = [StoryRole]()
    @Published var avator = defaultAvator
    @Published var currentId = 0
    var page = 0
    var size = 10
    @Published var msgs = [Message]()
    init(msg_ctx_id: Int64) {
        self.msg_ctx_id = msg_ctx_id
    }
    
    func sendMsg(senderId: Int64,recviId: Int64) async -> Void{
        self.currentId = self.currentId + 1
        return
    }
    
    func recvMsg() async -> Void{
        self.currentId = self.currentId + 1
    }
    
    func fetchMsg() async -> Void{
        
    }
}

struct Message: Identifiable {
    let id = UUID()
    let senderName: String
    let avatarName: String
    let content: String
    let timeAgo: String
    let unreadCount: Int
}

func sampleMessages() -> [Message] {
    [
        Message(senderName: "豆瓣小组", avatarName: defaultAvator, content: "这个秋天，遇到了心软的神", timeAgo: "3天前", unreadCount: 1),
        Message(senderName: "豆瓣豆品", avatarName: defaultAvator, content: "海獭鹦鹉小熊猫在线卖萌：快来带我回家！", timeAgo: "5个月前", unreadCount: 2),
        Message(senderName: "豆瓣阅读", avatarName: defaultAvator, content: "如果男主迟迟没出现，就先学会当好自己...", timeAgo: "7个月前", unreadCount: 3),
        Message(senderName: "豆瓣", avatarName: defaultAvator, content: "豆瓣2023年度报告发布", timeAgo: "9个月前", unreadCount: 0),
    ]
}
