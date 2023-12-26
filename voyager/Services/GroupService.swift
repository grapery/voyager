//
//  GroupService.swift
//  voyager
//
//  Created by grapestree on 2023/12/5.
//

import Foundation

extension APIClient {
    func getUserCreateGroups(offset: Int64,size: Int64,ptype: Int32) async throws -> [Project] {
        let items: [Project] = []
        return items
    }
    
    func getJoinedGroups(userId: Int64,projrctId: Int64) async throws -> Project {
        return Project()
    }
    
}
