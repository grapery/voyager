//
//  GroupService.swift
//  voyager
//
//  Created by grapestree on 2023/12/5.
//

import Foundation

extension APIClient {
    func getUserCreateGroups(offset: Int64,size: Int64,ptype: Int32,filter: [String]) async  -> ([Project],Int64,Int64) {
        let items: [Project] = []
        return (items,0,0)
    }
    
    func getJoinedGroups(userId: Int64,filter: [String]) async -> ([Project],Int64,Int64) {
        let items: [Project] = []
        return (items,0,0)
    }
    
    func JoinGroup(userId: Int64,groupId: Int64) async -> Bool{
        return true
    }
    
    func CreateGroup(userId: Int64) async -> Common_GroupInfo{
        return Common_GroupInfo()
    }
}
