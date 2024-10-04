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
    @Published var itemId: Int64 = 0
    init(id: String, itemId: Int64) {
        self.id = UUID().uuidString
        self.itemId = itemId
        self.realItem = Common_ItemInfo()
    }
    init(realItem: Common_ItemInfo) {
        self.id = UUID().uuidString
        self.realItem = realItem
    }
    static func == (lhs: StoryItem, rhs: StoryItem) -> Bool {
        if lhs.itemId == rhs.itemId{
            return true
        }
        return false
    }
    func fetchStoryItem(itemId: Int64)async -> Bool {
        //let info = APIClient.shared.fe
        return true
    }
    func formStoryItem()async ->Bool{
       
        return true
    }
}

class StoryBoard: Identifiable {
    var id: Int64
    var boardInfo: Common_StoryBoard
    init(id: Int64, boardInfo: Common_StoryBoard) {
        self.id = id
        self.boardInfo = boardInfo
    }
    static func == (lhs: StoryBoard,rhs: StoryBoard) -> Bool {
        if lhs.id == rhs.id {
            return true
        }
        return false
    }
}



