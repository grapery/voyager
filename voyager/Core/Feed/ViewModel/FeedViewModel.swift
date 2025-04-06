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
    
    private var currentPage: Int64 = 0
    private let defaultPageSize: Int64 = 10
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
        
        self.currentPage = 0
        self.user = user
        
        self.comments = [Comment]()
    }
    
    
    @MainActor
    func fetchStorys() async -> Void{
        let result = await APIClient.shared.fetchUserTakepartinStorys(userId: self.userId, offset: self.currentPage * self.defaultPageSize, size: self.defaultPageSize, filter: self.filters)
        if result.3 != nil {
            print("fetchStorys failed: ",result.3!)
            return
        }
        self.storys = result.0
        self.currentPage = result.1
        return
    }
    
    @MainActor
    func fetchStoryRoles() async -> Void{
        let result = await APIClient.shared.fetchStoryRoles(userId: self.userId, offset: self.currentPage * self.defaultPageSize, size: self.defaultPageSize, filter: self.filters)
        if result.3 != nil {
            print("fetchStoryRoles failed: ",result.3!)
            return
        }
        self.roles = result.0
        self.currentPage = result.1
        return
    }

    @MainActor
    func fetchUserCreatedStoryBoards() async -> Void{
        let result = await APIClient.shared.fetchUserCreatedStoryBoards(userId: self.userId, page: self.currentPage, size: self.defaultPageSize, storyId:0)
        if result.3 != nil {
            print("fetchUserCreatedStoryBoards failed: ",result.3!)
            return
        }
        self.boards = result.0!
        self.currentPage = result.1
        return
    }
    
    // 统一错误处理
    private func handleError(_ error: Error) {
        hasError = true
        errorMessage = error.localizedDescription
    }
    
    // 统一更新故事板数据
    private func updateStoryBoards(_ boards: [Common_StoryBoardActive]?, _ offset: Int64?) {
        if let boards = boards {
            storyBoardActives = boards
            currentPage = offset ?? 0
            hasMoreData = boards.count >= defaultPageSize
        }
    }
    
    // 统一追加故事板数据
    private func appendStoryBoards(_ boards: [Common_StoryBoardActive]?, _ offset: Int64?) {
        if let boards = boards {
            // 防止重复数据
            let newBoards = boards.filter { newBoard in
                !storyBoardActives.contains { $0.storyboard.storyBoardID == newBoard.storyboard.storyBoardID }
            }
            storyBoardActives.append(contentsOf: newBoards)
            currentPage = offset ?? currentPage
            hasMoreData = boards.count >= defaultPageSize
        }
    }
    
    // 重置分页参数
    private func resetPagination() {
        currentPage = 0
        timeStamp = 0
        hasMoreData = true
        storyBoardActives.removeAll()
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
        resetPagination()
        
        do {
            switch type {
            case .Story:
                print("storyActiveStoryBoards :",currentPage ,defaultPageSize)
                let (boards, offset, _, error) = await storyService.storyActiveStoryBoards(
                    userId: userId,
                    storyId: 0,
                    offset: currentPage ,
                    pageSize: defaultPageSize,
                    filter: ""
                )
                if let error = error {
                    handleError(error)
                    return
                }
                updateStoryBoards(boards, offset)
            case .StoryRole:
                print("userWatchRoleActiveStoryBoards :",currentPage ,defaultPageSize)
                let (boards, offset, _, error) = await storyService.userWatchRoleActiveStoryBoards(
                    userId: userId,
                    roleId: 0,
                    offset: currentPage ,
                    pageSize: defaultPageSize,
                    filter: ""
                )
                if let error = error {
                    handleError(error)
                    return
                }
                updateStoryBoards(boards, offset)
            case .Groups:
                print("not support")
            }
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    @MainActor
    func loadMoreData(type: FeedType) async {
        guard !isLoading && hasMoreData else { return }
        
        isLoading = true
        hasError = false
        
        do {
            switch type {
            case .Story:
                let (boards, offset, _, error) = await storyService.storyActiveStoryBoards(
                    userId: userId,
                    storyId: 0,
                    offset: (currentPage + 1) ,
                    pageSize: defaultPageSize,
                    filter: ""
                )
                if let error = error {
                    handleError(error)
                    return
                }
                appendStoryBoards(boards, offset)
            case .StoryRole:
                let (boards, offset, _, error) = await storyService.userWatchRoleActiveStoryBoards(
                    userId: userId,
                    roleId: 0,
                    offset: (currentPage + 1) ,
                    pageSize: defaultPageSize,
                    filter: ""
                )
                if let error = error {
                    handleError(error)
                    return
                }
                appendStoryBoards(boards, offset)
            case .Groups:
                print("not support")
            }
        } catch {
            handleError(error)
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

