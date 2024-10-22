//
//  SearchService.swift
//  voyager
//
//  Created by grapestree on 2023/12/5.
//

import Foundation

enum SearchType{
    case SearchProject
    case SearchGroup
    case SearchUser
    case SearchStory
}

extension APIClient {

    public func SearchGroups() async -> ([BranchGroup],Int64,Int64){
        return ([BranchGroup](),0,0)
    }
    public func SearchUsers() async -> ([User],Int64,Int64){
        return ([User](),0,0)
    }

    public func TrendingGroups() async -> ([BranchGroup],Int64,Int64){
        return ([BranchGroup](),0,0)
    }
    public func TrendingUsers() async -> ([User],Int64,Int64){
        return ([User](),0,0)
    }
    
    public func TrendingStorys() async -> ([Story],Int64,Int64){
        return ([Story](),0,0)
    }
    public func TrendingStoryRole() async -> ([StoryRole],Int64,Int64){
        return ([StoryRole](),0,0)
    }
}
