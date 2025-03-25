//
//  CommentViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/3/30.
//

import Foundation

@MainActor
class CommentsViewModel: ObservableObject {
    var pageSize: Int64
    var pageNum: Int64
    @Published var comments = [Comment]()
    init() {
        self.pageSize = 10
        self.pageNum = 0
    }
    
    func submitCommentForStory(storyId: Int64,userId:Int64,content: String,prevId:Int64) async -> Error?{
        return nil
    }
    
    func submitCommentForStoryboard(storyId: Int64,storyboardId: Int64,userId:Int64,content: String,prevId:Int64) async -> Error?{
        return nil
    }
    
    func fetchStoryComments(storyId: Int64,userId: Int64,pageSize: Int64,pageNum: Int64) async -> ([Comment]?,Error?){
        return (nil,nil)
    }
    
    func fetchStoryboardComments() async -> ([Comment]?,Error?){
        return (nil,nil)
    }
    
    
    func likeComments() async ->Error? {
        return nil
    }
}



