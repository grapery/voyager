//
//  Thread.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation

struct LeafItem: Identifiable, Hashable {
    let id: String
    let ownerUid: String
    let avator: String?
    let text: String?
    let likes: Int
    let replies: Int
    let imageUrl: String?
    let videoUrl: String?
    let content: String?
    let prompt: String?
    let timestamp: Int64
    let prevItem: Int64
    let nextItem: Int64
    let is_leaf: Bool
    init(id: String, ownerUid: String, text: String?, likes: Int, replies: Int, imageUrl: String?, timestamp: Int64,videoUrl: String,content: String,prompt: String,prevItem: Int64,nextItem: Int64,is_leaf: Bool,avator: String) {
        self.id = id
        self.ownerUid = ownerUid
        self.text = text
        self.likes = likes
        self.replies = replies
        self.imageUrl = imageUrl
        self.videoUrl = videoUrl
        self.timestamp = timestamp
        self.content = content
        self.is_leaf = is_leaf
        self.nextItem = nextItem
        self.prevItem = prevItem
        self.prompt = prompt
        self.avator = avator
    }
    
}


