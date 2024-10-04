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
        let realInfo = await APIClient.shared.getProjectInfo(userId: self.currentUser.userID, projectId:projrctId)
        self.info = realInfo
        return
    }
    
    func fetchProjectJoinedUsers(projrctId: Int64,filter: [String]) async  {
        let (users,_,_) = await APIClient.shared.getProjectJoinedUsers(projectId: projrctId, filter:filter)
        self.activeUsers = users
        return
    }
    
    func fetchProjectTimeline(projrctId: Int64,forkId: Int64,timeStamp: Int64,filter: [String]) async {
        
        self.limelines = [TimeLineModel]()
    }
    
    func fetchProjectForkItems(projrctId: Int64,forkId: Int64,timeStamp: Int64,filter: [String]) async -> ([StoryItem],Int64,Int64){
        return ([StoryItem](),0,0)
    }
    
    func fetchProjectItems(timelineId: Int64,timeStamp: Int64,offset: Int64,num: Int64,filter:[String]) async -> ([StoryItem],Int64,Int64){
        
        return ([StoryItem](),0,0)
    }
    
    func closeProject(projectId:Int64,userId: Int64) async{
        
    }
}
