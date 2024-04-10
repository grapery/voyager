//
//  StoryItem.swift
//  voyager
//
//  Created by grapestree on 2024/3/26.
//

import Foundation


class StoryItem: Identifiable{
    var id: String
    var realItem: Common_ItemInfo
    @Published var user: User
    @Published var itemId: Int64 = 0
    var prevItem = 0
    var nextItem = 0
    var ableFork = true
    init(id: String, user: User, itemId: Int64) {
        self.id = UUID().uuidString
        self.itemId = itemId
    }
    init(user: User,realItem: Common_ItemInfo) {
        self.id = UUID().uuidString
        self.realItem = realItem
        self.user = user
    }
    static func == (lhs: StoryItem, rhs: StoryItem) -> Bool {
        if lhs.itemId == rhs.itemId{
            return true
        }
        return false
    }
    func fetchStoryItem(itemId: Int64)async -> Bool {
        let info = APIClient.shared.fe
        return true
    }
    func formStoryItem()async ->Bool{
        if !self.ableFork{
            return false
        }
        return true
    }
}

