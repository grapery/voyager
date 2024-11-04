//
//  StoryViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/9/24.
//

import SwiftUI
import Combine


class StoryViewModel: ObservableObject {
    @Published var story: Story?
    @Published var isLoading: Bool = false
    @Published var storyId: Int64
    @Published var storyboards:[StoryBoard]?
    var isUpdateOk: Bool = false
    var isCreateOk: Bool = false
    var isForkOk: Bool = false
    var isGenerate: Bool = false
    var err: Error? = nil
    var page: Int64 = 0
    var pageSize: Int64 = 10
    var branchId: Int64 = 0
    var userId: Int64
    
    init(story: Story,userId: Int64) {
        self.story = story
        self.storyId = story.storyInfo.id
        self.userId = userId
        self.branchId = storyId
        self.err = nil
    }
    
    private let apiClient = APIClient.shared
    
    func fetchStory(withBoards:Bool) async {
        let currentStoryId: Int64 = getCurrentStoryId()
        self.err = nil
        do {
            let fetchedStory = await apiClient.GetStory(storyId: currentStoryId)
            if fetchedStory.self.1 == nil {
                self.story = fetchedStory.self.0
                self.isLoading = false
                self.err = nil
            }
        } catch {
            self.err = ("Error fetching story: \(error.localizedDescription)" as! any Error)
            self.isLoading = false
        }
        
        if withBoards {
            await self.fetchStoryBoards()
        }
    }
    
    // 添加一个方法来获取当前的 storyId
    private func getCurrentStoryId() -> Int64 {
        // 这里应该实现获取当前 storyId 的逻辑
        // 可能从用户选择、路由参数或其他来源获取
        // 暂时返回一个默认值或占位符
        return self.storyId
    }
    
    func updateStory() async  {
        guard let story = story else { return }
        isLoading = true
        self.err = nil
        do {
            let updatedStory =  await apiClient.UpdateStory(storyId: self.storyId, short_desc: story.storyInfo.desc, status: Int64(story.storyInfo.status), isAiGen: story.storyInfo.isAiGen, origin: story.storyInfo.origin, params: story.storyInfo.params)
            if updatedStory.self.1 != nil {
                self.isUpdateOk = false
            }else {
                self.isUpdateOk = true
                self.storyId = updatedStory.self.0
            }
        } catch {
            self.err = error
            self.isLoading = false
            
        }
    }
    
    func publishStoryboard(storyId: Int64, boardId: Int64,userId: Int64,status:Int64) async  {
        guard story != nil else { return }
        self.err = nil
        do {
            let updateResult =  await apiClient.UpdateStoryBoard(storyId: storyId, boardId: boardId,userId: userId,status:status)
            if updateResult != nil {
                throw NSError()
            }
        } catch {
            self.err = error
            self.isLoading = false
        }
    }
    
    func fetchStoryBoards() async{
        let currentStoryId: Int64 = getCurrentStoryId()
        self.err = nil
        do {
            let result = await apiClient.GetStoryboards(storyId: currentStoryId, branchId: self.branchId, startTime: 0, endTime: 0, offset: self.page, size: self.pageSize)
            if result.self.3 == nil {
                self.storyboards = result.self.0
                self.isLoading = false
                self.err = nil
            }
        } catch {
            self.err = ("Error fetching storyboards: \(error.localizedDescription)" as! any Error)
            self.isLoading = false
        }
    }
    
    func createStoryBoard(prevBoardId: Int64, nextBoardId: Int64, title: String, content: String, isAiGen: Bool, backgroud: String, params: Common_StoryBoardParams) async -> (StoryBoard?,Error?){
        var newStoryboard: StoryBoard?
        var err: Error?
        self.err = nil
        (newStoryboard,err) = await apiClient.CreateStoryboard(storyId: self.storyId, prevBoardId: prevBoardId, nextBoardId: nextBoardId, creator: self.userId, title: title, content: content, isAiGen: isAiGen, background: backgroud, params: params)
        if err != nil {
            self.isCreateOk = false
            print("CreateStoryBoard failed",err!)
            return (newStoryboard,nil)
        }
        if newStoryboard?.id == 0 {
            self.isCreateOk = false
            print("CreateStoryBoard failed")
            return (newStoryboard,nil)
        }
        self.isCreateOk = true
        print("CreateStoryBoard ok")
        return (newStoryboard,nil)
    }
    
    func createStoryRole() async{
        
    }
    
    func deleteStoryBoard(storyId: Int64, boardId: Int64, userId: Int64) async -> Error? {
        self.err = nil
        do {
            let result = await apiClient.DelStoryboard(boardId: boardId, storyId: storyId, userId: userId)
            
            if let error = result {
                // 如果API返回错误，返回该错误
                return error
            }
            
            // 删除成功，更新本地数据
            if let index = self.storyboards?.firstIndex(where: { $0.id == boardId }) {
                self.storyboards?.remove(at: index)
            }
            // 可能需要重新获取故事板列表
            await self.fetchStoryBoards()
            return nil
        } catch {
            // 捕获并返回任何其他错误
            self.err = error
            return error
        }
    }
    
    func forkStory(preStoryBoardId: Int64, storyId: Int64, userId: Int64) async ->(Int64,Error?){
        var newStoryboardId: Int64
        var err: Error?
        self.err = nil
        var paramsStoryboard: Common_StoryBoard?
        (newStoryboardId,err) = await apiClient.ForkStoryboard(prevboardId: preStoryBoardId, storyId: self.storyId, userId: self.userId, storyParam: paramsStoryboard!)
        if err != nil {
            self.isForkOk = false
            print("ForkStoryBoard failed",err!)
            return (newStoryboardId,nil)
        }
        if newStoryboardId == 0 {
            self.isForkOk = false
            print("ForkStoryBoard failed",err!)
            return (newStoryboardId,nil)
        }
        self.isForkOk = true
        print("ForkStoryBoard ok",err!)
        return (newStoryboardId,nil)
    }
    
    func genStory(storyId:Int64,userId:Int64) async -> (Common_RenderStoryDetail,Error?) {
        var resp: Common_RenderStoryDetail
        var err: Error?
        self.isGenerate = true
        self.err = nil
        do {
            (resp,err) = await apiClient.RenderStory(
                boardId: 0,
                storyId: storyId,
                userId: userId,
                is_regenerate: false,
                render_type: Common_RenderType(rawValue: 0)!)
            if err != nil {
                print("genStory failed",err!)
                return (Common_RenderStoryDetail(),err)
            }
        } catch {
            self.isGenerate = false
        }
        self.isGenerate = false
        return (resp,nil as Error?)
    }
    
    func CreateStory(groupId:Int64) async{
        var newStory: Story?
        var storyId: Int64
        var err: Error?
        self.err = nil
        do {
            (newStory,storyId,_,err) = await apiClient.CreateStory(
                name: (self.story?.storyInfo.name)!,
                title: (self.story?.storyInfo.title)!,
                short_desc: (self.story?.storyInfo.desc)!,
                creator: (self.userId),
                groupId: groupId,
                isAiGen: (self.story?.storyInfo.isAiGen)!,
                origin: (self.story?.storyInfo.origin)!,
                params: (self.story?.storyInfo.params)!)
            if err != nil {
                self.isCreateOk = false
                self.err = err
                print("CreateStory failed",err!)
                return
            }
            if storyId == 0 {
                self.isCreateOk = false
            }else {
                self.isCreateOk = true
                //self.storyId = storyId
                self.story?.Id = newStory!.Id
                self.story?.storyInfo.creatorID = self.userId
                self.story?.storyInfo.ownerID = self.userId
            }
        } catch {
            self.isCreateOk = false
        }
    }
    
    func getGenStory(storyId:Int64,userId:Int64) async -> (Common_RenderStoryDetail?,Error?) {
        var resp: Common_RenderStoryDetail?
        var err: Error?
        self.err = nil
        do {
            (resp,err) = await apiClient.GetRenderStory(storyId: storyId, userId: userId, is_regenerate: false, render_type: Common_RenderType(rawValue: 0)!)
            if err != nil {
                print("get genStory failed",err!)
                return (Common_RenderStoryDetail(),err)
            }
        }
        return (resp,nil as Error?)
    }
    
    func getGenStoryBoard(storyId:Int64,userId:Int64,boardId:Int64) async -> (Common_RenderStoryboardDetail?,Error?) {
        var resp: Common_RenderStoryboardDetail?
        var err: Error?
        self.err = nil
        do {
            (resp,err) = await apiClient.GetRenderStoryboard(boardId: boardId, storyId: storyId, userId: userId, is_regenerate: false, render_type: Common_RenderType(rawValue: 0)!)
            if err != nil {
                print("get genStoryboard failed",err!)
                return (Common_RenderStoryboardDetail(),err)
            }
        }
        return (resp,nil as Error?)
    }
    
    func conintueGenStory(storyId:Int64,userId:Int64,prevBoardId: Int64,prompt: String, title: String, desc: String, backgroud: String) async -> (Common_RenderStoryDetail,Error?) {
        var resp: Common_RenderStoryDetail
        var err: Error?
        self.err = nil
        self.isGenerate = true
        do {
            (resp,err) = await apiClient.ContinueRenderStory(prevBoardId: prevBoardId, storyId: storyId, userId: userId, is_regenerate: true, prompt: prompt, title: title, desc: desc, backgroud: backgroud)
            if err != nil {
                return (Common_RenderStoryDetail(),err)
            }
        }
        self.isGenerate = false
        return (resp,nil as Error?)
    }
    
    func applyStorySummry(storyId:Int64,theme: String, summry: String,userId:Int64) async -> Error?{
        do {
            let (resp,err) = await apiClient.UpdateStory(storyId: storyId, short_desc: theme, status: 1, isAiGen: true, origin: (self.story?.storyInfo.origin)!, params: (self.story?.storyInfo.params)!)
            if err != nil {
                self.isGenerate = false
                self.err = err
            }
            print("applyStorySummry resp :",resp)
        }
        self.isGenerate = false
        return nil
    }
    
    func applyStoryBoard(storyId: Int64,title: String, content: String,userId:Int64) async -> Error?{
        do {
            self.isGenerate = true
            let (resp,err) = await apiClient.CreateStoryboard(storyId: storyId, prevBoardId: 0, nextBoardId: -1, creator: userId, title: title, content: content, isAiGen: true, background: (self.story?.storyInfo.origin)!, params: Common_StoryBoardParams())
            if err != nil {
                self.isGenerate = false
                self.err = err
            }
            print("applyStoryBoard resp :",resp)
        }
        self.isGenerate = false
        return nil
    }
    
    func genStoryBoardPrompt(storyId:Int64,boardId:Int64,userId:Int64,renderType: Common_RenderType) async -> Error?{
        do {
            self.isGenerate = true
            let (resp,err) = await apiClient.RenderStoryboard(boardId: boardId, storyId: storyId, userId: userId, is_regenerate: true, render_type: renderType)
            if err != nil {
                self.isGenerate = false
                self.err = err
            }
            print("genStoryBoardPrompt resp: ",resp)
        }
        self.isGenerate = false
        return nil
    }
    
    func genStoryBoardImages(storyId:Int64,boardId:Int64,userId:Int64,renderType: Common_RenderType) async -> Error?{
        do {
            self.isGenerate = true
//            let (resp,err) = await apiClient.GenStoryboardImages(boardId: boardId, storyId: storyId, userId: userId, is_regenerate: true, render_type: Common_RenderType(rawValue: 1)!, title: <#T##String#>, prompt: <#T##String#>, image_url: <#T##String#>, description: <#T##String#>, refImage: <#T##String#>)
//            if err != nil {
//                self.isGenerate = false
//                self.err = err
//            }
//            print("genStoryBoardPrompt resp: ",resp)
        }
        self.isGenerate = false
        return nil
    }
    
    func genStoryBoardVideo(storyId:Int64,boardId:Int64,userId:Int64,renderType: Common_RenderType) async -> Error?{
        do {
            self.isGenerate = true
            
            print("genStoryBoardVideo resp not impl")
        }
        self.isGenerate = false
        return nil
    }
}



