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
    
    func CreateStory(name: String,title: String,short_desc: String,creator: Int64,groupId: Int64,isAiGen: Bool,origin: String,params: Common_StoryParams) async -> (Story,Int64,Int64) {
        var result = Story()
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
            header[GrpcGatewayCookie] = ["\(token!)"]
            resp = await authClient.createStory(request: request, headers:header)
            result.Id = Int64(resp.message!.data.storyID)
            result.storyInfo.id = Int64(resp.message!.data.storyID)
            result.storyInfo.rootBoardID = Int64(resp.message!.data.boardID)
        }
        return (result,result.storyInfo.id,result.storyInfo.rootBoardID)
    }
    
    func GetStory(storyId: Int64) async -> (Story, Error?) {
        var result = Story()
        var err : Error? = nil
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_GetStoryInfoRequest.with {
                $0.storyID = storyId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(token!)"]
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
            header[GrpcGatewayCookie] = ["\(token!)"]
            
            let resp = await authClient.updateStory(request: request, headers: header)
            
            if resp.message?.code != 1 {
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
            header[GrpcGatewayCookie] = ["\(token!)"]
            
            let resp = await authClient.watchStory(request: request, headers: header)
            
            if resp.message?.code != 1 {
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
    
    func CreateStoryboard(storyId: Int64, prevBoardId: Int64, nextBoardId: Int64, creator: Int64, title: String, content: String, isAiGen: Bool, backgroud: String, params: Common_StoryBoardParams) async -> (StoryBoard, Error?) {
        print("CreateStoryboard request parameters:")
        print("storyId: \(storyId), prevBoardId: \(prevBoardId), nextBoardId: \(nextBoardId), creator: \(creator)")
        print("title: \(title), content: \(content), isAiGen: \(isAiGen), backgroud: \(backgroud)")
        print("params: \(params)")

        var result = StoryBoard(id: -1, boardInfo: Common_StoryBoard())
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            var  request = Common_CreateStoryboardRequest.with {
                $0.board = Common_StoryBoard(
                    
                )
            }
            
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(token!)"]
            
            let resp = await authClient.createStoryboard(request: request, headers: header)
            
            if resp.message?.code != 1 {
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
    
    func GetStoryboard(boardId: Int64) async -> (StoryBoard, Error?) {
        var result = StoryBoard(id: -1, boardInfo: Common_StoryBoard())
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_GetStoryboardRequest.with {
                $0.boardID = boardId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(token!)"]
            
            let resp = await authClient.getStoryboard(request: request, headers: header)
            
            if resp.message?.code != 1 {
                // If the response code is not 1, it indicates an error
                return (result, NSError(domain: "GetStoryboardError", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"]))
            }
            
            if let boardData = resp.message?.data {
                result.id = Int64(boardData.info.storyBoardID)
                result.boardInfo = boardData.info
            }
            
            return (result, nil)
        } catch {
            // If an exception occurs during the API call, return it as the error
            return (result, error)
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
            header[GrpcGatewayCookie] = ["\(token!)"]
            
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
    
    func GetStoryboards(storyId: Int64, branchId: Int64, startTime: Int64, endTime: Int64, offset: Int64, size: Int64) async -> (([StoryBoard], Int64, Int64, Error?)) {
        var storyboards: [StoryBoard] = []
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
            header[GrpcGatewayCookie] = ["\(token!)"]
            
            let resp = await authClient.getStoryboards(request: request, headers: header)
            
            if resp.message?.code != 0 {
                let error = NSError(domain: "GetStoryboardsError", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
                return ([], 0, 0, error)
            }
            if let boardsData = resp.message?.data {
                storyboards = boardsData.list.map { boardInfo in
                    StoryBoard(id: Int64(boardInfo.storyBoardID), boardInfo: boardInfo)
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
            header[GrpcGatewayCookie] = ["\(token!)"]
            
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
    
    func ForkStoryboard(prevboardId: Int64, storyId: Int64, userId: Int64, storyParam: Common_StoryBoard) async -> (Int64, Int64, Error?) {
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_ForkStoryboardRequest.with {
                $0.prevBoardID = prevboardId
                $0.storyID = storyId
                $0.userID = userId
                $0.board = storyParam
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(token!)"]
            
            let resp = await authClient.forkStoryboard(request: request, headers: header)
            
            if resp.message?.code != 0 {
                let error = NSError(domain: "ForkStoryboardError", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
                return (0, 0, error)
            }
            
            if let forkData = resp.message?.data {
                return (Int64(forkData.storyID), Int64(forkData.boardID), nil)
            } else {
                return (0, 0, NSError(domain: "ForkStoryboardError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
            }
        } catch {
            return (0, 0, error)
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
            header[GrpcGatewayCookie] = ["\(token!)"]
            
            let resp = await authClient.likeStoryboard(request: request, headers: header)
            
            if resp.message?.code != 0 {
                // If the response code is not 1, it indicates an error
                return NSError(domain: "LikeStoryboardError", code: Int(resp.message?.code ?? 0), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"])
            }
            
            // If successful, return nil (no error)
            return nil
        } catch {
            // If an exception occurs during the API call, return it as the error
            return error
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
            header[GrpcGatewayCookie] = ["\(token!)"]
            
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
            header[GrpcGatewayCookie] = ["\(token!)"]
            
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
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(token!)"]
            
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
            header[GrpcGatewayCookie] = ["\(token!)"]
            
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
            header[GrpcGatewayCookie] = ["\(token!)"]
            
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
}
