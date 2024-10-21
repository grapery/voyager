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
    case TrendingStorys
    case TrendingStoryRoles
}

class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var currentUser :User?
    
    @Published var users = [User]()
    @Published var storys = [Story]()
    @Published var groups = [BranchGroup]()
    @Published var storyRoles = [StoryRole]()
    
    @Published var useAI: Bool = false
    @Published var useLocation: Bool = false
    var page: Int64 = 0
    var pageSize: Int64 = 10
    
    init(currentUser: User? = nil, query: String, useAI: Bool, useLocation: Bool, offset: Int, limit: Int) {
        self.users = [User]()
        self.storys = [Story]()
        self.groups = [BranchGroup]()
        self.currentUser = currentUser
        self.query = query
        self.useAI = useAI
        self.useLocation = useLocation
        self.page = Int64(offset)
        self.pageSize = Int64(limit)
    }
    
    @MainActor
    func FetchTrending(trendingType: TrendingType) async  {
        if trendingType == .TrendingUsers{
            (self.users,self.page,self.pageSize) =  await APIClient.shared.TrendingUsers()
        }else  if trendingType == .TrendingGroups {
            (self.groups,self.page,self.pageSize) = await APIClient.shared.TrendingGroups()
        }else if trendingType == .TrendingStorys {
            (self.storys,self.page,self.pageSize) = await APIClient.shared.TrendingStorys()
        }else if trendingType == .TrendingStoryRoles {
            (self.storyRoles,self.page,self.pageSize) = await APIClient.shared.TrendingStoryRole()
        }
    }
    
    @MainActor
    func SearchAllStory() async {
        
    }
    
    @MainActor
    func SearchStoryInGroup() async {
        
    }
    
    @MainActor
    func SearchUserCreatedStory() async {
        
    }
    @MainActor
    func SearchUserContributeStory() async {
        
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
