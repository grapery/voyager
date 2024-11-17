//
//  LeafService.swift
//  voyager
//
//  Created by grapestree on 2023/12/5.
//

import Foundation

extension APIClient {
    
    func fetchUserWatchedGroup(userId: Int64,offset: Int64,size: Int64,filter: [String]) async  -> ( [BranchGroup],Int64,Int64,Error?) {
        let groups: [BranchGroup] = []
        // 用户创建的,用户关注的,用户参与的
        return (groups,0,0,nil)
    }
    
    func fetchUserTakepartinStorys(userId: Int64,offset: Int64,size: Int64,filter: [String]) async  -> ([Story],Int64,Int64,Error?){
        // 用户创建的,用户参与的
        let storys: [Story] = []
        return (storys,0,0,nil)
    }
    
    func fetchStoryRoles(userId: Int64,offset: Int64,size: Int64,filter: [String]) async -> ([StoryRole],Int64,Int64,Error?){
        // 用户创建的,用户关注的,用户参与的
        let roles: [StoryRole] = []
        return (roles,0,0,nil)
    }
    
    func fetchUserCreatedStoryBoards(userId: Int64,offset: Int64,size: Int64,filter: [String]) async -> ([StoryBoard],Int64,Int64,Error?){
        // 用户创建的
        let roles: [StoryBoard] = []
        return (roles,0,0,nil)
    }

    func createCommentForBoards(userId: Int64,boardId: Int64,info: Comment) async ->Void {
        return
    }
    
    func getBoardComments(userId: Int64,boardId: Int64) async ->([Comment],Error?) {
        let comments: [Comment] = []
        return (comments,nil)
    }
    
    func fetchTrendingGroup(userId: Int64,offset: Int64,size: Int64,filter: [String]) async  -> ( [BranchGroup],Int64,Int64,Error?) {
        let groups: [BranchGroup] = []
        return (groups,0,0,nil)
    }
    
    func fetchTrendingStorys(userId: Int64,offset: Int64,size: Int64,filter: [String]) async  -> ([Story],Int64,Int64,Error?){
        let storys: [Story] = []
        return (storys,0,0,nil)
    }
    
    func fetchTrendingStoryRoles(userId: Int64,offset: Int64,size: Int64,filter: [String]) async -> ([StoryRole],Int64,Int64,Error?){
        let roles: [StoryRole] = []
        return (roles,0,0,nil)
    }
}


