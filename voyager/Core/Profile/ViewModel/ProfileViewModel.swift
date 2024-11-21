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
    case storys
    case groups
    case roles
    
    var title: String {
        switch self {
        case .storys: return "参与的故事"
        case .groups: return "加入的小组"
        case .roles: return  "关注的角色"
        }
    }
}


class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var profile: UserProfile
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
    
    @State var StoryRolePage = 0
    @State var StoryRoleSize = 10
    
    @State var GroupsPage = 0
    @State var GroupsSize = 10
    
    private var uiImage: UIImage?
    
    init(user: User) {
        self.user = user
        self.profile = UserProfile()
        if isLoad == true {
            print("user profile is load")
        }else{
            Task{
                await fetchUserProfile()
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
        let newProfile = await APIClient.shared.updateUserProfile(userId: self.user!.userID,profile: self.profile)
        print(newProfile)
    }
    
    func loadImage(fromItem item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        self.uiImage = uiImage
        self.userImage = Image(uiImage: uiImage)
        
    }
    
    func updateUserDate() async throws {
        var data = [String: Any]()
        if let uiImage = self.uiImage {
            let imageUrl = try? await APIClient.shared.uploadImage(image: uiImage,filename: "data.jpg")
            data["profileImageUrl"] = imageUrl
        }
        if !fullname.isEmpty && user!.name != fullname {
            data["fullname"] = fullname
            
        }
    }
    
    func fetchUserStories(keyword: String, userId: Int64, page: Int64, size: Int64,groupId:Int64) async throws -> ([Story]?,Error?){
        do{
            let result = try await APIClient.shared.SearchStories(keyword: keyword, userId: userId, page: page, size: size)
            if result.3 != nil {
                self.StoriesPage = 0
                self.StoriesSize = 10
                return (nil,result.3)
            }
            self.StoriesPage = Int(result.1)
            self.StoriesSize = Int(result.2)
            return (result.0,nil)
        }catch{
            return (nil,error)
        }
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
    
    func fetchUserGroups(keyword: String, userId: Int64, page: Int64, size: Int64) async throws -> ([BranchGroup]?,Error?){
        do{
            let result = try await APIClient.shared.SearchGroups(name: keyword, userId: userId, offset: page, pageSize: size)
            if result.3 != nil {
                self.GroupsPage = 0
                self.GroupsSize = 10
                return (nil,result.3)
            }
            self.GroupsPage = Int(result.1)
            self.GroupsSize = Int(result.2)
            return (result.0,nil)
        }catch{
            return (nil,error)
        }
    }
    
    func fetchUserStoryRoles(keyword: String, userId: Int64, page: Int64, size: Int64,groupId:Int64) async throws -> ([StoryRole]?,Error?){
        do{
            let result = try await APIClient.shared.SearchStoryRoles(keyword: keyword, userId: userId, page: page, size: size)
            if result.3 != nil {
                self.StoryRolePage = 0
                self.StoryRoleSize = 10
                return (nil,result.3)
            }
            self.StoryRolePage = Int(result.1)
            self.StoryRoleSize = Int(result.2)
            return (result.0,nil)
        }catch{
            return (nil,error)
        }
    }
}
