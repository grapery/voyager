//
//  GroupService.swift
//  voyager
//
//  Created by grapestree on 2023/12/5.
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import Connect
import SwiftUI


extension APIClient {
    func getUserCreateGroups(userId: Int64, groupType: Common_GroupType, page: Int32, size: Int32) async  -> (groups: [BranchGroup], page: Int32, offset: Int32) {
        do {
            let request = Common_UserGroupRequest.with {
                $0.userID = userId
                $0.gtype = groupType
                $0.offset = page
                $0.pageSize = size
            }
            
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(token!)"]
            
            let authClient = Common_TeamsApiClient(client: self.client!)
            let response =  await authClient.userGroup(request: request, headers: header)
             
            if let data = response.message {
                let groups = data.list.map { BranchGroup(info: $0) }
                return (groups: groups, page: data.offset, offset: data.pageSize)
            } else {
                print("Error: No data returned from getUserCreateGroups")
                return (groups: [], page: 0, offset: 0)
            }
        } catch {
            print("Error fetching user created groups: \(error.localizedDescription)")
            return (groups: [], page: 0, offset: 0)
        }
    }
    
    func getJoinedGroups(userId: Int64, groupType: Common_GroupType, page: Int32, size: Int32) async -> (groups: [BranchGroup], page: Int32, offset: Int32) {
        do {
            let request = Common_UserGroupRequest.with {
                $0.userID = userId
                $0.gtype = groupType
                $0.offset = page
                $0.pageSize = size
            }
            
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(token!)"]
            
            let authClient = Common_TeamsApiClient(client: self.client!)
            let response = await authClient.userGroup(request: request, headers: header)
            
            if let data = response.message {
                let groups = data.list.map { BranchGroup(info: $0) }
                return (groups: groups, page: data.offset, offset: data.pageSize)
            } else {
                print("Error: No data returned from getUserCreateGroups")
                return (groups: [], page: 0, offset: 0)
            }
        } catch {
            print("Error fetching user created groups: \(error.localizedDescription)")
            return (groups: [], page: 0, offset: 0)
        }
    }
    
    func JoinGroup(userId: Int64, groupId: Int64) async -> (Bool, Error?) {
        do {
            let request = Common_JoinGroupRequest.with {
                $0.userID = userId
                $0.groupID = groupId
            }
            
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(token!)"]
            
            let authClient = Common_TeamsApiClient(client: self.client!)
            let response = try await authClient.joinGroup(request: request, headers: header)
            
            if response.message?.code == 0 {
                return (true, nil)
            } else {
                let errorMessage = response.message?.message ?? "Unknown error occurred while joining group"
                return (false, NSError(domain: "GroupService", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
            }
        } catch {
            return (false, error)
        }
    }
    
    func LeaveGroup(userId: Int64, groupId: Int64) async -> (Bool, Error?) {
        do {
            let request = Common_LeaveGroupRequest.with {
                $0.userID = userId
                $0.groupID = groupId
            }
            
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(token!)"]
            
            let authClient = Common_TeamsApiClient(client: self.client!)
            let response = try await authClient.leaveGroup(request: request, headers: header)
            
            if response.message?.code == 0 {
                return (true, nil)
            } else {
                let errorMessage = response.message?.message ?? "Unknown error occurred while joining group"
                return (false, NSError(domain: "GroupService", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
            }
        } catch {
            return (false, error)
        }
    }
    
    func CreateGroup(userId: Int64, name: String) async -> (BranchGroup?, Error?) {
        let result = BranchGroup(info: Common_GroupInfo())
        var response :ResponseMessage<Common_CreateGroupResponse>
        print("CreateGroup params: ",userId,"name ",name)
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            // Performed within an async context.
            let request = Common_CreateGroupReqeust.with {
                $0.userID = Int64(userId);
                $0.name = name
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(token!)"]
            response = await authClient.createGroup(request:request,headers:header)
            if let group = response.message?.data.info {
                result.info = group
                return (result, nil)
            } else {
                return (nil, NSError(domain: "GroupService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Group creation failed: No group returned"]))
            }
        } catch {
            return (nil, error)
        }
    }
    
    func GetGroupProfile(groupId: Int64,userId:Int64) -> (Common_GroupProfileInfo,Error?){
        
        return (Common_GroupProfileInfo(),nil)
    }
    
    func UpdateGroupProfile(groupId: Int64,userId:Int64,profile:Common_GroupProfileInfo)->Error?{
        return nil
    }
    
    func UpdateGroup(groupId: Int64,userId:Int64,avator: String,desc:String,owner:Int64,location: String,status: Int64) async->Error?{
        let result = BranchGroup(info: Common_GroupInfo())
        var response :ResponseMessage<Common_UpdateGroupInfoResponse>
        do {
            let apiClient = Common_TeamsApiClient(client: self.client!)
            // Performed within an async context.
            var groupInfo = Common_GroupInfo()
            groupInfo.avatar = avator
            groupInfo.desc = desc
            groupInfo.location = location
            groupInfo.status = Int32(status)
            groupInfo.owner = userId
            let request = Common_UpdateGroupInfoRequest.with {
                $0.groupID = groupId;
                $0.info = groupInfo
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(token!)"]
            response = await apiClient.updateGroupInfo(request:request,headers:header)
            if let group = response.message?.data.info {
                result.info = group
                return nil
            } else {
                return  NSError(domain: "GroupService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Update Group failed"])
            }
        } catch {
            return error
        }
        return nil
    }
    
    func getGroupMembers(groupId: Int64,page: Int64,size: Int64) async-> ([Common_UserInfo]?,Int64,Int64,Error?){
        do {
            let request = Common_FetchGroupMembersRequest.with {
                $0.groupID = groupId
                $0.offset = page
                $0.pageSize = size
            }
            
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(token!)"]
            
            let apiClient = Common_TeamsApiClient(client: self.client!)
            let response = await apiClient.fetchGroupMembers(request: request, headers: header)
            
            if response.message?.code != 0{
                let users = response.message?.data.list
                return (users, page, size,nil)
            } else {
                return ([], 0,  0,NSError(domain: "GroupService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Group members list failed"]))
            }
        } catch {
            print("Error fetching user in groups: \(error.localizedDescription)")
            return ([], 0,  0,NSError(domain: "GroupService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Group members list failed"]))
        }
    }
    
    func GetGroupStorys(groupId: Int64,userId: Int64,page: Int64,size: Int64) async -> ([Story]?,Int64,Int64,Error?){
        do {
            let request = Common_FetchGroupStorysReqeust.with {
                $0.groupID = groupId
                $0.page = Int32(page)
                $0.pageSize = Int32(size)
            }
            
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(token!)"]
            
            let apiClient = Common_TeamsApiClient(client: self.client!)
            let response = await apiClient.fetchGroupStorys(request: request, headers: header)
            
            if response.message?.code != 1{
                let storys = response.message?.data.list.map { Story(Id: $0.id, storyInfo: $0) }
                return (storys, page, size,nil)
            } else {
                return ([], 0,  0,NSError(domain: "GroupService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Group story list failed"]))
            }
        } catch {
            print("Error fetching user created groups: \(error.localizedDescription)")
            return ([], 0,  0,NSError(domain: "GroupService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Group story list failed"]))
        }
        
    }
}
