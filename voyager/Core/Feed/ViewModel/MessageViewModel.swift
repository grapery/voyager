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
    let id: Int64
    var msg: Common_ChatMessage
    var type: MessageType = .MessageTypeText
    var status: MessageStatus = .MessageSendSuccess
    var mediaURL: String?
    init(id: Int64, msg: Common_ChatMessage) {
        self.id = id
        self.msg = msg
    }
    init(id: Int64, msg: Common_ChatMessage,status: MessageStatus) {
        self.id = id
        self.msg = msg
        self.status = status
    }
    static func == (lhs: ChatMessage,rhs: ChatMessage) -> Bool {
        if lhs.msg.id == rhs.msg.id {
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
    
    func createUserChatContext(userId: Int64,roleId: Int64) async -> (Common_ChatContext?,Error?) {
        return (nil,nil)
    }
    
    func delUserChatContext(msgCtxId: Int64) async -> Error? {
        return nil
    }
    
    func saveUserChatContext(msgCtxId: Int64) async -> Error? {
        return nil
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
    
    func fetchMessages() async -> (Common_ChatMessage?,Error?){
        return (nil,nil)
    }
    
    func sendMessage(msg: Common_ChatMessage) async -> ([Common_ChatMessage]?,Error?){
        var waitSendMsgs = [Common_ChatMessage]()
        waitSendMsgs.append(msg)
        let (newMsgs,err) = await APIClient.shared.chatWithStoryRole(msgs: waitSendMsgs)
        if err != nil {
            return (nil,err)
        }
        return (newMsgs,nil)
    }
}

