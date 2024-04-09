//
//  StoryItem.swift
//  voyager
//
//  Created by grapestree on 2024/3/26.
//

import Foundation

class StoryItem: Identifiable,Equatable{
    @Published var user: User
//    @Published var project: Project
//    @Published var group: BranchGroup
//    @Published var timeline: TimeBranch
    @Published var itemId: Int64 = 0
    @Published var items: [LeafItem]
    @Published var projectId: Int64 = 0
    @Published var prevItem: Int64
    @Published var nextItem: Int64
    @Published var ableFork: Bool
    var likes: Int64
    static func == (lhs: StoryItem, rhs: StoryItem) -> Bool {
        if lhs.itemId == rhs.itemId{
            return true
        }
        return false
    }
    init(user: User, itemId: Int64) {
        self.user = user
        self.itemId = itemId
        self.items = items
        self.prevItem = 0
        self.nextItem = 0
        self.likes = 0
    }
    func fetchStoryItem()async -> Bool {
        
    }
    func formStoryItem()async ->Bool{
        if !self.ableFork{
            return false
        }
        return true
    }
}
