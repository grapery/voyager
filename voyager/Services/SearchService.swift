//
//  SearchService.swift
//  voyager
//
//  Created by grapestree on 2023/12/5.
//

import PhotosUI
import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import Connect
import SwiftUI

enum SearchType{
    case SearchProject
    case SearchGroup
    case SearchUser
    case SearchStory
}

extension APIClient {

    public func SearchGroups(name: String,userId: Int64,offset:Int64,pageSize: Int64) async -> ([BranchGroup]?,Int64,Int64,Error?){
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_SearchGroupRequest.with {
                $0.name = name
                $0.userID = userId
                $0.offset = offset
                $0.pageSize = pageSize
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            
            let resp = await authClient.searchGroup(request: request, headers: header)
            
            if resp.message?.code != Common_ResponseCode.ok {
                // If the response code is not 1, it indicates an error
                return (nil,0,0,NSError(domain: "SearchGroups", code: Int((resp.message?.code.rawValue)!), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"]))
            }
            var groups = [BranchGroup]()
            if let groupList = resp.message?.data.list {
                for item in groupList {
                    var group = BranchGroup(info: item)
                    groups.append(group)
                }
            }
            return (groups, resp.message?.data.offset ?? 0, resp.message?.data.pageSize ?? 0, nil)
        } catch {
            // If an exception occurs during the API call, return it as the error
            return (nil,0,0,NSError(domain: "SearchGroups error", code: -1))
        }
        return (nil,0,0,NSError(domain: "SearchGroups error", code: -1))
    }
    public func SearchUsers() async -> ([User],Int64,Int64){
        return ([User](),0,0)
    }
    public func SearchStoryRoles(name: String,userId: Int64,offset:Int64,pageSize: Int64,storyId:Int64) async ->([StoryRole]?,Int64,Int64,Error?){
        do{
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_SearchRolesRequest.with {
                $0.userID = userId
                $0.offset = offset
                $0.pageSize = pageSize
                $0.keyword = name
                $0.storyID = storyId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            let resp = await authClient.searchRoles(request: request, headers: header)
            if resp.message?.code != Common_ResponseCode.ok {
                return (nil,0,0,NSError(domain: "SearchStoryRoles", code: Int((resp.message?.code.rawValue)!), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"]))
            }
            var roles = [StoryRole]()
            if let roleList = resp.message?.roles {
                for item in roleList {
                    var role = StoryRole(Id:item.roleID,role: item)
                    roles.append(role)
                }
            }
        }catch{
            return (nil,0,0,NSError(domain: "SearchStoryRoles error", code: -1))
        }
        return (nil,0,0,NSError(domain: "SearchStoryRoles error", code: -1))
    }

    public func SearchStorys(name: String,userId: Int64,offset:Int64,pageSize: Int64,groupId:Int64) async ->([Story]?,Int64,Int64,Error?){
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            let request = Common_SearchStoriesRequest.with {
                $0.keyword = name
                $0.userID = userId
                $0.offset = offset
                $0.pageSize = pageSize
                $0.groupID = groupId
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            let resp = await authClient.searchStories(request: request, headers: header)
            if resp.message?.code != Common_ResponseCode.ok {
                return (nil,0,0,NSError(domain: "SearchStorys", code: Int((resp.message?.code.rawValue)!), userInfo: [NSLocalizedDescriptionKey: resp.message?.message ?? "Unknown error"]))
            }
            var stories = [Story]()
            if let storyList = resp.message?.stories {
                for item in storyList {
                    var story = Story(Id: item.id, storyInfo: item)
                    stories.append(story)
                }
            }
        }catch{
            return (nil,0,0,NSError(domain: "SearchStorys error", code: -1))
        }
        return (nil,0,0,NSError(domain: "SearchStorys error", code: -1))
    }

    public func TrendingGroups() async -> ([BranchGroup],Int64,Int64){
        return ([BranchGroup](),0,0)
    }
    public func TrendingUsers() async -> ([User],Int64,Int64){
        return ([User](),0,0)
    }
    
    public func TrendingStorys() async -> ([Story],Int64,Int64){
        return ([Story](),0,0)
    }
    public func TrendingStoryRole() async -> ([StoryRole],Int64,Int64){
        return ([StoryRole](),0,0)
    }
}
