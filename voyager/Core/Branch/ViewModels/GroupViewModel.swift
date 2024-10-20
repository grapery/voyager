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
    @Published public var groupsProfile: Dictionary<Int64,GroupProfile>
    var page: Int32 = 0
    var size: Int32 = 10
    init(user: User) {
        self.user = user
        self.groups = [BranchGroup]()
        self.groupsProfile = Dictionary<Int64,GroupProfile>()
    }
    
    func fetchGroups() async {
        var groups: [BranchGroup]
        (groups,self.page,self.size) = await APIClient.shared.getUserCreateGroups(userId: user.userID, groupType: Common_GroupType(rawValue: 0)! , page: self.page, size: self.size)
        self.groups = groups
        for group in groups {
            await self.fetchGroupProfile(groupdId: group.info.groupID)
        }
    }
    
    func fetchGroupProfile(groupdId: Int64) async {
        var err: Error?
        var profileInfo: Common_GroupProfileInfo?
        (profileInfo,err) = await APIClient.shared.GetGroupProfile(groupId: groupdId, userId: self.user.userID)
        if err != nil {
            print("fetchGroupProfile err",err!)
            return
        }
        groupsProfile[groupdId]=GroupProfile(profile: profileInfo!)
    }
}

class GroupDetailViewModel: ObservableObject {
    @Published var user: User
    var groupId: Int64
    @Published var storys: [Story]
    @Published var members: [User]
    @Published var profile: GroupProfile?
    @Published var joinedGroup: Bool = true
    var page: Int = 0
    var size: Int = 10
    var memberPage: Int64 = 0
    var memberPagesize: Int64 = 10
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
        (profileInfo,err) = await APIClient.shared.GetGroupProfile(groupId: self.groupId, userId: self.user.userID)
        if err != nil {
            print("fetchGroupProfile err",err!)
            return
        }
        self.profile = GroupProfile(profile: profileInfo!)
    }
    
    func fetchGroupMembers(groupdId: Int64) async  {
        var err: Error?
        var users: [User]?
        var page: Int64
        var pageSize: Int64
        (users,page,pageSize,err) = await APIClient.shared.getGroupMembers(groupId: self.groupId, page: self.memberPage,size: self.memberPagesize)
        if err != nil {
            print("fetchGroup members err",err!)
            return
        }
        self.memberPage = page
        self.memberPagesize = pageSize
        self.members = users!
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
    
    func JoinGroup(groupdId: Int64) async  {
        var err: Error?
        var joined: Bool = false
        (joined,err) = await APIClient.shared.JoinGroup(userId: self.user.userID, groupId: self.groupId)
        if err != nil {
            print("JoinGroup err",err!)
            return
        }
        if joined {
            joinedGroup = true
        }else{
            joinedGroup = false
        }
        print("JoinGroup success")
    }
    
    func LeaveGroup(groupdId: Int64) async  {
        var err: Error?
        var leaved: Bool = false
        (leaved,err) = await APIClient.shared.LeaveGroup(userId: self.user.userID, groupId: self.groupId)
        if err != nil {
            print("fleaveGroup err",err!)
            return
        }
        if leaved {
            joinedGroup = false
        }else{
            joinedGroup = true
        }
        print("LeaveGroup success")
    }
    
}
