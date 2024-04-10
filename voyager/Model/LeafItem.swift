//
//  Thread.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation

// 仅仅是图片、文字、视频的contaniner
struct LeafItem: Identifiable, Hashable {
    let id: String
    let ownerUid: Int64
    let avator: String?
    let text: String?
    let title: String
    let likes: Int
    let replies: Int
    let imageUrl: String?
    let videoUrl: String?
    let content: String?
    let prompt: String?
    let timestamp: Int64
    
    init(info: Common_ItemInfo) {
        self.id = UUID().uuidString
        self.ownerUid = info.userID
        self.avator = "avator"
        self.text = ""
        self.title = info.title
        self.likes = 0
        self.replies = 0
        self.imageUrl = "imageUrl"
        self.videoUrl = "videoUrl"
        self.content = "content"
        self.prompt = "prompt"
        self.timestamp = 0
    }
}



