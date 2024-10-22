//
//  Story.swift
//  voyager
//
//  Created by grapestree on 2024/10/23.
//

import Foundation

let defaultStory = Story(Id: -1, storyInfo: Common_Story())

class Story:Identifiable {
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
}

class StoryRole: Identifiable {
    var Id: String
    var role: Common_StoryRole
    init(){
        self.Id = ""
        self.role = Common_StoryRole()
    }
    
    init(Id: String, role: Common_StoryRole) {
        self.Id = Id
        self.role = role
    }
    static func == (lhs: StoryRole,rhs: StoryRole)-> Bool{
        if lhs.id == rhs.id {
            return true
        }
        return false
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
