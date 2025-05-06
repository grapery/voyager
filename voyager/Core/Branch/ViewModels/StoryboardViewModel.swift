//
//  StoryboardViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/10/5.
//

import SwiftUI
import Combine

class StoryBoardSence{
    var senceIndex: Int
    var content: String
    var characters: [Common_Character]
    var imagePrompt: String
    var senceId: Int64
    var imageUrl: String
    var referencaImage = UIImage()
    
    init(index: Int, content: String, characters: [Common_Character], imagePrompt: String) {
        self.senceIndex = index
        self.content = content
        self.characters = characters
        self.imagePrompt = imagePrompt
        self.senceId = 0
        self.imageUrl = ""
    }
    
    // 从API响应数据创建场景
    static func fromResponse(_ data: Common_DetailScene, index: Int) -> StoryBoardSence? {
        let content = data.content
        let characters = data.characters
        let imagePrompt = data.imagePrompt
        
        return StoryBoardSence(
            index: index,
            content: content,
            characters: characters,
            imagePrompt: imagePrompt
        )
    }
}

class StoryboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var storyboard: StoryBoardActive?
    @Published var story: Story?
    @Published var creator: User?
    @Published var isLoading: Bool = false
    @Published var hasError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isLiked: Bool = false
    @Published var likeCount: Int = 0
    @Published var commentCount: Int = 0
    @Published var forkCount: Int = 0
    @Published var roles: [StoryRole] = []
    
    // MARK: - Private Properties
    private let apiClient = APIClient.shared
    private let userId: Int64
    private let storyboardId: Int64
    private let storyId: Int64
    
    // MARK: - Initialization
    init(storyboardId: Int64, storyId: Int64, userId: Int64) {
        self.storyboardId = storyboardId
        self.storyId = storyId
        self.userId = userId
    }
    
    // MARK: - Public Methods
    
    /// 获取故事板详细信息
    func fetchStoryboardDetails() async {
        await setLoading(true)
        do {
            // 获取故事板信息
            let (storyboard, error) = await apiClient.GetStoryboardActive(boardId: storyboardId)
            if let error = error {
                await handleError(error)
                return
            }
            
            // 获取关联的故事信息
            let (story, storyError) = await apiClient.GetStory(storyId: storyId)
            if let storyError = storyError {
                await handleError(storyError)
                return
            }
            
            // 获取创建者信息
            let (creator) = try! await apiClient.GetUserInfo(userId: userId)
            
            await MainActor.run {
                self.storyboard = storyboard
                self.story = story
                self.creator = creator
                self.isLiked = ((storyboard?.boardActive.isliked) != nil)
                self.likeCount = Int(storyboard!.boardActive.totalLikeCount)
                self.commentCount = Int(storyboard!.boardActive.totalCommentCount)
                self.forkCount = Int(storyboard!.boardActive.totalForkCount)
                self.hasError = false
                self.errorMessage = ""
            }
        } catch {
            await handleError(error)
        }
        await setLoading(false)
    }
    
    /// 获取故事板角色信息
    func fetchStoryboardRoles() async {
        await setLoading(true)
        do {
            let (roles, error) = await apiClient.getStoryRoles(userId: userId, storyId: storyId)
            if let error = error {
                await handleError(error)
                return
            }
            
            await MainActor.run {
                self.roles = roles ?? []
                self.hasError = false
                self.errorMessage = ""
            }
        } catch {
            await handleError(error)
        }
        await setLoading(false)
    }
    
    /// 点赞故事板
    func likeStoryboard() async {
        guard !isLoading else { return }
        await setLoading(true)
        
        do {
            let error = await apiClient.LikeStoryboard(boardId: storyboardId, storyId: storyId, userId: userId)
            if let error = error {
                await handleError(error)
                return
            }
            
            await MainActor.run {
                self.isLiked = true
                self.likeCount += 1
                self.hasError = false
                self.errorMessage = ""
            }
        } catch {
            await handleError(error)
        }
        await setLoading(false)
    }
    
    /// 取消点赞故事板
    func unlikeStoryboard() async {
        guard !isLoading else { return }
        await setLoading(true)
        
        do {
            let error = await apiClient.UnLikeStoryboard(boardId: storyboardId, storyId: storyId, userId: userId)
            if let error = error {
                await handleError(error)
                return
            }
            
            await MainActor.run {
                self.isLiked = false
                self.likeCount -= 1
                self.hasError = false
                self.errorMessage = ""
            }
        } catch {
            await handleError(error)
        }
        await setLoading(false)
    }
   
    
    // MARK: - Private Methods
    
    private func setLoading(_ loading: Bool) async {
        await MainActor.run {
            self.isLoading = loading
        }
    }
    
    private func handleError(_ error: Error) async {
        await MainActor.run {
            self.hasError = true
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}


