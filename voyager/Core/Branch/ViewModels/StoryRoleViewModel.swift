//
//  StoryRoleViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/10/26.
//

import SwiftUI
import Combine

class StoryRoleModel: ObservableObject {
    @Published var story: Story?
    @Published var isLoading: Bool = false
    @Published var storyId: Int64
    @State var roles: [StoryRole] = [StoryRole]()
    var userId: Int64
    var isUpdateOk: Bool = false
    var isCreateOk: Bool = false
    var isGenerate: Bool = false
    
    var err: Error? = nil
    var page: Int64 = 0
    var pageSize: Int64 = 10
    
    
    init(story: Story? = nil, storyId: Int64, err: Error? = nil, page: Int64, pageSize: Int64, userId: Int64) {
        self.story = story
        self.storyId = storyId
        self.err = err
        self.page = page
        self.pageSize = pageSize
        self.userId = userId
        Task{
            await fetchStoryRoles(storyId:storyId)
        }
    }
    func fetchStoryRoles(storyId:Int64) async {
        let (roles,err) = await APIClient.shared.getStoryRoles(userId: self.userId, storyId: storyId)
        if err != nil {
            print("fetchStoryboard failed: ",err as Any)
            return
        }
        self.roles = roles!
        return 
    }
    
    func fetchStoryRoleDetail() async -> Error?{
        return nil
    }
    
    func createNewStoryRole() async -> (Int64,Error?){
        return (0,nil)
    }
    
    func updateStoryRole() async -> Error?{
        return nil
    }
    
    func genStoryRoleDetail() async -> Error?{
        return nil
    }
    
    func genStoryRoleAvatar() async -> Error?{
        return nil
    }
}
