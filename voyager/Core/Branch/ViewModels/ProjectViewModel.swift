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
    @Published var info: Project
    @Published var projectProfile: ProjectProfile
    @Published var limelines: [TimeLineModel]
    init(groupInfo: BranchGroup, activeUsers: [User], projectInfo: Project, projectProfile: ProjectProfile, limelines: [TimeLineModel]) {
        self.groupInfo = groupInfo
        self.activeUsers = activeUsers
        self.info = projectInfo
        self.projectProfile = projectProfile
        self.limelines = limelines
    }
    
    func fetchProjectInfo() async {
        self.info = Project()
    }
    
    func fetchProjectJoinedUsers() async  {
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
