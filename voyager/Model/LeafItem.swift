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
    let text: String?
    let likes: Int
    let replies: Int
    let imageUrl: String?
    let timestamp: Int64
    var user: User?
    init(id: String, ownerUid: String, text: String?, likes: Int, replies: Int, imageUrl: String?, timestamp: Int64, user: User? = nil) {
        self.id = id
        self.ownerUid = ownerUid
        self.text = text
        self.likes = likes
        self.replies = replies
        self.imageUrl = imageUrl
        self.timestamp = timestamp
        self.user = user
    }
    
}


