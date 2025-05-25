//
//  GroupViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/3/31.
//

import Foundation
import SwiftUI

class GroupViewModel: ObservableObject {
    @State public var user: User
    @Published public var groups: [BranchGroup]
    
    public var groupPage: Int32 = 0
    public var groupPageSize: Int32 = 10
    public var hasMorePages: Bool = true // 添加是否有更多页的标志
    
    init(user: User) {
        self.user = user
        self.groups = [BranchGroup]()
        print("GroupViewModel init")
    }
    
    // 重置分页
    func resetPagination() {
        print("resetPagination :",groupPage,hasMorePages)
        groupPage = 0
        hasMorePages = true
        groups.removeAll()
    }
    
    @MainActor
    func fetchGroups() async {
        // 用于刷新，重置 page
        self.groupPage = 0
        let (fetchedGroups, _, _) = await APIClient.shared.getUserCreateGroups(
            userId: user.userID,
            groupType: Common_GroupType(rawValue: 0)!,
            page: self.groupPage,
            size: self.groupPageSize
        )
        self.groups = fetchedGroups
        self.hasMorePages = !fetchedGroups.isEmpty && fetchedGroups.count == self.groupPageSize
        // 只在 fetchMoreGroups 里自增 groupPage
    }
    
    @MainActor
    func fetchMoreGroups() async {
        guard hasMorePages else { return }
        let nextPage = self.groupPage + 1
        print("req params: ", nextPage, self.groupPageSize)
        let (fetchedGroups, _, _) = await APIClient.shared.getUserCreateGroups(
            userId: user.userID,
            groupType: Common_GroupType(rawValue: 0)!,
            page: nextPage,
            size: self.groupPageSize
        )
        print("fetchMoreGroups: \(fetchedGroups.count), page: \(nextPage)")
        if !fetchedGroups.isEmpty {
            // 只追加未出现过的 group
            let newGroups = fetchedGroups.filter { new in
                !self.groups.contains(where: { $0.info.groupID == new.info.groupID })
            }
            self.groups.append(contentsOf: newGroups)
            self.hasMorePages = fetchedGroups.count == self.groupPageSize
            self.groupPage = nextPage // 只在成功时自增
            print("fetchMoreGroups page: \(self.groupPage)")
        } else {
            self.hasMorePages = false
        }
    }
    
    @MainActor
    func fetchGroupProfile(groupdId: Int64) async ->(Common_GroupProfileInfo?,Error?){
        var err: Error?
        var profileInfo: Common_GroupProfileInfo?
        (profileInfo,err) = await APIClient.shared.GetGroupProfile(groupId: groupdId, userId: self.user.userID)
        if err != nil {
            print("fetchGroupProfile err",err!)
            return (nil,err)
        }
        print("group profile: ",profileInfo!)
        return (profileInfo,nil)
    }
    
    @MainActor
    func createGroup(creatorId: Int64,name: String, description: String, avatar: String)async -> (BranchGroup?,Error?){
        var result: BranchGroup?
        var err: Error?
        // 在这里实现创建 Group 的逻辑
        let userId = creatorId

        (result,err) = await APIClient.shared.CreateGroup(userId: userId, name: name,desc: description,avatar: avatar)
        if err != nil {
            return (nil,err)
        }
        return (result!,nil)
    }
    
    func followGroup(userId:Int64,groupId:Int64)async -> Error?{
        let err = await APIClient.shared.followGroup(userId: userId, groupID: groupId)
        if err != nil {
            return err
        }
        return nil
    }
    
    func unfollowGroup(userId:Int64,groupId:Int64)async -> Error?{
        let err = await APIClient.shared.unfollowGroup(userId: userId, groupId: groupId)
        if err != nil {
            return err
        }
        return nil
    }
}

class GroupDetailViewModel: ObservableObject {
    @Published var user: User
    var groupId: Int64
    @Published var storys: [Story]
    @Published var members: [User]
    @Published var profile: GroupProfile?
    @Published var joinedGroup: Bool = true
    
    @State var storyPage: Int32 = 0
    @State var storyPageSize: Int32 = 10
    @State var memberPage: Int32 = 0
    @State var memberPageSize: Int32 = 10
    
    init(user: User, groupId: Int64) {
        self.user = user
        self.storys = [Story]()
        self.members = [User]()
        self.groupId = groupId
        Task { @MainActor in
            await self.fetchGroupStorys(groupdId: groupId)
        }
    }
    
    @MainActor
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
    
    @MainActor
    func fetchGroupMembers(groupdId: Int64) async  {
        var err: Error?
        var users: [User]?
        var page: Int64
        var pageSize: Int64
        (users,page,pageSize,err) = await APIClient.shared.getGroupMembers(groupId: self.groupId, page: Int64(self.memberPage),size: Int64(self.memberPageSize))
        if err != nil {
            print("fetchGroup members err",err!)
            return
        }
        self.memberPage = Int32(page)
        self.memberPageSize = Int32(pageSize)
        self.members = users!
    }
    
    @MainActor
    func fetchGroupStorys(groupdId: Int64) async  {
        var err: Error?
        var storys: [Story]?
        var page: Int64 = 0
        var pageSize: Int64 = 10
        (storys,page,pageSize,err) = await APIClient.shared.GetGroupStorys(groupId: self.groupId, userId: self.user.userID, page: Int64(self.storyPage), size: Int64(self.storyPageSize))
        if err != nil {
            print("fetchGroupStorys err: ",err as Any)
            return
        }
        if storys == nil {
            return
        }
        self.storyPage = Int32(page)
        self.storyPageSize = Int32(pageSize)
        self.storys = storys!
    }
    
    @MainActor
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
    
    @MainActor
    func LeaveGroup(groupdId: Int64) async -> Error?{
        var err: Error?
        var leaved: Bool = false
        (leaved,err) = await APIClient.shared.LeaveGroup(userId: self.user.userID, groupId: self.groupId)
        if err != nil {
            print("fleaveGroup err",err!)
            return err
        }
        if leaved {
            joinedGroup = false
        }else{
            joinedGroup = true
        }
        print("LeaveGroup success")
        return nil
    }
    
    @MainActor
    func followGroup(userId: Int64,groupId: Int64) async -> Error?{
        var err: Error?
        (err) = await APIClient.shared.followGroup(userId: self.user.userID, groupID: self.groupId)
        if err != nil {
            print("followGroup err",err!)
            return err
        }
        print("followGroup success")
        return nil
    }
    
    @MainActor
    func unFollowGroup(userId: Int64,groupId: Int64) async -> Error?{
        var err: Error?
        (err) = await APIClient.shared.unfollowGroup(userId: self.user.userID, groupId: self.groupId)
        if err != nil {
            print("unfollowGroup err",err!)
            return err
        }
        print("unfollowGroup success")
        return nil
    }
    
    @MainActor
    func watchStory(storyId: Int64,userId: Int64) async -> Error?{
        let (_,err) = await APIClient.shared.WatchStory(storyId: storyId, userId: userId)
        if err != nil {
            return err
        }
        return nil
    }

    @MainActor
    func unWatchStory(storyId: Int64,userId: Int64) async -> Error?{
        let (_,err) = await APIClient.shared.WatchStory(storyId: storyId, userId: userId)
        if err != nil {
            return err
        }
        return nil
    }
    
    @MainActor
    func likeStory(userId: Int64,storyId:Int64) async -> Error?{
        let (err) = await APIClient.shared.LikeStory(storyId: storyId, userId: userId)
        if err != nil {
            return err
        }
        return nil
    }
    
    @MainActor
    func unlikeStory(userId: Int64,storyId:Int64) async -> Error?{
        let (err) = await APIClient.shared.UnLikeStory(storyId: storyId, userId: userId)
        if err != nil {
            return err
        }
        return nil
    }
}
