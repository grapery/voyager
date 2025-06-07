import Foundation

class UnpublishedStoryViewModel: ObservableObject {
    @Published var unpublishedStoryboards: [StoryBoardActive] = []
    @Published var isLoading = false
    @Published var hasError = false
    @Published var errorMessage = ""
    @Published var currentPage = 1
    @Published var hasMorePages = true
    
    public let pageSize = 10
    public var userId: Int64
    
    init(userId: Int64) {
        self.userId = userId
    }
    
    func getStoryboardDetails(storyboardId: Int64) async -> (StoryBoardActive?,Error?) {
        var (board,err) = await APIClient.shared.GetStoryboardActive(boardId: storyboardId)
        if let error = err {
            return (nil, error)
        }
        return (board, nil)
    }
    
    func fetchUnpublishedStoryboards(isRefreshing: Bool = false) async {
        await MainActor.run {
            if isRefreshing {
                currentPage = 1
                hasMorePages = true
            }
            guard hasMorePages, !isLoading else { return }
            isLoading = true
        }
        
        do {
            let result = await APIClient.shared.UnPublishStoryboard(
                userId: self.userId,
                offset: Int64(self.currentPage),
                pageSize: Int64(self.pageSize)
            )
            
            await MainActor.run {
                if let commonBoards = result.0 {
                    let boards = commonBoards.map { commonBoard in
                        StoryBoardActive(id: commonBoard.storyboard.storyBoardID, boardActive: commonBoard)
                    }
                    if isRefreshing {
                        self.unpublishedStoryboards = boards
                    } else {
                        let newBoards = boards.filter { newBoard in
                            !self.unpublishedStoryboards.contains(where: { $0.id == newBoard.id })
                        }
                        self.unpublishedStoryboards.append(contentsOf: newBoards)
                    }
                    self.hasMorePages = boards.count == self.pageSize
                    if self.hasMorePages {
                        self.currentPage += 1
                    }
                } else {
                    self.hasMorePages = false
                }
                if let error = result.3 {
                    self.hasError = true
                    self.errorMessage = error.localizedDescription
                }
                self.isLoading = false
            }
        }
    }
}
