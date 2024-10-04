//
//  LeafService.swift
//  voyager
//
//  Created by grapestree on 2023/12/5.
//

import Foundation

extension APIClient {

    func fetchFeedLeaves(offset: Int64,size: Int64,filter: [String]) async -> ([StoryItem],Int64,Int64) {
        let items: [StoryItem] = []
        return (items,0,0)
    }
    
    func fetchUserLeaves(uid: Int64,offset: Int64,size: Int64,filter: [String]) async  -> ( [StoryItem],Int64,Int64)? {
        let items: [StoryItem] = []
        return (items,0,0)
    }
    
    func fetchGroupLeaves(groupId: Int64,offset: Int64,size: Int64,filter: [String]) async  -> ([StoryItem],Int64,Int64){
        let items: [StoryItem] = []
        return (items,0,0)
    }
    
    func fetchProjectLeaves(groupId: Int64,projectId: Int64,offset: Int64,size: Int64,filter: [String]) async -> ([StoryItem],Int64,Int64){
        let items: [StoryItem] = []
        return (items,0,0)
    }
    // userId check is user is in block list
    // projectId check is project visable os is public
    // filter used to do some option work
    func fetchItemsComment(userId: Int64,itemId: Int64,filter: [String],pageSize: Int64,pageNum : Int64)async -> ([Comment],Int64,Int64) {
        let comments: [Comment] = []
        return(comments,0,0)
    }
    func createCommentForItems(userId: Int64,itemId: Int64,info: Common_CommentInfo) async ->Void {
        return
    }
}
