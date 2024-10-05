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
    @Published var isLoading: Bool = false
    @Published var storyId: Int64
    var storyboardId:Int64
    var isUpdateOk: Bool = false
    var err: Error? = nil
    var userId: Int64
    init(storyId: Int64,storyboardId: Int64,userId: Int64) {
        self.storyId = storyId
        self.userId = userId
        self.storyboardId = storyboardId
        Task{
            await fetchStoryboard()
        }
    }
    
    private let apiClient = APIClient.shared
    
    func fetchStoryboard()async{
        
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
