//
//  Story.swift
//  voyager
//
//  Created by grapestree on 2024/10/23.
//

import Foundation

let defaultStory = Story(Id: -1, storyInfo: Common_Story())

class Story:Identifiable,Hashable{
    var Id: Int64
    var storyInfo: Common_Story
    init(){
        self.Id = 0
        self.storyInfo = Common_Story()
    }
    init(Id: Int64, storyInfo: Common_Story) {
        self.Id = Id
        self.storyInfo = storyInfo
    }
    static func == (lhs: Story,rhs: Story)-> Bool{
        if lhs.id == rhs.id {
            return true
        }
        return false
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class StoryRole: Identifiable, Hashable {
    var Id: Int64
    var role: Common_StoryRole
    init(){
        self.Id = 0
        self.role = Common_StoryRole()
    }
    
    init(Id: Int64, role: Common_StoryRole) {
        self.Id = Id
        self.role = role
    }
    static func == (lhs: StoryRole, rhs: StoryRole) -> Bool {
        return lhs.Id == rhs.Id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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

class StoryBoardActive: Identifiable {
    var id: Int64
    var boardActive: Common_StoryBoardActive
    init(id: Int64, boardActive: Common_StoryBoardActive) {
        self.id = id
        self.boardActive = boardActive
    }
    static func == (lhs: StoryBoardActive,rhs: StoryBoardActive) -> Bool {
        if lhs.id == rhs.id {
            return true
        }
        return false
    }
}
