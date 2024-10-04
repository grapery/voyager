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
    public func SearchProjects() async -> ([Project],Int64,Int64){
        return ([Project](),0,0)
    }
    public func SearchGroups() async -> ([BranchGroup],Int64,Int64){
        return ([BranchGroup](),0,0)
    }
    public func SearchUsers() async -> ([User],Int64,Int64){
        return ([User](),0,0)
    }
    
    public func TrendingProjects() async -> [Project]{
        return [Project]()
    }
    public func TrendingGroups() async -> [BranchGroup]{
        return [BranchGroup]()
    }
    public func TrendingUsers() async -> [User]{
        return [User]()
    }
}
