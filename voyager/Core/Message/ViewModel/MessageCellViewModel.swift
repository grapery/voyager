//
//  MessageCellViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/18.
//

import Foundation
import SwiftUI


class MessageCellViewModel: ObservableObject {
    var msg: String
    var timeStamp: Int64
    var msgId: Int64
    var image: Image
    var sender: String
    var senderId: Int64
    
    init(msg: String, timestamp: Int64, msgId: Int64, image: Image, sender: String, senderId: Int64) {
        self.msg = msg
        self.timeStamp = timestamp
        self.msgId = msgId
        self.image = image
        self.sender = sender
        self.senderId = senderId
    }
}
