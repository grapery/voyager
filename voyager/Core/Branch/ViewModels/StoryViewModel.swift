//
//  StoryViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/9/24.
//

import SwiftUI
import Combine


class StoryViewModel: ObservableObject {
    @Published var story: Story?
    @Published var isLoading: Bool = false
    @Published var storyId: Int64
    @Published var storyboards:[StoryBoard]?
    var isUpdateOk: Bool = false
    var err: Error? = nil
    init(storyId: Int64) {
        self.storyId = storyId
        Task{
            await fetchStory()
        }
    }
    
    private let apiClient = APIClient.shared
    
    func fetchStory() async {
        let currentStoryId: Int64 = getCurrentStoryId()
        print("fetchStory id ",self.storyId)
        do {
            let fetchedStory = await apiClient.GetStory(storyId: currentStoryId)
            print("fetchStory fetchedStory ",fetchedStory.self.0)
            if fetchedStory.self.1 == nil {
                self.story = fetchedStory.self.0
                self.isLoading = false
                self.err = nil
            }
        } catch {
            self.err = ("Error fetching story: \(error.localizedDescription)" as! any Error)
            self.isLoading = false
        }
        print("fetchStory story ",self.story?.storyInfo)
    }
    
    // 添加一个方法来获取当前的 storyId
    private func getCurrentStoryId() -> Int64 {
        // 这里应该实现获取当前 storyId 的逻辑
        // 可能从用户选择、路由参数或其他来源获取
        // 暂时返回一个默认值或占位符
        return self.storyId
    }
    
    func updateStory() async  {
        guard let story = story else { return }
        isLoading = true
        
        do {
            let updatedStory =  await apiClient.UpdateStory(storyId: self.storyId, short_desc: story.storyInfo.desc, status: Int64(story.storyInfo.status), isAiGen: story.storyInfo.isAiGen, origin: story.storyInfo.origin, params: story.storyInfo.params)
            if updatedStory.self.1 != nil {
                self.isUpdateOk = false
            }else {
                self.isUpdateOk = true
                self.storyId = updatedStory.self.0
            }
        } catch {
            self.err = error
            self.isLoading = false
            
        }
    }
    
    func fetchStoryBoards(page:Int64,size:Int64,userId:Int64,branchId:Int64){
        
    }
}


