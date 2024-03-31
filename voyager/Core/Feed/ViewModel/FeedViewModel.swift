//
//  FeedViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation

class FeedViewModel: ObservableObject {
    
    @Published var leaves = [StoryItem]()
    @Published var filters = [String]()
    @Published var page: Int64
    @Published var size: Int64
    @Published var timeStamp: Int64
    @Published var user:User
    
    init(timeStamp: Int64,user: User){
        self.page = 0
        self.size = 20
        self.timeStamp = timeStamp
        self.user = user
    }
    
    @MainActor
    func fetchLeaves() async -> Void{
        let result = await APIClient.shared.fetchUserLeaves(uid: self.user.userID, offset: self.page,size: self.size, filter: [])
        if result?.1 == 0 {
            return
        }
        self.leaves = result?.0 ?? [StoryItem]()
        return
    }
}

class TimeLineModel: ObservableObject{
    @Published var rootId: Int64
    @Published var totalCount: Int64
    @Published var currentId: Int64
    @Published var tags: [String]
    
    init(rootId: Int64, totalCount: Int64, currentId: Int64, tags: [String]) {
        self.rootId = rootId
        self.totalCount = totalCount
        self.currentId = currentId
        self.tags = tags
    }
}
