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
    
    @Published var page: Int64
    @Published var size: Int64
    @Published var timeStamp: Int64
    @Published var tags: [String]
    @Published @MainActor var searchText: String = ""
   
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
        
        self.page = 0
        self.size = 0
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
        let result = await APIClient.shared.fetchUserFriendStoryRoles(userId: self.userId, offset: self.page, size: self.size, filter: self.filters)
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
        let result = await APIClient.shared.fetchUserCreatedStoryBoards(userId: self.userId, offset: self.page, size: self.size, filter: self.filters)
        if result.3 != nil {
            print("fetchUserCreatedStoryBoards failed: ",result.3!)
            return
        }
        self.boards = result.0
        self.page = result.1
        self.size = result.2
        return
    }
    
}
