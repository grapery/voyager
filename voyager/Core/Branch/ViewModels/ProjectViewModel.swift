//
//  ProjectViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/3/31.
//

import Foundation


class ProjectViewModel: ObservableObject{
    @Published var groupInfo: BranchGroup
    @Published var activeUsers: [User]
    @Published var currentUser: User
    @Published var info: Project
    @Published var projectProfile: ProjectProfile
    @Published var limelines: [TimeLineModel]
    init(groupInfo: BranchGroup, activeUsers: [User], currentUser: User, info: Project, projectProfile: ProjectProfile, limelines: [TimeLineModel]) {
        self.groupInfo = groupInfo
        self.activeUsers = activeUsers
        self.currentUser = currentUser
        self.info = info
        self.projectProfile = projectProfile
        self.limelines = limelines
    }
    
    func fetchProjectInfo(projrctId: Int64) async {
        var realInfo = await APIClient.shared.getProjectInfo(userId: self.currentUser.userID, projrctId:projrctId)
        self.info = realInfo
    }
    
    func fetchProjectJoinedUsers() async  {
        var users = await APIClient.shared.getProjectProfile(userId: <#T##Int64#>, projrctId: <#T##Int64#>)
        self.activeUsers = [User]()
        return
    }
    
    func fetchProjectTimeline() async {
        self.limelines = [TimeLineModel]()
    }
    
    func fetchProjectForkItem() async{
        
    }
    
    func fetchProjectItem(timelineId: Int64,offset: Int64,num: Int64,filter:[String]) async {
        return
    }
}
