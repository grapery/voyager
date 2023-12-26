//
//  LeafService.swift
//  voyager
//
//  Created by grapestree on 2023/12/5.
//

import Foundation

extension APIClient {

    func fetchFeedLeaves(offset: Int64,size: Int64) async throws -> [LeafItem] {
        let items: [LeafItem] = []
        return items
    }
    
    func fetchUserLeaves(uid: UInt64,offset: Int64,size: Int64) async throws -> [LeafItem] {
        let items: [LeafItem] = []
        return items
    }
    
    func fetchGroupLeaves(groupId: UInt64,offset: Int64,size: Int64) async throws -> [LeafItem] {
        let items: [LeafItem] = []
        return items
    }
}
