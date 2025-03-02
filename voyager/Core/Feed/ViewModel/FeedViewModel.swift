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
    @Published var user: User
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
    @Published @MainActor var activeFlowType: Common_ActiveFlowType = Common_ActiveFlowType(rawValue: 3)!
   
    @MainActor
    func performSearch() async {
       // Implement search logic here based on the selected tab and searchText
    }
    
    init(user: User) {
        self.groups = [BranchGroup]()
        self.timeline = 0
        self.storys = [Story]()
        self.filters = [String]()
        self.timeStamp = 0
        self.userId = user.userID
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
        self.user = user
    }

    @MainActor
    func fetchActives() async -> Void{
        let result = await APIClient.shared.fetchActives(userId: self.userId, offset: self.page, size: self.size, timestamp: self.timeStamp, activeType: self.activeFlowType, filter: [String]())
        if result.3 != nil {
            print("fetchActives error: ",result.3 as Any)
            return
        }
        self.feedActives = result.0!.map { activeInfo in
            ActiveFeed(active: activeInfo)
        }
        print("self.feedActives: ",result.0 as Any)
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


// 添加 ViewModel 来管理数据加载
class FeedListViewModel: ObservableObject {
    @Published var storyBoardActives: [Common_StoryBoardActive] = []
    @Published var isLoading = false
    @Published var hasError = false
    @Published var errorMessage = ""
    
    private let userId: Int64
    private var currentOffset: Int64 = 0
    private let pageSize: Int64 = 10
    private var hasMoreData = true
    private let storyService = APIClient.shared
    
    init(userId: Int64) {
        self.userId = userId
    }
    
    @MainActor
    func refreshData() async {
        guard !isLoading else { return }
        
        isLoading = true
        hasError = false
        currentOffset = 0
        
        do {
            let (boards, offset, size, error) = await storyService.storyActiveStoryBoards(
                userId: userId,
                storyId: 0,
                offset: 0,
                pageSize: pageSize,
                filter: ""
            )
            print("refreshData: \(String(describing: boards))")
            if let error = error {
                hasError = true
                errorMessage = error.localizedDescription
                return
            }
            
            if let boards = boards {
                storyBoardActives = boards
                currentOffset = offset ?? 0
                hasMoreData = boards.count >= pageSize
            }
        } catch {
            hasError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func loadMoreData() async {
        guard !isLoading && hasMoreData else { return }
        
        isLoading = true
        hasError = false
        
        do {
            let (boards, offset, size, error) = await storyService.storyActiveStoryBoards(
                userId: userId,
                storyId: 0,
                offset: currentOffset + pageSize,
                pageSize: pageSize,
                filter: ""
            )
            print("loadMoreData: \(String(describing: boards))")
            if let error = error {
                hasError = true
                errorMessage = error.localizedDescription
                return
            }
            
            if let boards = boards {
                storyBoardActives.append(contentsOf: boards)
                currentOffset = offset ?? currentOffset
                hasMoreData = boards.count >= pageSize
            }
        } catch {
            hasError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}


