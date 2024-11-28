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
    
    func fetchStoryRoleDetail(roleId:Int64) async -> (StoryRole?,Error?){
        let (role,err) = await APIClient.shared.getStoryRoleDetail(userId: self.userId, roleId: roleId)
        if err != nil {
            print("fetchStoryRoleDetail failed: ",err as Any)
            return (nil,err)
        }
        return (role,err)
    }
    
    func createNewStoryRole(role:Common_StoryRole) async -> Error?{
        let err = await APIClient.shared.createStoryRole(userId: self.userId, role: role)
        if err != nil {
            print("createNewStoryRole failed: ",err as Any)
            return err
        }
        return nil
    }
    
    func updateStoryRole(role:Common_StoryRole) async -> Error?{
        return nil
    }
    
    func genStoryRoleDetail(roleId:Int64,prompt: String,refImage:[String]) async -> Error?{
        let err = await APIClient.shared.RenderStoryRole(userId: self.userId, roleId: roleId, refImage: refImage, prompt: prompt)
        if err != nil {
            print("genStoryRoleDetail failed: ",err as Any)
            return err
        }
        return nil
    }
    
    func genStoryRoleAvatar() async -> Error?{
        return nil
    }
}
