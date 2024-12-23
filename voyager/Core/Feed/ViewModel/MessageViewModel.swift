//
//  MessageViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/12/3.
//

import Foundation
import SwiftUI
import SwiftData

class ChatContext: Identifiable {
    var id: Int64
    var chatinfo: Common_ChatContext
    init(id: Int64, chatinfo: Common_ChatContext) {
        self.id = id
        self.chatinfo = chatinfo
    }
    static func == (lhs: ChatContext,rhs: ChatContext) -> Bool {
        if lhs.chatinfo.chatID == rhs.chatinfo.chatID {
            return true
        }
        return false
    }
}

class ChatMessage: Identifiable,Equatable {
    var id: Int64
    var msg: Common_ChatMessage
    var type: MessageType = .MessageTypeText
    var status: MessageStatus = .MessageSendSuccess
    var uuid: UUID?
    var mediaURL: String?
    
    var statusInt: NSNumber {
        return NSNumber(value: status.rawValue)
    }
    
    func setStatusFromInt(_ value: NSNumber) {
        if let newStatus = MessageStatus(rawValue: value.int64Value) {
            status = newStatus
        }
    }
    
    init(id: Int64, msg: Common_ChatMessage) {
        self.id = id
        self.msg = msg
        self.uuid = UUID()
    }
    init(id: Int64, msg: Common_ChatMessage,status: MessageStatus) {
        self.id = id
        self.msg = msg
        self.status = status
        self.uuid = UUID()
    }
    static func == (lhs: ChatMessage,rhs: ChatMessage) -> Bool {
        if lhs.msg.uuid == rhs.msg.uuid {
            return true
        }
        return false
    }
}


class MessageViewModel: ObservableObject{
    @Published var userId: Int64
    @Published var page: Int64
    @Published var pageSize: Int64
    @Published var msgCtxs =  [ChatContext]()
    init(userId: Int64, page: Int64, pageSize: Int64) {
        self.userId = userId
        if page == 0 {
            self.page = 0
        }else{
            self.page = page
        }
        
        if pageSize == 0 {
            self.pageSize = 10
        }else{
            self.pageSize = pageSize
        }
    }
    func fetchUserChatContext() async -> ([Common_ChatContext]?,Error?) {
        let (msgCtxs, err) = await APIClient.shared.getUserWithRoleChatList(userId: userId)
        if let err = err {
            print("fetchUserChatContext error: ", err)
            return (nil,err)
        }
        
        // Convert the messages to ChatContext objects
        let chatContexts = msgCtxs?.map { ctx in
            ChatContext(id: ctx.chatID, chatinfo: ctx)
        }
        
        await MainActor.run {
            self.msgCtxs = chatContexts ?? []
        }
        
        return (msgCtxs,nil)
    }
    
    func initUserChatContext() async {
        let (msgCtxs, err) = await APIClient.shared.getUserWithRoleChatList(userId: userId)
        if let err = err {
            print("fetchUserChatContext error: ", err)
            return
        }
        
        // Convert the messages to ChatContext objects
        let chatContexts = msgCtxs?.map { ctx in
            ChatContext(id: ctx.chatID, chatinfo: ctx)
        }
        
        await MainActor.run {
            self.msgCtxs = chatContexts ?? []
        }
        
        return
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
    @Published var messages = [ChatMessage]()
    private let coreDataManager = CoreDataManager.shared
    
    init(userId: Int64, roleId: Int64) {
        self.userId = userId
        self.roleId = roleId
        self.msgContext = Common_ChatContext()
        Task{
            let err = await self.getChatContext(userId: userId, roleId: roleId)
            if err != nil {
                print("MessageContextViewModel init error: ",err as Any)
            }
            //await self.loadMessages(userId: userId, roleId: roleId, chatCtxId: self.msgContext.chatID, timestamp: 0)
        }
    }
    
    init(userId: Int64, roleId: Int64 ,role: StoryRole) {
        self.userId = userId
        self.roleId = roleId
        self.msgContext = Common_ChatContext()
        self.role = role
        Task{
            let err = await self.getChatContext(userId: userId, roleId: roleId)
            if err != nil {
                print("MessageContextViewModel init error: ",err as Any)
            }
            await self.loadMessages(userId: userId, roleId: roleId, chatCtxId: self.msgContext.chatID, timestamp: 0)
            print("init 2",userId,roleId,self.msgContext.chatID)
        }
    }

    func loadMessages(userId: Int64,roleId: Int64,chatCtxId: Int64,timestamp: Int64) async {
        do {
            print(userId," ",roleId," ",chatCtxId)
            coreDataManager.debugPrintAllMessages()
            // 1. 首先加载本地消息
            let localMessages = try coreDataManager.fetchRecentMessages(chatId: msgContext.chatID)
            print("首先加载本地消息: ",localMessages.count)
            DispatchQueue.main.async {
                self.messages = localMessages
            }
            print("localMessages: ",localMessages.count)
            // 2. 然后从服务器获取新消息
            let lastMessageTimestamp = localMessages.last?.msg.timestamp ?? 0
            let (serverMessages,_,err) = await APIClient.shared.getUserChatMessages(userId: userId,roleId: roleId,chatCtxId: chatCtxId,timestamp: lastMessageTimestamp)
            if err != nil {
                print("fetch message error")
                return
            }
            print("serverMessages: ",serverMessages!.count)
            // 3. 保存新消息到本地
            if let messages = serverMessages {
                for message in messages {
                    let chatMst = ChatMessage(id: message.id, msg: message,status: .MessageSendSuccess)
                    try coreDataManager.saveMessage(chatMst)
                }
            }
            
            //Convert server messages to ChatMessage objects before appending
            let newChatMessages = serverMessages?.map { message in
                ChatMessage(id: message.id, msg: message, status: .MessageSendSuccess)
            } ?? []
            
            DispatchQueue.main.async {
                self.messages.append(contentsOf: newChatMessages)
                // Add debug printing
                print("Total messages count: \(self.messages.count)")
            }
            // 4. 清理旧消息
            try await cleanupOldMessages()
            
        } catch {
            print("Error loading messages: \(error)")
        }
    }
    
    private func cleanupOldMessages() async throws {
        try coreDataManager.cleanupOldMessages()
    }
    
    func getChatContext(userId:Int64,roleId: Int64) async -> Error?{
        let (msgContext, err) = await APIClient.shared.createChatWithRoleContext(userId: userId, roleId: roleId)
        print("userId \(userId),roleId \(roleId)")
        if let err = err {
            print("getChatContext error: ", err)
            return err
        }
        // 在主线程上更新 @Published 属性
        await MainActor.run {
            self.msgContext = msgContext!
        }
        
        return nil
    }
    
    func fetchMessages(userId:Int64,chatCtxId: Int64) async -> (ChatMessage?,Error?){
        do {
            // 1. 首先获取 chatCtxId 聊天上下文的最后一条消息的时间戳
            let localMessageTimestamp = try coreDataManager.fetchRecentMessageTimestamp(chatId: msgContext.chatID)
            // 2. 然后从服务器获取新消息
            let (serverMessages,_,err) = await APIClient.shared.getUserChatMessages(userId: userId,roleId: roleId,chatCtxId: chatCtxId,timestamp: localMessageTimestamp)
            if err != nil {
                print("fetch message error")
                return (nil,err)
            }
            if (serverMessages?.count)! > 0 {
                // 3. 保存新消息到本地
                if let messages = serverMessages {
                    for message in messages {
                        let chatMst = ChatMessage(id: message.id, msg: message,status: .MessageSendSuccess)
                        try coreDataManager.saveMessage(chatMst)
                    }
                }
                // 4. Convert server messages to ChatMessage objects before appending
                let newChatMessages = serverMessages?.map { message in
                    ChatMessage(id: message.id, msg: message, status: .MessageSendSuccess)
                } ?? []
                
                DispatchQueue.main.async {
                    self.messages.append(contentsOf: newChatMessages)
                }
            }
        }catch{
            return (nil,NSError(domain: "ChatError", code: -1, userInfo: [NSLocalizedDescriptionKey: "获取历史消息失败"]))
        }
        return  (nil,nil)
    }
    
    func fetchRemoteHistoryMessages(chatCtxId: Int64,timestamp: Int64) async -> (ChatMessage?,Error?){
        do {
            // 1. 首先获取 chatCtxId 聊天上下文的最后一条消息的时间戳
            let localMessageTimestamp = try coreDataManager.fetchRecentMessageTimestamp(chatId: msgContext.chatID)
            // 2. 然后从服务器获取新消息
            let (serverMessages,_,err) = await APIClient.shared.getUserChatMessages(userId: userId,roleId: roleId,chatCtxId: chatCtxId,timestamp: localMessageTimestamp)
            if err != nil {
                print("fetch message error")
                return (nil,err)
            }
            if (serverMessages?.count)! > 0 {
                // 3. 保存新消息到本地
                if let messages = serverMessages {
                    for message in messages {
                        let chatMst = ChatMessage(id: message.id, msg: message,status: .MessageSendSuccess)
                        try coreDataManager.saveMessage(chatMst)
                    }
                }
                // 4. Convert server messages to ChatMessage objects before appending
                let newChatMessages = serverMessages?.map { message in
                    ChatMessage(id: message.id, msg: message, status: .MessageSendSuccess)
                } ?? []
                
                DispatchQueue.main.async {
                    self.messages.insert(contentsOf: newChatMessages, at: 0)
                }
            }
        }catch{
            return (nil,NSError(domain: "ChatError", code: -1, userInfo: [NSLocalizedDescriptionKey: "获取历史消息失败"]))
        }
        return  (nil,nil)
    }
    
    func sendMessage(msg: Common_ChatMessage) async -> ([Common_ChatMessage]?,Error?){
        var waitSendMsgs = [Common_ChatMessage]()
        waitSendMsgs.append(msg)
        let (newMsgs,err) = await APIClient.shared.chatWithStoryRole(userId: self.userId, roleId: self.roleId, msgs: waitSendMsgs)
        if err != nil {
            return (nil,err)
        }
        return (newMsgs,nil)
    }
    
    func fetchHistoryMessages(chatId: Int64,timestamp: Int64,size: Int64) async -> Error?{
        var historyMsg = [ChatMessage]()
        do {
            // 1. 首先加载本地消息
            let localMessages = try coreDataManager.fetchRecentMessagesByTimestamp(chatId: msgContext.chatID,timestamp:timestamp)
            print("加载本地消息: ",localMessages.count)
            DispatchQueue.main.async {
                self.messages.insert(contentsOf: localMessages, at: 0)
            }
            return nil
        } catch {
            print("Error loading messages: \(error)")
            return NSError(domain: "ChatError", code: -1, userInfo: [NSLocalizedDescriptionKey: "获取历史消息失败"])
        }
        return nil
    }
}

