//
//  MessageViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/18.
//

import Foundation

class ChatMessageViewModel: ObservableObject {
    var msgList: MessageCellViewModel
    var offset: Int64 = 0
    var batchSize: Int64 = 0
    var timestamp: Int64 = 0
    var isMsgStored: Bool
    var currentOperator: User
    
    //var msgTitle: <String,Int64>
    init(msgList: MessageCellViewModel, offset: Int64, batchSize: Int64, timestamp: Int64, isMsgStored: Bool, currentOperator: User) {
        self.msgList = msgList
        self.offset = offset
        self.batchSize = batchSize
        self.timestamp = timestamp
        self.isMsgStored = isMsgStored
        self.currentOperator = currentOperator
    }
    // 如果已经是付费用户，存储聊天记录后拉取
    // 如果不是付费用户，只可以拉取本地存储的聊天记录
    func fetchMsgFlow(){
        if self.currentOperator.email.isEmpty {
            
        }
    }
}

