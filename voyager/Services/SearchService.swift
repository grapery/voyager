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
        
    }
    public func SearchGroups() async -> ([BranchGroup],Int64,Int64){
        
    }
    public func SearchUsers() async -> ([User],Int64,Int64){
        
    }
    public func SearchProjects() async -> ([],Int64,Int64){
        
    }
}
