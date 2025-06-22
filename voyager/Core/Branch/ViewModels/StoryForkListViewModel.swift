//
//  StoryForkListViewModel.swift
//  voyager
//
//  Created by Grapes Suo on 2025/6/21.
//

import SwiftUI
import Combine


// MARK: - ViewModel
class StoryForkListViewModel: ObservableObject {
    @Published var forkedStoryboards: [Common_StoryBoardActive] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let storyboardId: Int64
    private var cancellables = Set<AnyCancellable>()
    
    init(storyboardId: Int64) {
        self.storyboardId = storyboardId
    }
    
    func fetchForks() {
        isLoading = true
        errorMessage = nil
        
        // 模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // 在这里替换为真实的网络请求逻辑
            // 例如: let (forks, error) = await StoryService.fetchForks(for: self.storyboardId)
            
            // --- 模拟数据 ---
            
            // --- 模拟结束 ---
            
            // 找到初始故事板并将其放在首位
            if let initialIndex = self.forkedStoryboards.firstIndex(where: { $0.storyboard.storyBoardID == self.storyboardId }) {
                let initialStoryboard = self.forkedStoryboards.remove(at: initialIndex)
                self.forkedStoryboards.insert(initialStoryboard, at: 0)
            }
            
            self.isLoading = false
        }
    }
}

