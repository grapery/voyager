//
//  StoryItem.swift
//  voyager
//
//  Created by grapestree on 2024/3/26.
//

import Foundation

class StoryItem: Identifiable,Equatable{
    var itemId: Int64 = 0
    static func == (lhs: StoryItem, rhs: StoryItem) -> Bool {
        if lhs.itemId == rhs.itemId{
            return true
        }
        return false
    }
    
}
