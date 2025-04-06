//
//  FeedViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation

class FeedViewModel: ObservableObject {
    @Published var timeline: Int64
    @Published var storys: [Story]
    @Published var userId: Int64
    @Published var user: User
    @Published var roles: [StoryRole]
    @Published var boards: [StoryBoardActive]
    @Published var filters = [String]()

    
    @Published var timeStamp: Int64
    
    @Published var tags: [String]
    @Published @MainActor var searchText: String = ""
    @Published @MainActor var activeFlowType: Common_ActiveFlowType = Common_ActiveFlowType(rawValue: 3)!
    
    @Published var comments: [Comment]
    
    @Published var storyBoardActives: [Common_StoryBoardActive] = []
    @Published var isLoading = false
    @Published var hasError = false
    @Published var errorMessage = ""
    
    private var currentOffset: Int64 = 0
    private let pageSize: Int64 = 10
    private var hasMoreData = true
    private let storyService = APIClient.shared
   
    @MainActor
    func performSearch() async {
       // Implement search logic here based on the selected tab and searchText
    }
    
    init(user: User) {
        self.timeline = 0
        self.storys = [Story]()
        self.filters = [String]()
        self.timeStamp = 0
        self.userId = user.userID
        self.tags = [String]()
        self.roles = [StoryRole]()
        self.boards = [StoryBoardActive]()
        
        self.currentOffset = 0
        self.user = user
        
        self.comments = [Comment]()
    }
    
    
    @MainActor
    func fetchStorys() async -> Void{
        let result = await APIClient.shared.fetchUserTakepartinStorys(userId: self.userId, offset: self.currentOffset, size: self.pageSize, filter: self.filters)
        if result.3 != nil {
            print("fetchStorys failed: ",result.3!)
            return
        }
        self.storys = result.0
        self.currentOffset = result.1
        return
    }
    
    @MainActor
    func fetchStoryRoles() async -> Void{
        let result = await APIClient.shared.fetchStoryRoles(userId: self.userId, offset: self.currentOffset, size: self.pageSize, filter: self.filters)
        if result.3 != nil {
            print("fetchStoryRoles failed: ",result.3!)
            return
        }
        self.roles = result.0
        self.currentOffset = result.1
        return
    }

    @MainActor
    func fetchUserCreatedStoryBoards() async -> Void{
        let result = await APIClient.shared.fetchUserCreatedStoryBoards(userId: self.userId, page: self.currentOffset, size: self.pageSize, storyId:0)
        if result.3 != nil {
            print("fetchUserCreatedStoryBoards failed: ",result.3!)
            return
        }
        self.boards = result.0!
        self.currentOffset = result.1
        return
    }
    
    // 重置分页参数
    func resetPagination() {
        self.currentOffset = 0
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
    
    @MainActor
    func refreshData(type: FeedType) async {
        guard !isLoading else { return }
        
        isLoading = true
        hasError = false
        currentOffset = 0
        
        do {
            switch type{
            case .Story:
                // 获取用户关注的故事动态
                let (boards, offset, size, error) = await storyService.storyActiveStoryBoards(
                    userId: userId,
                    storyId: 0,
                    offset: 0,
                    pageSize: pageSize,
                    filter: ""
                )
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
            case .StoryRole:
                // 获取用户关注的角色参与的故事板信息
                let (boards, offset, size, error) = await storyService.userWatchRoleActiveStoryBoards(
                    userId: userId,
                    roleId: 0,
                    offset: 0,
                    pageSize: pageSize,
                    filter: ""
                )
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
            case .Groups:
                print("not support")
            }
            
        } catch {
            hasError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func loadMoreData(type: FeedType) async {
        guard !isLoading && hasMoreData else { return }
        
        isLoading = true
        hasError = false
        
        do {
            switch type{
            case .Story:
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
            case .StoryRole:
                let (boards, offset, size, error) = await storyService.userWatchRoleActiveStoryBoards(
                    userId: userId,
                    roleId:  0,
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
            case .Groups:
                print("not support")
            }
            
        } catch {
            hasError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }

    func likeStoryBoard(storyId: Int64, boardId: Int64, userId: Int64) async -> Error? {
        let result = await APIClient.shared.LikeStoryboard(boardId: boardId, storyId: storyId, userId: userId)
        
        if let error = result {
            // 如果API返回错误，返回该错误
            return error
        }
        return nil
    }
    
    func unlikeStoryBoard(storyId: Int64, boardId: Int64, userId: Int64) async -> Error? {
        let result = await APIClient.shared.UnLikeStoryboard(boardId: boardId, storyId: storyId, userId: userId)
        if let error = result {
            // 如果API返回错误，返回该错误
            return error
        }
        return nil
    }
    
    func fetchStoryboardDetail(storyboardId: Int64) async -> (StoryBoardActive?,Error?) {
        let (storyboard, err) = await APIClient.shared.GetStoryboardActive(boardId: storyboardId)
        if err != nil {
            return (nil,err)
        }
        return (storyboard,nil)
    }
}

