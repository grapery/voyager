//
//  UserService.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import Connect
import SwiftUI

extension APIClient {
    func fetchUser(withUid uid: Int64) async throws -> User {
        var result = User()
        var resp :ResponseMessage<Common_UserInfoResponse>
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            // Performed within an async context.
            let request = Common_UserInfoRequest.with {
                $0.userID = Int64(uid);
                $0.account = ""
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(token!)"]
            resp = await authClient.userInfo(request: request, headers:header)
            result = resp.message!.info
        }
        return result
    }
    
    func fetchUsersInSameProject(projectId:Int64,userId: Int64) async throws -> ([User],Int32,Dictionary<String,Int64>) {
        var resp :ResponseMessage<Common_GetProjectMembersResponse>
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            // Performed within an async context.
            let request = Common_GetProjectMembersRequest.with {
                $0.userID = Int32(userId);
                $0.projectID = Int32(projectId)
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(token!)"]
            resp = await authClient.getProjectMembers(request:request)
        }
        return (resp.message!.list,resp.message!.total,resp.message!.role)
    }
    
    func fetchUsersInSameGroup(groupId:Int64,userId: Int64,offset: Int64,size: Int64) async throws -> [User] {
        var resp :ResponseMessage<Common_FetchGroupMembersResponse>
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            // Performed within an async context.
            let request = Common_FetchGroupMembersRequest.with {
                $0.groupID = Int64(groupId)
                $0.offset = Int64(offset)
                $0.pageSize = Int64(size)
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(token!)"]
            resp = await authClient.fetchGroupMembers(request:request)
        }
        return resp.message!.list
    }
    // 如果project有权限设置，就需要检查当前用户的权限
    func fetchUsersIsProjectWatcher(projectId:Int64,userId: Int64) async throws -> [User] {
        let users: [User] = []
        return users
    }
}
