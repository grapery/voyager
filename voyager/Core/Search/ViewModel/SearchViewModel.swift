//
//  SearchViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation

enum TrendingType: Int {
    case TrendingUsers
    case TrendingGroups
    case TrendingProjects
    case AllTrandingType
}

class SearchViewModel: ObservableObject {
    
    @Published var users = [User]()
    @Published var projects = [Project]()
    @Published var groups = [BranchGroup]()
    @Published var currentUser :User?
    @Published var query: String = ""
    @Published var useAI: Bool = false
    @Published var useLocation: Bool = false
    @Published var offset: Int = 0
    @Published var limit: Int = 10
    
    init(currentUser: User? = nil, query: String, useAI: Bool, useLocation: Bool, offset: Int, limit: Int) {
        self.users = [User]()
        self.projects = [Project]()
        self.groups = [BranchGroup]()
        self.currentUser = currentUser
        self.query = query
        self.useAI = useAI
        self.useLocation = useLocation
        self.offset = offset
        self.limit = limit
    }
    
    @MainActor
    func FetchTrending(trendingType: TrendingType) async  {
        if trendingType == .TrendingUsers{
            self.users =  await APIClient.shared.TrendingUsers()
        }else if trendingType == .TrendingProjects{
            self.projects = await APIClient.shared.TrendingProjects()
        }else if trendingType == .TrendingGroups {
            self.groups = await APIClient.shared.TrendingGroups()
        }else if trendingType == .AllTrandingType {
            self.users =  await APIClient.shared.TrendingUsers()
            self.projects = await APIClient.shared.TrendingProjects()
            self.groups = await APIClient.shared.TrendingGroups()
        }
    }
    
    @MainActor
    func SearchAllProject() async {
        
    }
    
    @MainActor
    func SearchProjectInGroup() async {
        
    }
    
    @MainActor
    func SearchUserProjectCreated() async {
        
    }
    @MainActor
    func SearchUserProjectJointed() async {
        
    }
    @MainActor
    func SearchAllGroup() async {
        
    }
    @MainActor
    func SearchUserGroupCreated() async {
        
    }
    @MainActor
    func SearchUserJointedGroup() async {
        
    }
    
}
