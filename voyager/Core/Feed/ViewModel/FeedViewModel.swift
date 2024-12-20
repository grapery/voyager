//
//  FeedViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation

class FeedViewModel: ObservableObject {
    @Published var groups: [BranchGroup]
    @Published var timeline: Int64
    @Published var storys: [Story]
    @Published var userId: Int64
    @Published var roles: [StoryRole]
    @Published var boards: [StoryBoard]
    @Published var filters = [String]()
    
    @Published var trendingStories: [Story]
    @Published var trendingRoles: [StoryRole]
    @Published var trendingBoards: [StoryBoard]
    @Published var trendingFilters = [String]()
    @Published var trendingGroups: [BranchGroup]
    
    @Published var feedActives: [ActiveFeed]
    
    @Published var page: Int64
    @Published var size: Int64
    @Published var timeStamp: Int64
    @Published var tags: [String]
    @Published @MainActor var searchText: String = ""
    @Published @MainActor var activeFlowType: Common_ActiveFlowType = Common_ActiveFlowType(rawValue: 1)!
   
    @MainActor
    func performSearch() async {
       // Implement search logic here based on the selected tab and searchText
    }
    
    init(userId: Int64) {
        self.groups = [BranchGroup]()
        self.timeline = 0
        self.storys = [Story]()
        self.filters = [String]()
        self.timeStamp = 0
        self.userId = userId
        self.tags = [String]()
        self.roles = [StoryRole]()
        self.boards = [StoryBoard]()
        
        self.trendingFilters = [String]()
        self.trendingStories = [Story]()
        self.trendingGroups = [BranchGroup]()
        self.trendingRoles = [StoryRole]()
        self.trendingBoards = [StoryBoard]()
        
        self.feedActives = [ActiveFeed]()
        
        self.page = 0
        self.size = 10
    }

    @MainActor
    func fetchActives() async -> Void{
        let result = await APIClient.shared.fetchActives(userId: self.userId, offset: self.page, size: self.size, timestamp: self.timeStamp, activeType: self.activeFlowType, filter: [String]())
        if result.3 != nil {
            return
        }
        self.feedActives = result.0!.map { activeInfo in
            ActiveFeed(active: activeInfo)
        }
        self.page = result.1
        self.size = result.2
        return
    }
    
    @MainActor
    func fetchGroups() async -> Void{
        let result = await APIClient.shared.fetchUserWatchedGroup(userId: self.userId, offset: self.page, size: self.size, filter: self.filters)
        if result.3 != nil {
            print("fetchGroups failed: ",result.3!)
            return
        }
        self.groups = result.0
        self.page = result.1
        self.size = result.2
        return
    }
    
    @MainActor
    func fetchStorys() async -> Void{
        let result = await APIClient.shared.fetchUserTakepartinStorys(userId: self.userId, offset: self.page, size: self.size, filter: self.filters)
        if result.3 != nil {
            print("fetchStorys failed: ",result.3!)
            return
        }
        self.storys = result.0
        self.page = result.1
        self.size = result.2
        return
    }
    
    @MainActor
    func fetchStoryRoles() async -> Void{
        let result = await APIClient.shared.fetchStoryRoles(userId: self.userId, offset: self.page, size: self.size, filter: self.filters)
        if result.3 != nil {
            print("fetchStoryRoles failed: ",result.3!)
            return
        }
        self.roles = result.0
        self.page = result.1
        self.size = result.2
        return
    }
    
    @MainActor
    func fetchTrendingGroups() async -> Void{
        let result = await APIClient.shared.fetchTrendingGroup(userId: self.userId, offset: self.page, size: self.size, filter: self.filters)
        if result.3 != nil {
            print("fetchTrendingGroups failed: ",result.3!)
            return
        }
        self.groups = result.0
        self.page = result.1
        self.size = result.2
        return
    }
    
    @MainActor
    func fetchTrendingStorys() async -> Void{
        let result = await APIClient.shared.fetchTrendingStorys(userId: self.userId, offset: self.page, size: self.size, filter: self.filters)
        if result.3 != nil {
            print("fetchTrendingStorys failed: ",result.3!)
            return
        }
        self.storys = result.0
        self.page = result.1
        self.size = result.2
        return
    }
    
    @MainActor
    func fetchTrendingStoryRoles() async -> Void{
        let result = await APIClient.shared.fetchTrendingStoryRoles(userId: self.userId, offset: self.page, size: self.size, filter: self.filters)
        if result.3 != nil {
            print("fetchTrendingStoryRoles failed: ",result.3!)
            return
        }
        self.roles = result.0
        self.page = result.1
        self.size = result.2
        return
    }
    
    @MainActor
    func fetchUserCreatedStoryBoards() async -> Void{
        let result = await APIClient.shared.fetchUserCreatedStoryBoards(userId: self.userId, page: self.page, size: self.size, storyId:0)
        if result.3 != nil {
            print("fetchUserCreatedStoryBoards failed: ",result.3!)
            return
        }
        self.boards = result.0!
        self.page = result.1
        self.size = result.2
        return
    }
    
    // 重置分页参数
    func resetPagination() {
        self.page = 0
        self.size = 20  // 或其他默认值
        self.timeStamp = 0
    }
    
    // 根据 FeedType 设置对应的 activeFlowType
    @MainActor func setActiveFlowType(for type: FeedType) {
        switch type {
        case .Groups:
            self.activeFlowType = Common_ActiveFlowType.groupFlowType
        case .Story:
            self.activeFlowType = Common_ActiveFlowType.storyFlowType
        case .StoryRole:
            self.activeFlowType = Common_ActiveFlowType.roleFlowType
        }
    }
}
