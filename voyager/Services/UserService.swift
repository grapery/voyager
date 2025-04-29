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
    func fetchUser(withUid uid: Int64) async -> User {
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
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            resp = await authClient.userInfo(request: request, headers:header)
            result = resp.message!.data.info
        }
        return result
    }
    
    
    func fetchUsersInSameGroup(groupId:Int64,userId: Int64,offset: Int64,size: Int64) async  -> [User] {
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
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            resp = await authClient.fetchGroupMembers(request:request)
        }
        return resp.message!.data.list
    }

    
    func fetchUserProfile(userId: Int64) async -> UserProfile{
        if (globalUserToken == nil){
            return UserProfile()
        }
        
        var resp :ResponseMessage<Common_GetUserProfileResponse>
        let authClient = Common_TeamsApiClient(client: self.client!)
        // Performed within an async context.
        let request = Common_GetUserProfileRequest.with {
            $0.userID = Int64(userId)
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        resp = await authClient.getUserProfile(request:request, headers: header)
        if resp.code.rawValue != 0 {
            return UserProfile()
        }
        return resp.message!.info
    }
    
    func updateUserProfile(userId: Int64,backgroundImage:String,avatar: String,name: String,description_p:String,location: String,email: String) async -> Error?{
        var resp :ResponseMessage<Common_UpdateUserProfileResponse>
        let authClient = Common_TeamsApiClient(client: self.client!)
        // Performed within an async context.
        let request = Common_UpdateUserProfileRequest.with {
            $0.userID = Int64(userId)
            $0.backgroundImage = backgroundImage
            $0.avatar = avatar
            $0.name = name
            $0.description_p = description_p
            $0.location = location
            $0.email = email
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        resp = await authClient.updateUserProfile(request:request, headers: header)
        if resp.code.rawValue != 0 {
            return NSError(domain: "updateUserProfile", code: 0, userInfo: [NSLocalizedDescriptionKey: "updateUserProfile failed"])
        }
        return nil
    }
    
    func updateUserAvator(userId: Int64,avatorUrl: String) async -> Error?{
        var resp :ResponseMessage<Common_UpdateUserAvatorResponse>
        let authClient = Common_TeamsApiClient(client: self.client!)
        // Performed within an async context.
        let request = Common_UpdateUserAvatorRequest.with {
            $0.userID = Int64(userId)
            $0.avatar = avatorUrl
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        resp = await authClient.updateUserAvator(request:request, headers: header)
        if resp.code.rawValue != 0 {
            return NSError(domain: "updateUserAvator", code: 0, userInfo: [NSLocalizedDescriptionKey: "updateUserAvator failed"])
        }
        return nil
    }
    
    func updateUserBackgroud(userId: Int64,backgrouUrl: String) async -> Error?{
        var resp :ResponseMessage<Common_UpdateUserBackgroundImageResponse>
        let authClient = Common_TeamsApiClient(client: self.client!)
        // Performed within an async context.
        let request = Common_UpdateUserBackgroundImageRequest.with {
            $0.userID = Int64(userId)
            $0.backgroundImage = backgrouUrl
        }
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        resp = await authClient.updateUserBackgroundImage(request:request, headers: header)
        if resp.code.rawValue != 0 {
            return NSError(domain: "updateUserBackgroud", code: 0, userInfo: [NSLocalizedDescriptionKey: "updateUserBackgroud failed"])
        }
        return nil
    }
    

}
