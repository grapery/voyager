//
//  StoryboardViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/10/5.
//

import SwiftUI
import Combine

class StoryboardViewModel: ObservableObject {
    @Published var storyboard: StoryBoard?
    @Published var storyId: Int64
    @Published var storyboardId:Int64
    var isUpdateOk: Bool = false
    var isCreateOk: Bool = false
    var isForkOk: Bool = false
    var err: Error? = nil
    @Published var userId: Int64
    @Published var prevBoardId: Int64 = 0
    @Published var nextBoardId: Int64 = -1
    @Published var storyboad: StoryBoard
    @Published var isCreateBoard: Bool = false
    @Published var isForkBoard: Bool = false
    
    
    
    init(storyboard: StoryBoard? = nil, storyId: Int64, storyboardId: Int64, userId: Int64, prevBoardId: Int64, nextBoardId: Int64, storyboad: StoryBoard, isCreateBoard: Bool, isForkBoard: Bool) {
        self.storyboard = storyboard
        self.storyId = storyId
        self.storyboardId = storyboardId
        self.userId = userId
        self.prevBoardId = prevBoardId
        self.nextBoardId = nextBoardId
        self.storyboad = storyboad
        self.isCreateBoard = isCreateBoard
        self.isForkBoard = isForkBoard
        Task{
            if !isCreateBoard && !isForkBoard{
                await fetchStoryboard()
            }
        }
    }
    
    private let apiClient = APIClient.shared
    
    func fetchStoryboard() async{
        let (board,err) = await apiClient.GetStoryboard(boardId: self.storyboardId)
        if err != nil {
            print("fetchStoryboard failed: ",err as Any)
            return
        }
        self.storyboard = board
        return
    }
    
    func genStoryboadDetail() async{
        
    }
    
    func genStoryboadImages() async{
        
    }
    
    func genStoryboadVedio() async{
        
    }
    
    func fetchstoryboardGen() async{
        
    }
    
    func updateStoryboad() async{
        
    }
}
