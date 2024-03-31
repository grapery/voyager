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
    @Published var projectInfo: Project
    @Published var projectProfile: ProjectProfile
    init(groupInfo: BranchGroup, activeUsers: [User], projectInfo: Project, projectProfile: ProjectProfile) {
        self.groupInfo = groupInfo
        self.activeUsers = activeUsers
        self.projectInfo = projectInfo
        self.projectProfile = projectProfile
    }
    
    func fetchProjectInfo() async {
        
    }
    
    func fetchProjectJoinedUsers() async {
        
    }
}
