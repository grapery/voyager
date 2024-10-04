//
//  Project.swift
//  voyager
//
//  Created by grapestree on 2023/11/18.
//

import Foundation

typealias Project = Common_ProjectInfo

//class Project: Identifiable {
//    var Id: String
//    var projectInfo: Common_ProjectInfo
//    init(Id: String, projectInfo: Common_ProjectInfo) {
//        self.Id = Id
//        self.projectInfo = projectInfo
//    }
//}

typealias ProjectProfile = Common_ProjectProfileInfo

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
