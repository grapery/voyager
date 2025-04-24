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
    @Published var isRefreshing = false
    
    private var currentPage: Int64 = 0
    private let defaultPageSize: Int64 = 10
    public  var hasMoreData = true
    private let storyService = APIClient.shared
   
    // 添加分支故事板相关的状态
    @Published var currentForkPage: Int64 = 0
    @Published var hasMoreForkStoryboards = true
    private let forkPageSize: Int64 = 10
   
    // 使用字典存储每个故事板的分支列表
    @Published private var forkListsMap: [Int64: [StoryBoardActive]] = [:]
    @Published private var forkListsLoadingMap: [Int64: Bool] = [:]
    @Published private var forkListsHasMoreMap: [Int64: Bool] = [:]
    @Published private var forkListsPageMap: [Int64: Int64] = [:]
    
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
        isRefreshing = true
        hasError = false
        resetPagination()
        
        do {
            switch type {
            case .Story:
                let (boards, offset, _, error) = await storyService.storyActiveStoryBoards(
                    userId: userId,
                    storyId: 0,
                    offset: currentPage * defaultPageSize,
                    pageSize: defaultPageSize,
                    filter: ""
                )
                if let error = error {
                    handleError(error)
                    return
                }
                updateStoryBoards(boards, offset)
            case .StoryRole:
                let (boards, offset, _, error) = await storyService.userWatchRoleActiveStoryBoards(
                    userId: userId,
                    roleId: 0,
                    offset: currentPage * defaultPageSize,
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
        isRefreshing = false
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

    // 获取特定故事板的分支列表
    func getForkList(for boardId: Int64) -> [StoryBoardActive] {
        return forkListsMap[boardId] ?? []
    }
    
    // 获取特定故事板的加载状态
    func isLoadingForkList(for boardId: Int64) -> Bool {
        return forkListsLoadingMap[boardId] ?? false
    }
    
    // 获取特定故事板是否有更多数据
    func hasMoreForkList(for boardId: Int64) -> Bool {
        return forkListsHasMoreMap[boardId] ?? true
    }
    
    // 清理特定故事板的分支列表
    func clearForkList(for boardId: Int64) {
        forkListsMap.removeValue(forKey: boardId)
        forkListsLoadingMap.removeValue(forKey: boardId)
        forkListsHasMoreMap.removeValue(forKey: boardId)
        forkListsPageMap.removeValue(forKey: boardId)
    }
    
    @MainActor
    func fetchStoryboardForkList(userId: Int64, storyId: Int64, boardId: Int64, forceRefresh: Bool = false) async {
        guard !forkListsLoadingMap[boardId, default: false] else { return }
        
        // 如果强制刷新，重置状态
        if forceRefresh {
            forkListsPageMap[boardId] = 0
            forkListsMap[boardId] = []
            forkListsHasMoreMap[boardId] = true
        }
        
        // 如果没有更多数据，直接返回
        if !forkListsHasMoreMap[boardId, default: true] && !forceRefresh {
            return
        }
        
        forkListsLoadingMap[boardId] = true
        hasError = false
        
        do {
            let offset = forkListsPageMap[boardId, default: 0]
            let (fetchedBoards, pageNum, pageSize, error) = await APIClient.shared.getNextStoryboard(
                userId: userId,
                storyId: storyId,
                boardId: boardId,
                offset: offset,
                pageSize: forkPageSize,
                filter: .likes
            )
            
            if let error = error {
                hasError = true
                errorMessage = error.localizedDescription
                forkListsLoadingMap[boardId] = false
                return
            }
            
            if let boards = fetchedBoards {
                // 更新分页状态
                forkListsHasMoreMap[boardId] = boards.count >= forkPageSize
                forkListsPageMap[boardId, default: 0] += 1
                
                // 将 Common_StoryBoardActive 转换为 StoryBoardActive
                let convertedBoards = boards.map { commonBoard -> StoryBoardActive in
                    return StoryBoardActive(id: commonBoard.storyboard.storyBoardID, boardActive: commonBoard)
                }
                
                // 更新数据
                if forceRefresh {
                    forkListsMap[boardId] = convertedBoards
                } else {
                    forkListsMap[boardId, default: []].append(contentsOf: convertedBoards)
                }
            }
            
            forkListsLoadingMap[boardId] = false
        } catch {
            hasError = true
            errorMessage = error.localizedDescription
            forkListsLoadingMap[boardId] = false
        }
    }
    
    // 加载更多分支故事板
    @MainActor
    func loadMoreForkStoryboards(userId: Int64, storyId: Int64, boardId: Int64) async {
        guard !forkListsLoadingMap[boardId, default: false] && forkListsHasMoreMap[boardId, default: true] else { return }
        await fetchStoryboardForkList(userId: userId, storyId: storyId, boardId: boardId)
    }
    
    // 刷新分支故事板列表
    @MainActor
    func refreshForkStoryboards(userId: Int64, storyId: Int64, boardId: Int64) async {
        await fetchStoryboardForkList(userId: userId, storyId: storyId, boardId: boardId, forceRefresh: true)
    }
    
    func TrendingStoris(userId: Int64,starttime: Int64,endTime: Int64,pageNum: Int64,pageSize: Int64) async -> ([Story]?,Error?){
        let (stories,_,_,err) = await APIClient.shared.getTrendingStoris(userId: userId, starttime: starttime, endtime: endTime, pageNum: pageNum, pageSize: pageSize)
        
        if err != nil { 
            return (nil,err)
        }   
        return (stories,nil)
    }
    
    func TrendingStoryRole(userId: Int64,starttime: Int64,endTime: Int64,pageNum: Int64,pageSize: Int64) async -> ([StoryRole]?,Error?){
        let (roles,_,_,err) = await APIClient.shared.getTrendingStoryRole(userId: userId, starttime: starttime, endtime: endTime, pageNum: pageNum, pageSize: pageSize)
        if err != nil { 
            return (nil,err)
        }   
        return (roles,nil)
    }
    
}

