//
//  GroupViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/3/31.
//

import Foundation
import SwiftUI


class GroupViewModel: ObservableObject {
    @Published public var user: User
    @Published public var groups: [BranchGroup]
    var page: Int32 = 0
    var size: Int32 = 10
    init(user: User) {
        self.user = user
        self.groups = [BranchGroup]()
    }
    
    func fetchGroups() async {
        var groups: [BranchGroup]
        (groups,self.page,self.size) = await APIClient.shared.getUserCreateGroups(userId: user.userID, groupType: Common_GroupType(rawValue: 0)! , page: self.page, size: self.size)
        self.groups = groups
    }
}

class GroupDetailViewModel: ObservableObject {
    @Published var user: User
    var groupId: Int64
    @Published var storys: [Story]
    @Published var members: [User]
    @Published var profile: GroupProfile?
    var page: Int = 0
    var size: Int = 0
    init(user: User,groupId:Int64) {
        self.user = user
        self.storys = [Story]()
        self.members = [User]()
        self.groupId = groupId
        Task{
            await self.fetchGroupStorys(groupdId:groupId)
        }
    }
    
    func fetchGroupProfile(groupdId: Int64) async {
        var err: Error?
        var profileInfo: Common_GroupProfileInfo?
        (profileInfo,err) = APIClient.shared.GetGroupProfile(groupId: self.groupId, userId: self.user.userID)
        if err != nil {
            print("fetchGroupProfile err",err!)
            return
        }
        self.profile = GroupProfile(profile: profileInfo!)
    }
    
    func fetchGroupMembers(groupdId: Int64)  {
        
    }
    
    func fetchGroupStorys(groupdId: Int64) async  {
        var err: Error?
        var storys: [Story]?
        var page: Int64 = 0
        var pageSize: Int64 = 10
        (storys,page,pageSize,err) = await APIClient.shared.GetGroupStorys(groupId: self.groupId, userId: self.user.userID, page: page, size: pageSize)
        if err != nil {
            print("fetchGroupStorys err",err!)
            return
        }
        self.storys = storys!
    }
    
}
