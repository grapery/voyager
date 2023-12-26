//
//  SearchViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation

class SearchViewModel: ObservableObject {
    
    @Published var users = [User]()
    @Published var projects = [Project]()
    @Published var groups = [BranchGroup]()
    @Published var currentUser :User?
    @Published var query: String = ""
    @Published var LastVisionTime: UInt64 = 0
    
    @Published var useAI: Bool = false
    @Published var useLocation: Bool = false
    @Published var offset: Int = 0
    @Published var limit: Int = 10
    
    init() {
        Task { try await FetchTrending() }
    }
    
    @MainActor
    func FetchTrending() async throws {
//        let result = try await SearchTrending()
//        self.projects = result.projects
//        self.groups = result.groups
//        self.users = result.users
//        self.currentUser = result.currentUser
    }
    
    
    
    
    @MainActor
    func SearchAllProject() async throws {
        
    }
    
    @MainActor
    func SearchProjectInGroup() async throws {
        
    }
    
    @MainActor
    func SearchProjectCreatedByUser() async throws {
        
    }
    @MainActor
    func SearchProjectJointedByUser() async throws {
        
    }
    @MainActor
    func SearchAllGroup() async throws {
        
    }
    @MainActor
    func SearchGroupCreatedByUser() async throws {
        
    }
    @MainActor
    func SearchGroupJointedByUser() async throws {
        
    }
    
}
