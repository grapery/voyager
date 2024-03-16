//
//  FeedViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation

class FeedViewModel: ObservableObject {
    
    @Published var leaves = [LeafItem]()
    @Published var filters = [String]()
    @Published var page: Int64
    @Published var size: Int64
    @Published var timeStamp: Int64
    
    init(timeStamp: Int64){
        self.page = 0
        self.size = 20
        self.timeStamp = timeStamp
        Task{
            try await self.fetchLeaves()
        }
    }
    
    @MainActor
    func fetchLeaves() async throws{
        self.leaves = try await APIClient.shared.fetchFeedLeaves(offset: self.page,size: self.size)
    }
}

class TimeLineModel: ObservableObject{
    @Published var rootId: Int64
    @Published var totalCount: Int64
    @Published var currentId: Int64
    
    init(rootId: Int64, totalCount: Int64, currentId: Int64) {
        self.rootId = rootId
        self.totalCount = totalCount
        self.currentId = currentId
    }
    
}
