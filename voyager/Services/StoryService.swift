//
//  StoryService.swift
//  voyager
//
//  Created by grapestree on 2024/9/3.
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import Connect
import SwiftUI



extension APIClient {
    
    func CreateStory(name: String,title: String,short_desc: String,creator: Int64,groupId: Int64,isAiGen: Bool,origin: String,params: Common_StoryParams) async -> (Story?,Int64,Int64,Error?) {
        let result = Story()
        var resp :ResponseMessage<Common_CreateStoryResponse>
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            // Performed within an async context.
            let request = Common_CreateStoryRequest.with {
                $0.creatorID = creator
                $0.groupID = groupId
                $0.isAiGen = isAiGen
                $0.name = name
                $0.ownerID = creator
                $0.origin = origin
                $0.shortDesc = short_desc
                $0.title = title
                $0.params = params
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            resp = await authClient.createStory(request: request, headers:header)
            if resp.code.rawValue != 0 {
                return (nil,-1,-1,NSError(domain: "CreateStory", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"]))
            }
            result.Id = Int64(resp.message!.data.storyID)
            result.storyInfo.id = Int64(resp.message!.data.storyID)
            result.storyInfo.rootBoardID = Int64(resp.message!.data.boardID)
        }
        
        return (result,result.storyInfo.id,result.storyInfo.rootBoardID,nil)
    }
    
    func GetStory(storyId: Int64) async -> (Story, Error?) {
        let result = Story()
        var err : Error? = nil
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_GetStoryInfoRequest.with {
                $0.storyID = storyId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            let resp = await authClient.getStoryInfo(request: request, headers: header)
            if resp.message?.code != 0 {
                err = nil
            }else if let storyData = resp.message?.data {
                result.Id = Int64(storyData.info.id)
                result.storyInfo.id = Int64(storyData.info.id)
                result.storyInfo.rootBoardID = Int64(storyData.info.rootBoardID)
                result.storyInfo.name = storyData.info.name
                result.storyInfo.desc = storyData.info.desc
                result.storyInfo.params = storyData.info.params
                result.storyInfo.origin = storyData.info.origin
                result.storyInfo.isAiGen = storyData.info.isAiGen
                result.storyInfo.creatorID = storyData.info.creatorID
                result.storyInfo.ownerID = storyData.info.ownerID
                result.storyInfo.groupID = storyData.info.groupID
                result.storyInfo.avatar = storyData.info.avatar
                return (result, nil)
            }
            
        }
        return (result, err)
    }
    
    func UpdateStory(storyId: Int64, short_desc: String, status: Int64, isAiGen: Bool, origin: String, params: Common_StoryParams) async -> (Int64, Error?) {
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_UpdateStoryRequest.with {
                $0.storyID = storyId
                $0.shortDesc = short_desc
                $0.status = Int32(status)
                $0.isAiGen = isAiGen
                $0.origin = origin
                $0.params = params
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.updateStory(request: request, headers: header)
            
            if resp.message?.code != 0 {
                // If the response code is not 1, it indicates an error
                return (0, NSError(domain: "UpdateStoryError", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"]))
            }
            
            // If successful, return the updated story ID
            return (Int64(resp.message?.data.storyID ?? 0), nil)
        } catch {
            // If an exception occurs during the API call, return it as the error
            return (0, error)
        }
    }
    
    func WatchStory(storyId: Int64, userId: Int64) async -> (Int64, Error?) {
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_WatchStoryRequest.with {
                $0.storyID = storyId
                $0.userID = userId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.watchStory(request: request, headers: header)
            
            if resp.message?.code != 0 {
                // If the response code is not 1, it indicates an error
                return (0, NSError(domain: "WatchStoryError", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"]))
            }
            
            // If successful, return the watched story ID
            return (storyId, nil)
        } catch {
            // If an exception occurs during the API call, return it as the error
            return (0, error)
        }
    }
    
    func CreateStoryboard(storyId: Int64, prevBoardId: Int64, nextBoardId: Int64, creator: Int64, title: String, content: String, isAiGen: Bool, background: String, params: Common_StoryBoardParams) async -> (StoryBoard, Error?) {
        print("CreateStoryboard request parameters:")
        print("storyId: \(storyId), prevBoardId: \(prevBoardId), nextBoardId: \(nextBoardId), creator: \(creator)")
        print("title: \(title), content: \(content), isAiGen: \(isAiGen), background: \(background)")
        print("params: \(params)")

        let result = StoryBoard(id: -1, boardInfo: Common_StoryBoard())
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_CreateStoryboardRequest.with {
                $0.board = Common_StoryBoard.with {
                    $0.storyID = storyId
                    $0.prevBoardID = prevBoardId
                    $0.nextBoardID = [Int64]()
                    $0.creator = creator
                    $0.title = title
                    $0.content = content
                    $0.isAiGen = isAiGen
                    $0.backgroud = background
                    $0.params = params
                }
            }
            
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.createStoryboard(request: request, headers: header)
            
            if resp.message?.code != 0 {
                let error = NSError(domain: "CreateStoryboardError", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
                print("CreateStoryboard error: \(error)")
                return (result, error)
            }
            
            if let boardData = resp.message?.data {
                result.id = Int64(boardData.boardID)
            }
            
            print("CreateStoryboard response:")
            print(result)
            
            return (result, nil)
        } catch {
            print("CreateStoryboard unexpected error: \(error)")
            return (result, error)
        }
    }
    
    func GetStoryboardActive(boardId: Int64) async -> (StoryBoardActive?, Error?) {
        let result = StoryBoardActive(id: -1, boardActive: Common_StoryBoardActive())
        do {
            let apiClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_GetStoryboardRequest.with {
                $0.boardID = boardId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await apiClient.getStoryboard(request: request, headers: header)
            
            if resp.message?.code != 0 {
                // If the response code is not 1, it indicates an error
                return (nil, NSError(domain: "GetStoryboardError", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"]))
            }
            
            if let boardData = resp.message?.data {
                result.id = Int64(boardData.boardInfo.storyboard.storyBoardID)
                result.boardActive = boardData.boardInfo
            }
            
            return (result, nil)
        } catch {
            // If an exception occurs during the API call, return it as the error
            return (nil, error)
        }
    }
    
    func UpdateStoryboard(storyId: Int64, boardId: Int64, userId: Int64, params: Common_StoryBoardParams) async -> (Int64, Int64, Error?) {
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_UpdateStoryboardRequest.with {
                $0.storyID = storyId
                $0.boardID = boardId
                $0.userID = userId
                $0.params = params
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.updateStoryboard(request: request, headers: header)
            
            if resp.message?.code != 1 {
                let error = NSError(domain: "UpdateStoryboardError", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
                return (0, 0, error)
            }
            
            if let boardData = resp.message?.data {
                // 假设 boardData 包含更新后的 boardID 和某个相关的计数
                // 如果实际返回的数据结构不同，请相应调整这里的代码
                return (Int64(boardData.storyID), Int64(boardData.boardID), nil)
            } else {
                return (0, 0, NSError(domain: "UpdateStoryboardError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
            }
        } catch {
            return (0, 0, error)
        }
    }
    
    func GetStoryboards(storyId: Int64, branchId: Int64, startTime: Int64, endTime: Int64, offset: Int64, size: Int64) async -> (([StoryBoardActive], Int64, Int64, Error?)) {
        var storyboards: [StoryBoardActive] = []
        var totalCount: Int64 = 0
        var nextOffset: Int64 = 0
        
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_GetStoryboardsRequest.with {
                $0.storyID = storyId
                //$0.branchID = branchId
                $0.startTime = startTime
                $0.endTime = endTime
                $0.page = Int32(offset)
                $0.pageSize = Int32(size)
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.getStoryboards(request: request, headers: header)
            
            if resp.message?.code != 0 {
                let error = NSError(domain: "GetStoryboardsError", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
                return ([], 0, 0, error)
            }
            if let boardsData = resp.message?.data {
                storyboards = boardsData.list.map { boardInfo in
                    StoryBoardActive(id: Int64(boardInfo.storyboard.storyBoardID), boardActive: boardInfo)
                }
                totalCount = Int64(boardsData.total)
                nextOffset = offset + Int64(storyboards.count)
            }
            
            return (storyboards, totalCount, nextOffset, nil)
        } catch {
            return ([], 0, 0, error)
        }
    }

    func DelStoryboard(boardId: Int64, storyId: Int64, userId: Int64) async -> Error? {
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_DelStoryboardRequest.with {
                $0.boardID = boardId
                $0.storyID = storyId
                $0.userID = userId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.delStoryboard(request: request, headers: header)
            
            if resp.message?.code != 0 {
                // If the response code is not 1, it indicates an error
                return NSError(domain: "DelStoryboardError", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
            }
            
            // If successful, return nil (no error)
            return nil
        } catch {
            // If an exception occurs during the API call, return it as the error
            return error
        }
    }
    
    func ForkStoryboard(prevboardId: Int64, storyId: Int64, userId: Int64, storyParam: Common_StoryBoard) async -> (Int64,  Error?) {
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_ForkStoryboardRequest.with {
                $0.prevBoardID = prevboardId
                $0.storyID = storyId
                $0.userID = userId
                $0.board = storyParam
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.forkStoryboard(request: request, headers: header)
            
            if resp.message?.code != 0 {
                let error = NSError(domain: "ForkStoryboardError", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
                return (0,  error)
            }
            
            if let forkData = resp.message?.data {
                return (Int64(forkData.storyID), nil)
            } else {
                return (0,  NSError(domain: "ForkStoryboardError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
            }
        } catch {
            return (0, error)
        }
    }
    
    
    
    func ShareStoryboard(boardId: Int64, storyId: Int64, userId: Int64) async -> (Error?) {
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_ShareStoryboardRequest.with {
                $0.boardID = boardId
                $0.storyID = storyId
                $0.userID = userId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.shareStoryboard(request: request, headers: header)
            
            if resp.message?.code != 0 {
                // If the response code is not 1, it indicates an error
                return NSError(domain: "ShareStoryboardError", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
            }
            
            // If successful, return nil (no error)
            return nil
        } catch {
            // If an exception occurs during the API call, return it as the error
            return error
        }
    }
    func RenderStory(boardId: Int64, storyId: Int64, userId: Int64, is_regenerate: Bool, render_type: Common_RenderType) async -> (Common_RenderStoryDetail, Error?) {
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_RenderStoryRequest.with {
                $0.boardID = boardId
                $0.storyID = storyId
                $0.userID = userId
                $0.isRegenerate = is_regenerate
                $0.renderType = render_type
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.renderStory(request: request, headers: header)
            
            if resp.message?.code != 0 {
                let error = NSError(domain: "RenderStoryError", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
                return (Common_RenderStoryDetail(), error)
            }
            
            if let renderData = resp.message?.data {
                return (renderData, nil)
            } else {
                return (Common_RenderStoryDetail(), NSError(domain: "RenderStoryError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
            }
        } catch {
            return (Common_RenderStoryDetail(), error)
        }
    }
    
    func RenderStoryboard(boardId: Int64, storyId: Int64, userId: Int64, is_regenerate: Bool, render_type: Common_RenderType) async -> (Common_RenderStoryboardDetail,Error?){
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_RenderStoryboardRequest.with {
                $0.boardID = boardId
                $0.storyID = storyId
                $0.userID = userId
                $0.isRegenerate = is_regenerate
                $0.renderType = render_type
            }
            print("RenderStoryboard request: ",request)
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.renderStoryboard(request: request, headers: header)
            
            if resp.message?.code != 0 {
                let error = NSError(domain: "RenderStoryboardError", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
                return (Common_RenderStoryboardDetail(), error)
            }
            
            if let renderData = resp.message?.data {
                return (renderData, nil)
            } else {
                return (Common_RenderStoryboardDetail(), NSError(domain: "RenderStoryboardError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
            }
        } catch {
            return (Common_RenderStoryboardDetail(), error)
        }
    }
    
    func GenStoryboardImages(boardId: Int64, storyId: Int64, userId: Int64, is_regenerate: Bool, 
    render_type: Common_RenderType,title: String,prompt: String,image_url: String,description: String,refImage: String) async -> (Common_RenderStoryboardDetail,Error?) {
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_GenStoryboardImagesRequest.with {
                $0.boardID = boardId
                $0.storyID = storyId
                $0.userID = userId
                $0.isRegenerate = is_regenerate
                $0.renderType = render_type
                $0.prompt = prompt
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.genStoryboardImages(request: request, headers: header)
            
            if resp.message?.code != 0 {
                let error = NSError(domain: "GenStoryboardImagesError", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
                return (Common_RenderStoryboardDetail(), error)
            }
            
            if let renderData = resp.message?.data {
                return (renderData, nil)
            } else {
                return (Common_RenderStoryboardDetail(), NSError(domain: "GenStoryboardImagesError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
            }
        } catch {
            return (Common_RenderStoryboardDetail(), error)
        }
    }
    
    func GenStoryboardText(boardId: Int64, storyId: Int64, userId: Int64, is_regenerate: Bool, 
    render_type: Common_RenderType, title: String, prompt: String, image_url: String, description: String) async -> (Common_RenderStoryboardDetail, Error?) {
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_GenStoryboardTextRequest.with {
                $0.boardID = boardId
                $0.storyID = storyId
                $0.userID = userId
                $0.renderType = render_type
                $0.title = title
                $0.prompt = prompt
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.genStoryboardText(request: request, headers: header)
            
            if resp.message?.code != 0 {
                let error = NSError(domain: "GenStoryboardTextError", 
                                    code: Int(resp.message?.code ?? 0), 
                                    userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
                return (Common_RenderStoryboardDetail(), error)
            }
            
            if let renderData = resp.message?.data {
                return (renderData, nil)
            } else {
                return (Common_RenderStoryboardDetail(), 
                        NSError(domain: "GenStoryboardTextError", 
                                code: 0, 
                                userInfo: [NSLocalizedDescriptionKey: "No data received"]))
            }
        } catch {
            return (Common_RenderStoryboardDetail(), error)
        }
    }
    
    func GetRenderStory(storyId: Int64, userId: Int64, is_regenerate: Bool, render_type: Common_RenderType) async -> (Common_RenderStoryDetail?, Error?) {
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_GetStoryRenderRequest.with {
                $0.storyID = storyId
                $0.renderStatus = 1
                $0.renderType = 0
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.getStoryRender(request: request, headers: header)
            
            if resp.message?.code != 0 {
                let error = NSError(domain: "GetRenderStoryError", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
                return (Common_RenderStoryDetail(), error)
            }
            
            if let renderDatas = resp.message?.data {
                if renderDatas.list.count <= 0 {
                    return (Common_RenderStoryDetail(), NSError(domain: "GetRenderStoryError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                }
                return (renderDatas.list.first, nil)
            } else {
                return (Common_RenderStoryDetail(), NSError(domain: "RenderStoryError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
            }
        } catch {
            return (Common_RenderStoryDetail(), error)
        }
    }
    
    func GetRenderStoryboard(boardId: Int64, storyId: Int64, userId: Int64, is_regenerate: Bool, render_type: Common_RenderType) async -> (Common_RenderStoryboardDetail,Error?){
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_GetStoryBoardRenderRequest.with {
                $0.boardID = boardId
                $0.renderStatus = 1
                $0.renderType = 0
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.getStoryBoardRender(request: request, headers: header)
            
            if resp.message?.code != 0 {
                let error = NSError(domain: "GetRenderStoryboardError", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
                return (Common_RenderStoryboardDetail(), error)
            }
            
            if let renderDatas = resp.message?.data.list {
                if renderDatas.count <= 0 {
                    return (Common_RenderStoryboardDetail(), NSError(domain: "GetRenderStoryboardError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                }
                return (renderDatas[0], nil)
            } else {
                return (Common_RenderStoryboardDetail(), NSError(domain: "GetRenderStoryboardError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
            }
        } catch {
            return (Common_RenderStoryboardDetail(), error)
        }
    }
    
    func ContinueRenderStory(prevBoardId: Int64, storyId: Int64, userId: Int64, is_regenerate: Bool,prompt:String,title: String,desc:String,backgroud: String) async -> (Common_RenderStoryboardDetail?, Error?) {
        let authClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_ContinueRenderStoryRequest.with {
            $0.prevBoardID = prevBoardId
            $0.storyID = storyId
            $0.userID = userId
            $0.prompt = prompt
            $0.title = title
            $0.description_p = desc
            $0.background = backgroud
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        
        let resp = await authClient.continueRenderStory(request: request, headers: header)
        
        if resp.message?.code != 0 {
            let error = NSError(domain: "ConintueRenderStoryError", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
            return (Common_RenderStoryboardDetail(), error)
        }
        
        if let renderData = resp.message?.data {
            return (renderData, nil)
        } else {
            return (nil, NSError(domain: "ConintueRenderStoryError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
        }
    }
    
    func UpdateStoryBoard(storyId: Int64,boardId: Int64,userId: Int64,status: Int64) async -> Error?{
        return nil
    }
    
    
    func GetStoryBoardSences(boardId: Int64,userId: Int64) async ->([Common_StoryBoardSence],Error?){
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_GetStoryBoardSencesRequest.with {
                $0.userID = userId
                $0.boardID = boardId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.getStoryBoardSences(request: request, headers: header)
            
            if resp.message?.code != 0 {
                let error = NSError(domain: "GetStoryBoardSences", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
                return ([Common_StoryBoardSence](), error)
            }
            
            let retCode = resp.message?.code
            if retCode! < 0 || retCode! > 1 {
                return ([Common_StoryBoardSence](), NSError(domain: "GetStoryBoardSences", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
            }
            if let renderData = resp.message?.data.list {
                return (renderData, nil)
            }
        } catch {
            return ([Common_StoryBoardSence](), error)
        }
        return ([Common_StoryBoardSence](),nil)
    }
    
    func CreateStoryBoardSence(storyId:Int64,boardId: Int64,userId:Int64,originContent: String,characterIds:[String],imagePrompts: String,videoPrompts:String) async -> (Int64,Error?){
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            var newSenceItem = Common_StoryBoardSence()
            newSenceItem.senceID=0
            newSenceItem.storyID = storyId
            newSenceItem.boardID=boardId
            newSenceItem.characterIds=characterIds
            newSenceItem.content=originContent
            newSenceItem.characterIds=characterIds
            newSenceItem.imagePrompts=imagePrompts
            newSenceItem.videoPrompts=videoPrompts
            newSenceItem.status=1
            let request = Common_CreateStoryBoardSenceRequest.with{
                $0.userID = userId
                $0.sence = newSenceItem
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.createStoryBoardSence(request: request, headers: header)
            
            if resp.message?.code != 0 {
                let error = NSError(domain: "CreateStoryBoardSence", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
                return (-1, error)
            }
            print("CreateStoryBoardSence resp: ", resp)
            if let renderData = resp.message?.data {
                return (renderData.senceID, nil)
            } else {
                return (-1, NSError(domain: "CreateStoryBoardSence", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
            }
        } catch {
            return (-1, error)
        }
    }
    
    func UpdateStoryBoardSence(storyId:Int64,boardId: Int64,userId:Int64,originContent: String,characterIds:[String],imagePrompts: String,videoPrompts:String,status:Int64) async -> Error? {
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            var newSenceItem = Common_StoryBoardSence()
            newSenceItem.senceID=0
            newSenceItem.characterIds=characterIds
            newSenceItem.content=originContent
            newSenceItem.characterIds=characterIds
            newSenceItem.imagePrompts=imagePrompts
            newSenceItem.videoPrompts=videoPrompts
            newSenceItem.status=Int32(status)
            let request = Common_UpdateStoryBoardSenceRequest.with {
                $0.userID = userId
                $0.sence = newSenceItem
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.updateStoryBoardSence(request: request, headers: header)
            
            if resp.message?.code != 0 || resp.message?.code != 1{
                let error = NSError(domain: "UpdateStoryBoardSence", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
                return error
            }
            return nil
        }
    }
    
    func DeleteStoryBoardSence(storyId:Int64,boardId: Int64,userId:Int64,senceId:Int64) async -> Error?{
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_DeleteStoryBoardSenceRequest.with {
                $0.userID = userId
                $0.senceID = senceId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.deleteStoryBoardSence(request: request, headers: header)
            
            if resp.message?.code != 0 || resp.message?.code != 1{
                let error = NSError(domain: "DeleteStoryBoardSenceError", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
                return error
            }
            return nil
        }
    }
    
    func GenStoryBoardSences(storyId: Int64,boardId: Int64,userId: Int64,render_type: Common_RenderType) async -> Error?{
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_RenderStoryBoardSencesRequest.with {
                $0.boardID = Int32(boardId)
                $0.userID = userId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.renderStoryBoardSences(request: request, headers: header)
            
            if resp.message?.code != 0 {
                let error = NSError(domain: "GenStoryBoardSences", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
                return error
            }
            let renderCode = resp.message?.code
            if renderCode==0 || renderCode==1{
                return nil
            } else {
                return NSError(domain: "GenStoryBoardSences", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
            }
        }
    }
    
    func GenStoryBoardSpecSence(storyId: Int64,boardId: Int64,userId: Int64,senceId:Int64,render_type: Common_RenderType) async -> (Common_StoryBoardSence?,Error?){
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_RenderStoryBoardSenceRequest.with {
                $0.boardID = Int32(boardId)
                $0.userID = userId
                $0.senceID = senceId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.renderStoryBoardSence(request: request, headers: header)
            
            if resp.message?.code != 0 {
                let error = NSError(domain: "GenStoryBoardSpecSence", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
                return (nil,error)
            }
            let renderCode = resp.message?.code
            if renderCode==0 || renderCode==1{
                return (resp.message?.data ,nil)
            } else {
                let error = NSError(domain: "GenStoryBoardSpecSence", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                return (nil,error)
            }
        }
    }
    
    func GetStoryBoardSpecSence(storyId: Int64,boardId: Int64,userId: Int64,sceneId: Int64,render_type: Common_RenderType) async -> (Common_StoryBoardSence,Error?){
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_GetStoryBoardSenceGenerateRequest.with {
                $0.userID = userId
                $0.senceID = sceneId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.getStoryBoardSenceGenerate(request: request, headers: header)
            
            if resp.message?.code != 0 {
                let error = NSError(domain: "GetStoryBoardSpecSence", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
                return (Common_StoryBoardSence(), error)
            }
            
            if let renderData = resp.message?.data {
                return (renderData, nil)
            } else {
                return (Common_StoryBoardSence(), NSError(domain: "GetStoryBoardSpecSence", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
            }
        } catch {
            return (Common_StoryBoardSence(), error)
        }
    }
    
    func GetStoryBoardSenceRenderStatus(storyId: Int64,boardId: Int64,userId: Int64,sceneId: Int64,render_type: Common_RenderType) async -> ([Common_StoryBoardSence],Error?){
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_GetStoryBoardGenerateRequest.with {
                $0.boardID = boardId
                $0.userID = userId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.getStoryBoardGenerate(request: request, headers: header)
            
            if resp.message?.code != 0 {
                let error = NSError(domain: "GetStoryBoardSenceRenderStatus", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
                return ([Common_StoryBoardSence](), error)
            }
            
            if let renderData = resp.message?.list {
                return (renderData, nil)
            } else {
                return ([Common_StoryBoardSence](), NSError(domain: "GetStoryBoardSenceRenderStatus", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
            }
        } catch {
            return ([Common_StoryBoardSence](), error)
        }
    }
    
    func GetStoryBoardSencesRenderStatus(storyId: Int64,boardId: Int64,userId: Int64,sceneId: Int64) async -> (Common_StoryBoardSence,Error?){
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_GetStoryBoardSenceGenerateRequest.with {
                $0.userID = userId
                $0.senceID = sceneId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.getStoryBoardSenceGenerate(request: request, headers: header)
            
            if resp.message?.code != 0 {
                let error = NSError(domain: "GetStoryBoardSencesRenderStatus", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
                return (Common_StoryBoardSence(), error)
            }
            
            if let renderData = resp.message?.data {
                return (renderData, nil)
            } else {
                return (Common_StoryBoardSence(), NSError(domain: "GetStoryBoardSencesRenderStatus", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
            }
        } catch {
            return (Common_StoryBoardSence(), error)
        }
    }
    
    func LikeStoryRole(roleId: Int64, storyId: Int64, userId: Int64) async -> (Error?) {
        do {
           let request = Common_LikeStoryRoleRequest.with {
                $0.roleID = roleId
                $0.storyID = storyId
                $0.userID = userId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            let apiClient = Common_TeamsApiClient(client: self.client!)
            let response = await apiClient.likeStoryRole(request: request, headers: header)
            if response.message?.code != Common_ResponseCode.ok{
                return NSError(domain: "StoryService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Like story role failed"])
            }
            // If successful, return nil (no error)
            return nil
        } catch {
            // If an exception occurs during the API call, return it as the error
            return error
        }
    }
    
    func UnLikeStoryRole(roleId: Int64, storyId: Int64, userId: Int64) async -> (Error?) {
        do {
            let request = Common_UnLikeStoryRoleRequest.with {
                $0.roleID = roleId
                $0.storyID = storyId
                $0.userID = userId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            let apiClient = Common_TeamsApiClient(client: self.client!)
            let response = await apiClient.unLikeStoryRole(request: request, headers: header)
            if response.message?.code != Common_ResponseCode.ok{
                return NSError(domain: "StoryService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unlike story role failed"])
            }
            // If successful, return nil (no error)
            return nil
        } catch {
            // If an exception occurs during the API call, return it as the error
            return error
        }
    }
    
    func LikeStoryboard(boardId: Int64, storyId: Int64, userId: Int64) async -> (Error?) {
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_LikeStoryboardRequest.with {
                $0.boardID = boardId
                $0.storyID = storyId
                $0.userID = userId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.likeStoryboard(request: request, headers: header)
            
            if resp.message?.code != 0 {
                // If the response code is not 1, it indicates an error
                return NSError(domain: "LikeStoryboard", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
            }
            
            // If successful, return nil (no error)
            return nil
        } catch {
            // If an exception occurs during the API call, return it as the error
            return error
        }
    }
    
    func UnLikeStoryboard(boardId: Int64, storyId: Int64, userId: Int64) async -> (Error?) {
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_UnLikeStoryboardRequest.with {
                $0.boardID = boardId
                $0.storyID = storyId
                $0.userID = userId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.unLikeStoryboard(request: request, headers: header)
            
            if resp.message?.code != 0 {
                // If the response code is not 1, it indicates an error
                return NSError(domain: "UnLikeStoryBoard", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
            }
            
            // If successful, return nil (no error)
            return nil
        } catch {
            // If an exception occurs during the API call, return it as the error
            return error
        }
    }
    
    func LikeStory(storyId: Int64, userId: Int64) async -> (Error?) {
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_LikeStoryRequest.with {
                $0.storyID = storyId
                $0.userID = userId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.likeStory(request: request, headers: header)
            
            if resp.message?.code != Common_ResponseCode.ok {
                // If the response code is not 1, it indicates an error
                return NSError(domain: "LikeStory", code: -1, userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
            }
            
            // If successful, return nil (no error)
            return nil
        } catch {
            // If an exception occurs during the API call, return it as the error
            return error
        }
    }
    
    func UnLikeStory(storyId: Int64, userId: Int64) async -> (Error?) {
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_UnLikeStoryRequest.with {
                $0.storyID = storyId
                $0.userID = userId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.unLikeStory(request: request, headers: header)
            
            if resp.message?.code != Common_ResponseCode.ok {
                // If the response code is not 1, it indicates an error
                return NSError(domain: "UnLikeStory", code: -1, userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
            }
            
            // If successful, return nil (no error)
            return nil
        } catch {
            // If an exception occurs during the API call, return it as the error
            return error
        }
    }

    func SearchStoryRoles(keyword: String,userId: Int64,page: Int64,size: Int64) async -> ([StoryRole]?,Int64,Int64,Error?){
        do {
            let request = Common_SearchRolesRequest.with {
                $0.keyword = keyword
                $0.userID = userId
                $0.offset = page
                $0.pageSize = size
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            let apiClient = Common_TeamsApiClient(client: self.client!)
            let response = await apiClient.searchRoles(request: request, headers: header)
            if response.message?.code != Common_ResponseCode.ok{
                let roles = response.message?.roles.map { StoryRole(Id:$0.roleID,role: $0) }
                return (roles, page, size,nil)
            } else {
                return ([], 0,  0,NSError(domain: "GroupService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Search story roles failed"]))
            }
        } catch {
            print("Error searching story roles: \(error.localizedDescription)")
            return ([], 0,  0,NSError(domain: "GroupService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Search story roles failed"]))
        }
    }

    func FollowStoryRole(userId: Int64,roleId: Int64,storyId: Int64) async -> (Bool,Error?){
        do {
            let request = Common_FollowStoryRoleRequest.with {
                $0.userID = userId
                $0.roleID = roleId
                $0.storyID = storyId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            let apiClient = Common_TeamsApiClient(client: self.client!)
            let response = await apiClient.followStoryRole(request: request, headers: header)
            if response.message?.code != Common_ResponseCode.ok{
                return (true,nil)
            } else {
                return (false,NSError(domain: "GroupService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Follow story role failed"]))
            }
        } catch {
            return (false,error)
        }
    }

    func LikeStoryRole(userId: Int64,roleId: Int64,storyId: Int64) async -> (Bool,Error?){
        do {
            let request = Common_LikeStoryRoleRequest.with {
                $0.userID = userId
                $0.roleID = roleId
                $0.storyID = storyId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            let apiClient = Common_TeamsApiClient(client: self.client!)
            let response = await apiClient.likeStoryRole(request: request, headers: header)
            if response.message?.code != Common_ResponseCode.ok{
                return (true,nil)
            } else {
                return (false,NSError(domain: "GroupService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Like story role failed"]))
            }
        } catch {
            return (false,error)
        }
    }
    func UnLikeStoryRole(userId: Int64,roleId: Int64,storyId: Int64) async -> (Bool,Error?){
        do {
            let request = Common_UnLikeStoryRoleRequest.with {
                $0.userID = userId
                $0.roleID = roleId
                $0.storyID = storyId
            }   
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            let apiClient = Common_TeamsApiClient(client: self.client!)
            let response = await apiClient.unLikeStoryRole(request: request, headers: header)
            if response.message?.code != Common_ResponseCode.ok{
                return (true,nil)
            } else {
                return (false,NSError(domain: "GroupService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unlike story role failed"]))
            }
        } catch {
            return (false,error)
        }
    }

    func UnFollowStoryRole(userId: Int64,roleId: Int64,storyId: Int64) async -> (Bool,Error?){
        do {
            let request = Common_UnFollowStoryRoleRequest.with {
                $0.userID = userId
                $0.roleID = roleId
                $0.storyID = storyId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            let apiClient = Common_TeamsApiClient(client: self.client!)
            let response = await apiClient.unFollowStoryRole(request: request, headers: header)
            if response.message?.code != Common_ResponseCode.ok{
                return (true,nil)
            } else {
                return (false,NSError(domain: "GroupService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unfollow story role failed"]))
            }
        } catch {
            return (false,error)
        }
    }
    func SearchStories(keyword: String,userId: Int64,page: Int64,size: Int64) async -> ([Story]?,Int64,Int64,Error?){
        do {
            let request = Common_SearchStoriesRequest.with {
                $0.keyword = keyword
                $0.userID = userId
                $0.offset = page
                $0.pageSize = size
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            let apiClient = Common_TeamsApiClient(client: self.client!)
            let response = await apiClient.searchStories(request: request, headers: header)
            if response.message?.code != Common_ResponseCode.ok{
                let stories = response.message?.stories.map { Story(Id: $0.id, storyInfo: $0) }
                return (stories, page, size,nil)
            } else {
                return ([], 0,  0,NSError(domain: "GroupService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Search stories failed"]))
            }
        } catch {
            print("Error searching stories: \(error.localizedDescription)")
            return ([], 0,  0,NSError(domain: "GroupService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Search stories failed"]))
        }
    }
    
    func fetchUserCreatedStoryBoards(userId:Int64,page: Int64,size: Int64,storyId:Int64) async -> ([StoryBoardActive]?,Int64,Int64,Error?){
        do {
            print("fetchUserCreatedStoryBoards " ,userId)
            let apiClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_GetUserCreatedStoryboardsRequest.with {
                $0.userID = userId
                $0.offset = page
                $0.pageSize = size
                $0.storyID = Int32(storyId)
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            let response = await apiClient.getUserCreatedStoryboards(request: request, headers: header)
            if response.message?.code != Common_ResponseCode.ok{
                print("fetchUserCreatedStoryBoards response: ",response.message as Any)
                return ([StoryBoardActive](),0,0,nil)
            }
            let boards = response.message?.storyboards.map { StoryBoardActive(id: $0.storyboard.storyBoardID, boardActive: $0) }
            print("boards?.count : ",boards?.count as Any)
            return (boards,response.message!.offset,response.message!.pageSize,nil)
        } catch {
            return (nil,0,0,error)
        }
    }
    
    func fetchUserCreatedStoryRoles(userId:Int64,page: Int64,size: Int64,storyid:Int64) async -> ([StoryRole]?,Int64,Int64,Error?){
        do {
            print("fetchUserCreatedStoryRoles " ,userId)
            let apiClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_GetUserCreatedRolesRequest.with {
                $0.userID = userId
                $0.offset = page
                $0.pageSize = size
                $0.storyID = Int32(storyid)
            }
            print("req : ",request)
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            let response = await apiClient.getUserCreatedRoles(request: request, headers: header)
            if response.message?.code != Common_ResponseCode.ok {
                print("fetchUserCreatedStoryRoles response: ",response.message as Any)
                return ([StoryRole](),0,0,nil)
            }
            print("rpc resp: ",response.message?.roles as Any)
            let roles = response.message?.roles.map { StoryRole(Id: $0.roleID, role: $0) }
            return (roles,response.message!.offset,response.message!.pageSize,nil)
        } catch {
            return (nil,0,0,error)
        }
    }
    
    func fetchUserWatchedGroup(userId: Int64,offset: Int64,size: Int64,filter: [String]) async  -> ( [BranchGroup],Int64,Int64,Error?) {
        let groups: [BranchGroup] = []
        // 用户创建的,用户关注的,用户参与的
        return (groups,0,0,nil)
    }
    
    func fetchUserTakepartinStorys(userId: Int64,offset: Int64,size: Int64,filter: [String]) async  -> ([Story],Int64,Int64,Error?){
        // 用户创建的,用户参与的
        let storys: [Story] = []
        return (storys,0,0,nil)
    }
    
    func fetchStoryRoles(userId: Int64,offset: Int64,size: Int64,filter: [String]) async -> ([StoryRole],Int64,Int64,Error?){
        // 用户创建的,用户关注的,用户参与的
        let roles: [StoryRole] = []
        return (roles,0,0,nil)
    }
    
    func fetchTrendingGroup(userId: Int64,offset: Int64,size: Int64,filter: [String]) async  -> ( [BranchGroup],Int64,Int64,Error?) {
        let groups: [BranchGroup] = []
        return (groups,0,0,nil)
    }
    
    func fetchTrendingStorys(userId: Int64,offset: Int64,size: Int64,filter: [String]) async  -> ([Story],Int64,Int64,Error?){
        let storys: [Story] = []
        return (storys,0,0,nil)
    }
    
    func fetchTrendingStoryRoles(userId: Int64,offset: Int64,size: Int64,filter: [String]) async -> ([StoryRole],Int64,Int64,Error?){
        let roles: [StoryRole] = []
        return (roles,0,0,nil)
    }
    
    
    func createStoryRole(userId: Int64,role:Common_StoryRole) async -> Error?{
        do {
            print("createStoryRole " ,userId)
            let apiClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_CreateStoryRoleRequest.with {
                $0.userID = userId
                $0.role = role
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            let response = await apiClient.createStoryRole(request: request, headers: header)
            if response.message?.code != Common_ResponseCode.ok{
                print("createStoryRole response: ",response.message as Any)
                return (nil)
            }
            return (nil)
        } catch {
            return NSError(domain: "createStoryRole", code: 0, userInfo: [NSLocalizedDescriptionKey: "create story role failed"])
        }
    }
    
    func getStoryRoles(userId:Int64,storyId:Int64)async -> ([StoryRole]?,Error?){
        do{
            let apiClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_GetStoryRolesRequest.with {
                $0.userID = userId
                $0.storyID = storyId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            let response = await apiClient.getStoryRoles(request: request, headers: header)
            if response.message?.code != 0{
                print("getStoryRoles response: ",response.message as Any)
                return ([],nil)
            }
            let roles = response.message?.data.list.map { StoryRole(Id: $0.roleID, role: $0) }
            return (roles,nil)
        } catch {
            return ([],NSError(domain: "getStoryRoles", code: 0, userInfo: [NSLocalizedDescriptionKey: "get story roles failed"]))
        }
    }

    func getStoryBoardRoles(userId:Int64,boardId:Int64)async -> ([StoryRole]?,Error?){
        let roles: [StoryRole] = []
        do {
            let apiClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_GetStoryBoardRolesRequest.with {
                $0.userID = userId
                $0.boardID = boardId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            let response = await apiClient.getStoryBoardRoles(request: request, headers: header)
            if response.message?.code != 0{
                print("getStoryBoardRoles response: ",response.message as Any)
                return ([],nil)
            }
            let roles = response.message?.data.list.map { StoryRole(Id: $0.roleID, role: $0) }
            return (roles,nil)
        }
        return (roles,nil)
    }

    func getStoryContributors(userId:Int64,storyId:Int64)async -> ([User]?,Error?){
        let users: [User]? = []
        do {
            let apiClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_GetStoryContributorsRequest.with {
                $0.storyID = storyId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            let response = await apiClient.getStoryContributors(request: request, headers: header)
            if response.message?.code != Common_ResponseCode.ok{
                return ([],nil)
            }
            let users = response.message?.data.list.map { User(userID: $0.userID, name: $0.username,avatar : $0.avatar) }
            return (users,nil)
        } catch {
            return ([],NSError(domain: "getStoryContributors", code: 0, userInfo: [NSLocalizedDescriptionKey: "get story contributors failed"]))
        }
    }

    func getStoryRoleDetail(userId:Int64,roleId:Int64)async -> (StoryRole?,Error?){
        let apiClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_GetStoryRoleDetailRequest.with {
            $0.roleID = roleId
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let response = await apiClient.getStoryRoleDetail(request: request, headers: header)
        if response.message?.code != Common_ResponseCode.ok{
            print("getStoryRoleDetail response: ",response.message as Any)
            return (nil,nil)
        }
        let role = StoryRole(Id: response.message!.info.roleID, role: response.message!.info)
        return (role,nil)
    }

    func RenderStoryRole(userId:Int64,roleId:Int64,refImage:[String],prompt:String)async -> Error?{
        let apiClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_RenderStoryRoleRequest.with {
            $0.userID = userId
            $0.roleID = roleId
            $0.refImages = refImage
            $0.prompt = prompt
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let response = await apiClient.renderStoryRole(request: request, headers: header)
        if response.message?.code != Common_ResponseCode.ok{
            print("RenderStoryRole response: ",response.message as Any)
            return NSError(domain: "RenderStoryRole", code: 0, userInfo: [NSLocalizedDescriptionKey: "render story role failed"])
        }
        return nil
    }
    
    func getUserChatWithRole(userId: Int64,roleId: Int64) async -> (Common_ChatContext?,Error?){
        let apiClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_GetUserChatWithRoleRequest.with {
            $0.userID = userId
            $0.roleID = roleId
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let response = await apiClient.getUserChatWithRole(request: request, headers: header)
        if response.message?.code != Common_ResponseCode.ok{
            return (nil,NSError(domain: "getUserChatWithRole", code: 0, userInfo: [NSLocalizedDescriptionKey: "get user chat with role failed"]))
        }
        return (response.message?.chatContext,nil)
    }
    
    
    func createChatWithRoleContext(userId: Int64,roleId: Int64) async -> (Common_ChatContext?,Error?){
        let apiClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_CreateStoryRoleChatRequest.with {
            $0.userID = userId
            $0.roleID = roleId
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let response = await apiClient.createStoryRoleChat(request: request, headers: header)
        if response.message?.code != Common_ResponseCode.ok{
            return (nil,NSError(domain: "createChatWithRoleContext", code: 0, userInfo: [NSLocalizedDescriptionKey: "create chat with role context failed"]))
        }
        return (response.message?.chatContext,nil)
    }
    
    
    func getUserWithRoleChatList(userId: Int64) async -> ([Common_ChatContext]?,Error?){
        if globalUserToken == "" {
            return (nil,nil)
        }
        let apiClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_GetUserWithRoleChatListRequest.with {
            $0.userID = userId
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let response = await apiClient.getUserWithRoleChatList(request: request, headers: header)
        if response.message?.code != Common_ResponseCode.ok {
            return (nil,NSError(domain: "getUserWithRoleChatList", code: 0, userInfo: [NSLocalizedDescriptionKey: "get user chat list failed"]))
        }
        return (response.message?.chats,nil)
    }
    
    func chatWithStoryRole(userId:Int64,roleId: Int64,msgs: [Common_ChatMessage]?) async -> ([Common_ChatMessage]?,Error?) {
        let apiClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_ChatWithStoryRoleRequest.with {
            $0.messages = msgs!
            $0.userID = userId
            $0.roleID = roleId
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let response = await apiClient.chatWithStoryRole(request: request, headers: header)
        if response.message?.code != Common_ResponseCode.ok {
            return (nil,NSError(domain: "chatWithStoryRole", code: 0, userInfo: [NSLocalizedDescriptionKey: "chat with story role failed"]))
        }
        return (response.message?.replyMessages,nil)
    }
    
    func getUserChatMessages(userId: Int64,roleId: Int64,chatCtxId: Int64,timestamp: Int64) async -> ([Common_ChatMessage]?,Int64,Error?){
        let apiClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_GetUserChatMessagesRequest.with {
            $0.userID = userId
            $0.roleID = roleId
            $0.chatID = chatCtxId
            $0.timestamp = timestamp
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let response = await apiClient.getUserChatMessages(request: request, headers: header)
        if response.message?.code != Common_ResponseCode.ok{
            return (nil,0,NSError(domain: "getUserChatMessages", code: 0, userInfo: [NSLocalizedDescriptionKey: "get user chat messages failed"]))
        }
        return (response.message?.messages,response.message!.timestamp,nil)
    }

    func fetchActives(userId:Int64,offset: Int64,size: Int64,timestamp: Int64,activeType: Common_ActiveFlowType,filter: [String]) async -> ([Common_ActiveInfo]?,Int64,Int64,Error?){
        var actives: [Common_ActiveInfo] = []
        var size = size
        var offset = offset
        do {
             let apiClient = Common_TeamsApiClient(client: self.client!)
             let request = Common_FetchActivesRequest.with {
                 $0.userID = userId
                 $0.timestamp = timestamp
                 $0.atype = activeType
                 $0.offset = 0
                 $0.pageSize = 10
             }
             print("fetchActives request: ",request)
             var header = Connect.Headers()
             header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
             let response = await apiClient.fetchActives(request: request, headers: header)
            print("fetchActives response: ",response as Any )
            if response.message?.code != Common_ResponseCode.ok{
                 return (nil,0,0,NSError(domain: "fetchActives", code: 0, userInfo: [NSLocalizedDescriptionKey: "fetchActives failed"]))
             }
            actives = (response.message?.data.list)!
            size = (response.message?.data.pageSize)!
            offset = (response.message?.data.offset)!
         }
        print("actives: ",actives)
         return (actives,offset,size,nil)
    }

    func publishStoryBoard(userId: Int64,storyBoardId: Int64) async -> Error? {
        let apiClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_PublishStoryboardRequest.with {
            $0.userID = userId
            $0.storyboardID = storyBoardId
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let response = await apiClient.publishStoryboard(request: request, headers: header)
        if response.message?.code != Common_ResponseCode.ok{
            return NSError(domain: "publishStoryBoard", code: 0, userInfo: [NSLocalizedDescriptionKey: "publish story board failed"])
        }
        return nil
    }

    func cancelStoryBoard(userId: Int64,storyBoardId: Int64) async -> Error? {
        let apiClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_CancelStoryboardRequest.with {
            $0.userID = userId
            $0.storyboardID = storyBoardId
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let response = await apiClient.cancelStoryboard(request: request, headers: header)
        if response.message?.code != Common_ResponseCode.ok{
            return NSError(domain: "cancelStoryBoard", code: 0, userInfo: [NSLocalizedDescriptionKey: "cancel story board failed"])
        }
        return nil
    }
    
    func restoreStoryboard(storyId: Int64,userId: Int64,boardId: Int64) async -> (Common_StoryboardStageStore?,Error?){
        let apiClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_RestoreStoryboardRequest.with {
            $0.userID = userId
            $0.storyboardID = boardId
            $0.storyID = storyId
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let response = await apiClient.restoreStoryboard(request: request, headers: header)
        if response.message?.code != Common_ResponseCode.ok{
            return (nil,NSError(domain: "restoreStoryboard", code: 0, userInfo: [NSLocalizedDescriptionKey: "restore story board failed"]))
        }
        let boardInfo = response.message?.store
        print("storyboard statu: ",boardInfo?.stage as Any)
        return (boardInfo,nil)
    }
    
    func storyActiveStoryBoards(userId: Int64,storyId: Int64,offset: Int64,pageSize: Int64,filter: String)async -> ([Common_StoryBoardActive]?,Int64?,Int64?,Error?){
        let apiClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_GetUserWatchStoryActiveStoryBoardsRequest.with {
            $0.userID = userId
            $0.storyID = storyId
            $0.offset = offset
            $0.pageSize = pageSize
            $0.filter = filter
        }
        print("storyActiveStoryBoards: ",request as Any)
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let response = await apiClient.getUserWatchStoryActiveStoryBoards(request: request, headers: header)
        if response.message?.code != Common_ResponseCode.ok{
            return (nil,offset,pageSize,NSError(domain: "storyActiveStoryBoards", code: 0, userInfo: [NSLocalizedDescriptionKey: "get story board active failed"]))
        }
        let boardActiveInfo = response.message?.storyboards
        let offset = response.message?.offset
        let pageSize = response.message?.pageSize
        return (boardActiveInfo,offset,pageSize,nil)
    }

    func userWatchRoleActiveStoryBoards(userId: Int64,roleId: Int64,offset: Int64,pageSize: Int64,filter: String)async -> ([Common_StoryBoardActive]?,Int64?,Int64?,Error?){
        let apiClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_GetUserWatchRoleActiveStoryBoardsRequest.with {
            $0.userID = userId
            $0.roleID = roleId
            $0.offset = offset
            $0.pageSize = pageSize
            $0.filter = filter
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let response = await apiClient.getUserWatchRoleActiveStoryBoards(request: request, headers: header)
        if response.message?.code != Common_ResponseCode.ok{
            return (nil,offset,pageSize,NSError(domain: "userWatchRoleActiveStoryBoards", code: 0, userInfo: [NSLocalizedDescriptionKey: "get user watch role active story boards failed"]))
        }
        let boardActiveInfo = response.message?.storyboards
        let offset = response.message?.offset
        let pageSize = response.message?.pageSize
        return (boardActiveInfo,offset,pageSize,nil)
    }

    func UnPublishStoryboard(userId: Int64,offset: Int64,pageSize: Int64) async -> ([Common_StoryBoardActive]?,Int64?,Int64?,Error?) {
        let apiClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_GetUnPublishStoryboardRequest.with {
            $0.userID = userId
            $0.offset = offset
            $0.pageSize = pageSize
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let response = await apiClient.getUnPublishStoryboard(request: request, headers: header)
        if response.message?.code != Common_ResponseCode.ok{
            return (nil,offset,pageSize,NSError(domain: "UnPublishStoryboard", code: 0, userInfo: [NSLocalizedDescriptionKey: "unpublish storyboard failed"]))
        }
        let storyboardActives = response.message?.storyboardactives
        let offset = response.message?.offset
        let pageSize = response.message?.pageSize
        return (storyboardActives,offset,pageSize,nil)
    }
    
    func updateStoryRoleAvatar(userId: Int64,roleId: Int64,avatar :String) async -> Error?{
        let apiClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_UpdateStoryRoleAvatorRequest.with {
            $0.userID = userId
            $0.roleID = roleId
            $0.avator = avatar
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let response = await apiClient.updateStoryRoleAvator(request: request, headers: header)
        if response.message?.code != Common_ResponseCode.ok{
            return NSError(domain: "updateStoryRoleAvatar", code: 0, userInfo: [NSLocalizedDescriptionKey: "update story role avatar failed"])
        }
        return nil
    }
    
    func updateStoryRoleBackgroud(userId: Int64,roleId: Int64,backgrondUrl: String) async -> Error?{
        let apiClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_UpdateStoryRoleDetailRequest.with {
            $0.userID = userId
            $0.roleID = roleId
            $0.backgroundImage = backgrondUrl
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let response = await apiClient.updateStoryRoleDetail(request: request, headers: header)
        if response.message?.code != Common_ResponseCode.ok{
            return NSError(domain: "updateStoryRoleBackgroud", code: 0, userInfo: [NSLocalizedDescriptionKey: "update story role background failed"])
        }
        return nil
    }
    
    func getNextStoryboard(userId:Int64,storyId:Int64,boardId:Int64,offset: Int64,pageSize: Int64,filter: Common_MultiBranchOrderBy) async ->  ([Common_StoryBoardActive]?,Int64?,Int64?,Error?){
        let apiClient = Common_TeamsApiClient(client: self.client!)
        let request = Common_GetNextStoryboardRequest.with {
            $0.userID = userId
            $0.storyboardID = boardId
            $0.storyID = storyId
            $0.offset = offset
            $0.pageSize = pageSize
            $0.orderBy = filter
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let response = await apiClient.getNextStoryboard(request: request, headers: header)
        if response.message?.code != Common_ResponseCode.ok{
            return (nil,offset,pageSize,NSError(domain: "getNextStoryboard", code: 0, userInfo: [NSLocalizedDescriptionKey: "get board branchs"]))
        }
        let boardActiveInfo = response.message?.storyboards
        let offset = response.message?.offset
        let pageSize = response.message?.pageSize
        return (boardActiveInfo,offset,pageSize,nil)
    }
    
}

