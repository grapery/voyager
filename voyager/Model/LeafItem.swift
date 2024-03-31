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
    let ownerUid: String
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
    let is_leaf: Bool
}


