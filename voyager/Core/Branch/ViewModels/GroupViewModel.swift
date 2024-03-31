//
//  GroupViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/3/31.
//

import Foundation


class GroupViewModel: ObservableObject {
    @Published var name: String
    @Published var user: User
    @Published var info: BranchGroup
    @Published var projectList: [Project]
    @Published var members: [User]
    @Published var groupProfile: GroupProfile
    init(name: String, user: User) {
        self.name = name
        self.user = user
        self.projectList = [Project]()
        self.members = [User]()
        self.groupProfile = GroupProfile()
        self.info  = BranchGroup()
    }
    
    func fetchGroupInfo() async{
        self.info  = BranchGroup()
    }
    
    func fetchGroupProfile() async {
        self.groupProfile = GroupProfile()
    }
    
    func fetchGroupMembers() async {
        self.members = [User]()
    }
    
    func fetchGroupProjects() async {
        self.projectList = [Project]()
    }
    
    func createNewProjectInGroup() async{
        
    }
    
    func updateGroupStatus() async{
        
    }

}
