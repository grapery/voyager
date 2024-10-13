//
//  StoryboadViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/10/3.
//

import SwiftUI
import Combine


class StoryboadViewModel: ObservableObject{
    @Published var storyId: Int64
    @Published var boardId: Int64
    @Published var userId: Int64 = 0
    @Published var prevBoardId: Int64 = 0
    @Published var nextBoardId: Int64 = -1
    @Published var storyboad: StoryBoard
    var isCreateBoard: Bool = false
    var isForkBoard: Bool = false
    init(storyId: Int64, boardId: Int64, userId: Int64, prevBoardId: Int64, nextBoardId: Int64, storyboad: StoryBoard) {
        self.storyId = storyId
        self.boardId = boardId
        self.userId = userId
        self.prevBoardId = prevBoardId
        self.nextBoardId = nextBoardId
        self.storyboad = storyboad
    }
    func fetchStoryBoardDetail(){
        
    }
    func updateStoryboardDetail(){
        
    }
    func genStoryboardDetail(){
        
    }
    func genStoryboardImages(){
        
    }
    
    func forkStoryBoard(){
        
    }
}
