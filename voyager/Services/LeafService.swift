//
//  LeafService.swift
//  voyager
//
//  Created by grapestree on 2023/12/5.
//

import Foundation

extension APIClient {

    func fetchFeedLeaves(offset: Int64,size: Int64,filter: [String]) async -> ([LeafItem],Int64,Int64) {
        let items: [LeafItem] = []
        return (items,0,0)
    }
    
    func fetchUserLeaves(uid: Int64,offset: Int64,size: Int64,filter: [String]) async  -> ( [LeafItem],Int64,Int64)? {
        let items: [LeafItem] = []
        return (items,0,0)
    }
    
    func fetchGroupLeaves(groupId: Int64,offset: Int64,size: Int64,filter: [String]) async  -> [LeafItem] {
        let items: [LeafItem] = []
        return items
    }
    
    func fetchProjectLeaves(groupId: Int64,projextId: Int64,offset: Int64,size: Int64,filter: [String]) async -> ([LeafItem],Int64,Int64){
        let items: [LeafItem] = []
        return (items,0,0)
    }
}
