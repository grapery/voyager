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

// 行业经历数据模型
struct IndustryExperience: Identifiable, Codable {
    var id = UUID()
    var company: String
    var position: String
    var duration: String
    var description: String
    
    enum CodingKeys: String, CodingKey {
        case company, position, duration, description
    }
}

// 教育经历数据模型
struct EducationExperience: Identifiable, Codable {
    var id = UUID()
    var school: String
    var major: String
    var degree: String
    var duration: String
    var description: String
    
    enum CodingKeys: String, CodingKey {
        case school, major, degree, duration, description
    }
}

enum UserProfileFilterViewModel: Int, CaseIterable {
    case storyboards
    case roles
    case waitPublish
    
    var title: String {
        switch self {
        case .storyboards: return "创建的故事板"
        case .roles: return  "创建的角色"
        case .waitPublish: return "草稿"
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
    
    @Published var backgroundSelectedImage: PhotosPickerItem? {
        didSet {
            Task {
                await loadBackgroundImage(fromItem: backgroundSelectedImage)
            }
        }
    }
    
    @Published var userImage: Image?
    @Published var backgroundImage: UIImage?
    @Published var fullname = ""
    @Published var bio = ""
    @Published var address = ""
    @Published var isLoad = false
    
    // 行业经历相关
    @Published var industryExperiences: [IndustryExperience] = []
    @Published var showIndustryExperience = true
    
    // 教育经历相关
    @Published var educationExperiences: [EducationExperience] = []
    @Published var showEducationExperience = true
    
    @Published var stories = [Story]()
    @Published var storyRoles = [StoryRole]()
    @Published var groups = [BranchGroup]()
    @Published var storyboards = [StoryBoardActive]()
    
    private var StoriesPage = 0
    private var StoriesSize = 10
    private var StoryRolePage = 0
    private var StoryRoleSize = 10
    private var GroupsPage = 0
    private var GroupsSize = 10
    private var StoryboardsPage = 0
    private var StoryboardsSize = 10
    
    private var uiImage: UIImage?
    private var query: String = ""
    
    init(user: User) {
        self.user = user
        self.profile = UserProfile()
        if isLoad == true {
            print("user profile is load")
        } else {
            Task {
                await MainActor.run {
                    self.isLoad = true
                }
                let newProfile = await self.fetchUserProfile()
                await MainActor.run {
                    self.profile = newProfile
                    self.loadUserData()
                }
            }
        }
    }
    
    // 加载用户数据到UI
    @MainActor
    private func loadUserData() {
        self.fullname = user?.name ?? ""
        self.bio = user?.desc ?? ""
        self.address = user?.location ?? ""
        
        // 这里可以从profile中加载行业经历和教育经历数据
        // 暂时使用空数组，后续可以从API获取
        self.industryExperiences = []
        self.educationExperiences = []
    }
    
    // 添加行业经历
    @MainActor
    func addIndustryExperience() {
        guard industryExperiences.count < 10 else { return }
        let newExperience = IndustryExperience(
            company: "",
            position: "",
            duration: "",
            description: ""
        )
        industryExperiences.append(newExperience)
    }
    
    // 删除行业经历
    @MainActor
    func removeIndustryExperience(at index: Int) {
        guard index < industryExperiences.count else { return }
        industryExperiences.remove(at: index)
    }
    
    // 添加教育经历
    @MainActor
    func addEducationExperience() {
        guard educationExperiences.count < 10 else { return }
        let newExperience = EducationExperience(
            school: "",
            major: "",
            degree: "",
            duration: "",
            description: ""
        )
        educationExperiences.append(newExperience)
    }
    
    // 删除教育经历
    @MainActor
    func removeEducationExperience(at index: Int) {
        guard index < educationExperiences.count else { return }
        educationExperiences.remove(at: index)
    }
    
    // 切换行业经历显示状态
    @MainActor
    func toggleIndustryExperienceVisibility() {
        showIndustryExperience.toggle()
    }
    
    // 切换教育经历显示状态
    @MainActor
    func toggleEducationExperienceVisibility() {
        showEducationExperience.toggle()
    }
    
    @MainActor
    func updateUserInfo(newUser: User) {
        self.user = newUser
        Task {
            let newProfile = await self.fetchUserProfile()
            self.profile = newProfile
        }
    }
    
    func fetchUserProfile() async -> UserProfile {
        let profile = await APIClient.shared.fetchUserProfile(userId: self.user?.userID ?? -1)
        return profile
    }
    
    @MainActor
    public func signOut() async {
        await AuthService.shared.signout()
    }
    
    @MainActor
    public func updateProfile() async {
        // 更新用户基本信息
        user?.name = fullname
        user?.desc = bio
        user?.location = address
        
        _ = await APIClient.shared.updateUserProfile(
            userId: user!.userID,
            backgroundImage: self.profile.backgroundImage,
            avatar: user!.avatar,
            name: user!.name,
            description_p: user!.desc,
            location: user!.location,
            email: user!.email
        )
        
        // 在主线程更新 profile
        let updatedProfile = await self.fetchUserProfile()
        await MainActor.run {
            self.profile = updatedProfile
        }
    }
    
    func loadImage(fromItem item: PhotosPickerItem?) async {
        // 释放之前的图片
        self.uiImage = nil
        self.userImage = nil
        guard let item = item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        
        await MainActor.run {
            self.uiImage = uiImage
            self.userImage = Image(uiImage: uiImage)
        }
    }
    
    func loadBackgroundImage(fromItem item: PhotosPickerItem?) async {
        guard let item = item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        
        await MainActor.run {
            self.uiImage = uiImage
            self.backgroundImage = uiImage
        }
    }
    
    @MainActor
    public func updateAvator(userId:Int64,newAvatorUrl: String) async -> Error?{
        let err = await APIClient.shared.updateUserAvator(userId: userId, avatorUrl: newAvatorUrl)
        if err != nil {
            return err
        }
        return nil
    }
    
    func updateUserbackgroud(userId: Int64,backgroundImageUrl: String) async -> Error?{
        let err = await APIClient.shared.updateUserBackgroud(userId: userId, backgrouUrl: backgroundImageUrl)
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
    
    func fetchUserCreatedStoryboards(userId: Int64,groupId:Int64,storyId:Int64) async throws -> ([StoryBoardActive]?,Error?){
        let result = await APIClient.shared.fetchUserCreatedStoryBoards(userId: userId, page: Int64(self.StoryboardsPage), size: Int64(self.StoryboardsSize), storyId: storyId)
        if result.3 != nil {
            self.StoryboardsPage = 0
            self.StoryboardsSize = 10
            return (nil,result.3)
        }
        self.StoryboardsPage = Int(result.1)
        self.StoryboardsSize = 10
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
        self.StoryRoleSize = 10
        return (result.0,nil)
    }
    
    func fetchUserUnPublishedStoryboards(userId: Int64,groupId:Int64,storyId:Int64,status: Int64) async throws -> ([StoryBoardActive]?,Error?){
        let result = await APIClient.shared.fetchUserCreatedStoryBoards(userId: userId, page: Int64(self.StoryboardsPage), size: Int64(self.StoryboardsSize), storyId: storyId)
        if result.3 != nil {
            self.StoryboardsPage = 0
            self.StoryboardsSize = 10
            return (nil,result.3)
        }
        self.StoryboardsPage = Int(result.1)
        self.StoryboardsSize = 10
        return (result.0,nil)
    }
}
