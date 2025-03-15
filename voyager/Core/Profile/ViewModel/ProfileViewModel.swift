//
//  ProfileViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import PhotosUI
import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import Connect
import SwiftUI

enum UserProfileFilterViewModel: Int, CaseIterable {
    case storyboards
    case roles
    case waitPublish
    
    var title: String {
        switch self {
        case .storyboards: return "创建的故事板"
        case .roles: return  "创建的角色"
        case .waitPublish: return "待发布"
        }
    }
}


class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @State var profile: UserProfile
    @Published var selectedImage: PhotosPickerItem? {
        didSet {
            Task {
                await loadImage(fromItem: selectedImage)
            }
        }
    }
    
    @Published var userImage: Image?
    @Published var fullname = ""
    @Published var bio = ""
    @State var isLoad = false
    
    @State var StoriesPage = 0
    @State var StoriesSize = 10
    @Published var stories = [Story]()
    
    @State var StoryRolePage = 0
    @State var StoryRoleSize = 10
    @Published var storyRoles = [StoryRole]()
    
    @State var GroupsPage = 0
    @State var GroupsSize = 10
    @Published var groups = [BranchGroup]()
    
    @State var StoryboardsPage = 0
    @State var StoryboardsSize = 10
    @Published var storyboards = [StoryBoard]()
    
    private var uiImage: UIImage?
    
    @State var query: String = ""
    
    init(user: User) {
        self.user = user
        self.profile = UserProfile()
        if isLoad == true {
            print("user profile is load")
        }else{
            Task{
                self.profile = await fetchUserProfile()
            }
        }
        
    }
    func fetchUserProfile() async -> UserProfile{
        let profile = await APIClient.shared.fetchUserProfile(userId: self.user?.userID ?? -1)
        return profile
    }
    
    @MainActor
    public func signOut() async {
        await AuthService.shared.signout()
    }
    
    @MainActor
    public func updateProfile() async {
        let newProfile = await APIClient.shared.updateUserProfile(userId: user!.userID,backgroundImage:self.profile.backgroundImage,avatar: user!.avatar,name: user!.name,description_p: user!.desc,location:  user!.location,email:  user!.email)
        print(newProfile as Any)
        return
    }
    
    func loadImage(fromItem item: PhotosPickerItem?) async {
        guard let item = item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        self.uiImage = uiImage
        self.userImage = Image(uiImage: uiImage)
        
    }
    
    @MainActor
    public func updateAvator(userId:Int64,newAvatorUrl: String) async -> Error?{
        let err = await APIClient.shared.updateUserAvator(userId: userId, avatorUrl: newAvatorUrl)
        print("updateAvator err:", err?.localizedDescription as Any)
        if err != nil {
            return err
        }
        return nil
    }
    
    func updateUserData() async throws {
        
    }
    
    func updateUserbackgroud(userId: Int64,backgroundImageUrl: String) async -> Error?{
        let err = await APIClient.shared.updateUserAvator(userId: userId, avatorUrl: backgroundImageUrl)
        print("updateUserbackgroud err:", err?.localizedDescription as Any)
        if err != nil {
            return err
        }
        return nil
    }
    
    func ResetStoriesParams(){
        self.StoriesPage = 0
        self.StoriesSize = 10
    }
    func ResetGroupsParams(){
        self.GroupsPage = 0
        self.GroupsSize = 10
    }
    func ResetStoryRolesParams(){
        self.StoryRolePage = 0
        self.StoryRoleSize = 10
    }
    
    func SearchStories(userId: Int64,groupId:Int64) async throws -> ([Story]?,Error?){
        let result = await APIClient.shared.SearchStories(keyword: self.query, userId: userId, page: Int64(self.StoriesPage), size: Int64(self.StoriesSize))
        if result.3 != nil {
            self.StoriesPage = 0
            self.StoriesSize = 10
            return (nil,result.3)
        }
        self.StoriesPage = Int(result.1)
        self.StoriesSize = Int(result.2)
        return (result.0,nil)
    }
    
    
    
    func SearchStoryRoles(userId: Int64,groupId:Int64) async throws -> ([StoryRole]?,Error?){
        let result = await APIClient.shared.SearchStoryRoles(keyword: self.query, userId: userId, page: Int64(self.StoryRolePage), size: Int64(self.StoryRoleSize))
        if result.3 != nil {
            self.StoryRolePage = 0
            self.StoryRoleSize = 10
            return (nil,result.3)
        }
        self.StoryRolePage = Int(result.1)
        self.StoryRoleSize = Int(result.2)
        return (result.0,nil)
    }
    
    func fetchUserCreatedStoryboards(userId: Int64,groupId:Int64,storyId:Int64) async throws -> ([StoryBoard]?,Error?){
        let result = await APIClient.shared.fetchUserCreatedStoryBoards(userId: userId, page: Int64(self.StoryboardsPage), size: Int64(self.StoryboardsSize), storyId: storyId)
        if result.3 != nil {
            self.StoryboardsPage = 0
            self.StoryboardsSize = 10
            return (nil,result.3)
        }
        self.StoryboardsPage = Int(result.1)
        self.StoryboardsSize = Int(result.2)
        return (result.0,nil)
    }
    
    func fetchUserCreatedStoryRoles(userId: Int64,groupId:Int64,storyId:Int64) async throws -> ([StoryRole]?,Error?){
        let result = await APIClient.shared.fetchUserCreatedStoryRoles(userId: userId, page: Int64(self.StoryboardsPage), size: Int64(self.StoryRoleSize), storyid: storyId)
        if result.3 != nil {
            self.StoryRolePage = 0
            self.StoryRoleSize = 10
            return (nil,result.3)
        }
        self.StoryRolePage = Int(result.1)
        self.StoryRoleSize = Int(result.2)
        print("fetchUserCreatedStoryRoles result: ",result)
        return (result.0,nil)
    }
    
    func fetchUserUnPublishedStoryboards(userId: Int64,groupId:Int64,storyId:Int64,status: Int64) async throws -> ([StoryBoard]?,Error?){
        let result = await APIClient.shared.fetchUserCreatedStoryBoards(userId: userId, page: Int64(self.StoryboardsPage), size: Int64(self.StoryboardsSize), storyId: storyId)
        if result.3 != nil {
            self.StoryboardsPage = 0
            self.StoryboardsSize = 10
            return (nil,result.3)
        }
        self.StoryboardsPage = Int(result.1)
        self.StoryboardsSize = Int(result.2)
        return (result.0,nil)
    }
}
