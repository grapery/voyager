//
//  FeedCellViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/3/29.
//

import Foundation
import SwiftUI
import SwiftData

class FeedCellViewModel: ObservableObject {
    @Published var user: User?
    let storyId: Int64
    let storyboardId: Int64
    let roleId: Int64
    
    init(user: User? = nil) {
        self.user = user
        self.storyId = 0
        self.storyboardId = 0
        self.roleId = 0
    }
    init(user: User? = nil,storyId:Int64) {
        self.user = user
        self.storyId = storyId
        self.storyboardId = 0
        self.roleId = 0
    }
    
    init(user: User? = nil,storyId:Int64,storyboardId:Int64) {
        self.user = user
        self.storyId = storyId
        self.storyboardId = storyboardId
        self.roleId = 0
    }
    
    init(user: User? = nil,storyId:Int64,roleId:Int64) {
        self.user = user
        self.storyId = storyId
        self.storyboardId = 0
        self.roleId = roleId
    }
    
    func likeStory() async{
        let err = await APIClient.shared.LikeStory(storyId: self.storyId, userId: self.user!.userID)
        if err != nil{
            print("likeStoryboard failed: ",err!)
        }
    }
    
    func unlikeStory() async{
        let err = await APIClient.shared.UnLikeStory(storyId: self.storyId, userId: self.user!.userID)
        if err != nil{
            print("likeStoryboard failed: ",err!)
        }
    }
    
    func likeStoryboard() async{
        let err = await APIClient.shared.LikeStoryboard(boardId: self.storyboardId, storyId: self.storyId, userId: self.user!.userID)
        if err != nil{
            print("likeStoryboard failed: ",err!)
        }
    }
    
    func unlikeStoryboard() async{
        let err = await APIClient.shared.UnLikeStoryboard(boardId: self.storyboardId, storyId: self.storyId, userId: self.user!.userID)
        if err != nil{
            print("likeStoryboard failed: ",err!)
        }
    }
    
    func likeStoryRole() async{
        let err = await APIClient.shared.LikeStoryRole(roleId: self.roleId, storyId: self.storyId, userId: self.user!.userID)
        if err != nil{
            print("likeStoryboard failed: ",err!)
        }
    }
    
    func unlikeStoryRole() async{
        let err = await APIClient.shared.UnLikeStoryRole(roleId: self.roleId, storyId: self.storyId, userId: self.user!.userID)
        if err != nil{
            print("likeStoryboard failed: ",err!)
        }
    }
    
    func fetchStoryboardComments(storyId:Int64,boardId:Int64,userId:Int64) async -> [Comment] {
        return [Comment]()
    }
    
    func addCommentForStoryboard(comment:Comment,userId:Int64) async -> Void{
        return
    }
    
    func delCommentForStoryboard(comment:Comment,userId:Int64) async -> Void{
        return
    }
    
    func upvoteCommentForStoryboard(comment:Comment,userId:Int64)async -> Void{
        return
    }
        
}



