//
//  FeedViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation

class FeedViewModel: ObservableObject {
    @Published var projectId: Int64
    @Published var groupId: Int64
    @Published var timeline: Int64
    @Published var leaves: [StoryItem]
    @Published var filters = [String]()
    @Published var page: Int64
    @Published var size: Int64
    @Published var timeStamp: Int64
    @Published var user:User
    @Published var tags: [String]
    
    init(user: User) {
        self.projectId = 0
        self.groupId = 0
        self.timeline = 0
        self.leaves = [StoryItem]()
        self.filters = [String]()
        self.page = 0
        self.size = 0
        self.timeStamp = 0
        self.user = user
        self.tags = [String]()
    }
    
    @MainActor
    func fetchLeaves() async -> Void{
        let result = await APIClient.shared.fetchUserLeaves(uid: self.user.userID, offset: self.page,size: self.size, filter: [])
        if result?.1 == 0 {
            return
        }
        self.leaves = result?.0 ?? [StoryItem]()
        return
    }
    
    @MainActor
    func fetchTimelineLeaves() async -> Void {
        
    }
    
    @MainActor
    func fetchProjectLeaves() async -> Void {
        var (result,pageNum,pageSize) = await APIClient.shared.fetchProjectLeaves(groupId: self.groupId, projectId: self.projectId, offset: self.page, size: self.size, filter: self.filters)
        self.leaves = result
        self.page = pageNum
        self.size = pageSize
        return
    }
    
    @MainActor
    func fetchGroupLeaves() async -> Void {
        var (result,pageNum,pageSize) = await APIClient.shared.fetchGroupLeaves(groupId: self.groupId, offset: self.page, size: self.size, filter: self.filters)
        self.leaves = result
        self.page = pageNum
        self.size = pageSize
        return
    }
}

class TimeLineModel: ObservableObject{
    @Published var timelineId: Int64
    @Published var rootId: Int64
    @Published var totalCount: Int64
    @Published var forkId: [Int64]
    @Published var currentId: Int64
    
    @Published var leaves = [StoryItem]()
    @Published var filters = [String]()
    @Published var page: Int64
    @Published var size: Int64
    @Published var timeStamp: Int64
    @Published var user:User
    
    init(timelineId: Int64, user: User) {
        self.timelineId = timelineId
        self.rootId = 0
        self.totalCount = 0
        self.forkId = [Int64]()
        self.currentId = 0
        self.leaves = [StoryItem]()
        self.filters = [String]()
        self.page = 0
        self.size = 0
        self.timeStamp = 0
        self.user = user
    }
    
    func fetchTimelineLeaves() async -> Void {
        
    }
}
