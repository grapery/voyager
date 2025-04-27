//
//  StoryRoleViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/10/26.
//

import SwiftUI
import Combine

class StoryRoleModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var storyId: Int64
    @State var roles: [StoryRole] = [StoryRole]()
    @Published var roleStoryboards: [StoryBoardActive] = [StoryBoardActive]()
    var userId: Int64
    
    var err: Error? = nil
    var page: Int64 = 0
    var pageSize: Int64 = 10
    
    init(storyId: Int64 = 0, userId: Int64 = 0) {
        self.storyId = storyId
        self.userId = userId
    }
    
    init(userId:Int64){
        self.userId = userId
        self.storyId = 0
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
        print("Fetching role detail for roleId: \(roleId), userId: \(self.userId)")
        let (role,err) = await APIClient.shared.getStoryRoleDetail(userId: self.userId, roleId: roleId)
        if let err = err {
            print("fetchStoryRoleDetail failed: \(err)")
            return (nil, err)
        }
        guard let role = role else {
            print("fetchStoryRoleDetail: No role data returned")
            return (nil, NSError(domain: "StoryRoleModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "No role data found"]))
        }
        print("fetchStoryRoleDetail succeeded: roleId=\(role.role.roleID), name=\(role.role.characterName)")
        return (role, nil)
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
    
    func likeStoryRole(roleId: Int64) async{
        let err = await APIClient.shared.LikeStoryRole(roleId: roleId, storyId: self.storyId, userId: self.userId)
        if err != nil{
            print("likeStoryboard failed: ",err!)
        }
    }
    
    func unlikeStoryRole(roleId: Int64) async{
        let (_,err) = await APIClient.shared.UnLikeStoryRole(userId: self.userId,roleId: roleId, storyId: self.storyId)
        if err != nil{
            print("likeStoryboard failed: ",err!)
        }
    }
    
    func generateRoleDescription(storyId: Int64,roleId:Int64,userId:Int64,sampleDesc: String) async -> (String?,Error?){
        return (sampleDesc,nil)
    }
    
    func updateRoleDescription(roleId:Int64,userId:Int64,desc: String)async -> Error?{
        return nil
    }
    
    func generateRolePrompt(storyId: Int64,roleId:Int64,userId:Int64,samplePrompt: String) async -> (String?,Error?){
        return (samplePrompt,nil)
    }
    
    func updateRolePrompt(userId: Int64,roleId:Int64,prompt: String)async -> Error?{
        return nil
    }
    
    
    func updateRoleAvatar(userId: Int64,roleId: Int64,avatar: String) async -> Error?{
        let err = await APIClient.shared.updateStoryRoleAvatar(userId: self.userId,roleId: roleId,avatar: avatar)
        if err != nil{
            print("updateRoleAvatar failed: ",err!)
            return err
        }
        return nil
    }
    
    func updateStoryRoleBackground(userId: Int64,roleId: Int64,backgroundAvatar: String) async{
        let err = await APIClient.shared.updateStoryRoleBackgroud(userId: userId, roleId: roleId,backgrondUrl: backgroundAvatar)
        if err != nil{
            print("updateStoryRoleBackground failed: ",err!)
        }
        return
    }
    
    func fetchRoleStoryboards(userId: Int64,roleId:Int64,storyName: String) async ->([StoryBoardActive]?,Error?){
        return (nil,nil)
    }
}


class StoryDetailViewModel: ObservableObject {
    @Published var story: Story?
    public let storyId: Int64
    public let userId: Int64
    @Published var characters: [StoryRole]? = []
    @Published var participants: [User] = []
    var likes: Int = 10
    var followers: Int = 10
    var shares: Int = 10
    
    private let apiClient = APIClient.shared
    
    init(story: Story? = nil, storyId: Int64, userId: Int64) {
        self.story = story
        self.storyId = storyId
        self.userId = userId
        
        self.characters = [StoryRole]()
        self.participants = [User]()
        self.likes = 10
        self.followers = 10
        self.shares = 10
        Task{
            await getTopStoryRoles(storyId: storyId, userId: userId)
        }
    }
    
    func fetchStoryDetails() async{
        // TODO: Implement API call to fetch story details
        
    }
    
    func saveStory() {
        // TODO: Implement API call to save story changes
    }
    
    func uploadImage(_ image: UIImage) async throws -> String {
        // 实现图片上传逻辑
        // 1. 压缩图片
        guard image.jpegData(compressionQuality: 0.6) != nil else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }
        
        // 2. 调用上传 API
        let imageUrl = try AliyunClient.UploadImage(image: image)
        return imageUrl
    }
    
    func getTopStoryRoles(
        storyId: Int64,
        userId: Int64
    ) async {
        do {
            let (roles, err) = await apiClient.getStoryRoles(userId: userId, storyId: storyId)
            if err != nil {
                print("getTopStoryRoles err: ", err as Any)
                return
            }
            // 在主线程上更新 UI
            await MainActor.run {
                self.characters = roles
            }
            print("characters : ", characters as Any)
        } catch {
            print("Error fetching top story roles: \(error)")
        }
    }
    
    func createStoryRole(
        storyId: Int64,
        name: String,
        description: String,
        avatar: String,
        characterPrompt: String,
        userId: Int64,
        characterRefImages: [String]?
    ) async {
        do {
            // 调用 API 创建角色
            var role = Common_StoryRole()
            role.storyID = storyId
            role.characterDescription = description
            role.characterName = name
            role.characterAvatar = avatar
            role.characterPrompt = characterPrompt
            role.characterRefImages = characterRefImages!
            role.creatorID = userId
            let err = await apiClient.createStoryRole(
                userId: self.userId,
                role: role
            )
            if err != nil{
                print("create story role failed: ",err as Any)
            }
            // 重新获取故事详情
            await fetchStoryDetails()
        }
    }
    
    func editStoryRole(){
        // TODO: Implement API call to edit role in story
    }
    
    func delStoryRole(){
        // TODO: Implement API call to delete role instory
    }
    
    func getTopParticipants(
        storyId: Int64,
        userId: Int64
    ) async {
        do {
            let (participants,err) = await apiClient.getStoryContributors(userId: userId, storyId: storyId)
            if err != nil {
                print("getTopParticipants err: ",err as Any)
                return
            }
            self.participants = participants!
            print("getTopParticipants : ",participants as Any)
        } catch {
            print("Error fetching top story roles: \(error)")
        }
    }
    
    func likeStory() async{
        let err = await APIClient.shared.LikeStory(storyId: self.storyId, userId: self.userId)
        if err != nil{
            print("likeStoryboard failed: ",err!)
        }
    }
    
    func unlikeStory() async{
        let err = await APIClient.shared.UnLikeStory(storyId: self.storyId, userId: self.userId)
        if err != nil{
            print("likeStoryboard failed: ",err!)
        }
        return
    }
    
    func updateStoryRoleAvatar(roleId: Int64,roleAvatar: String) async{
        let err = await APIClient.shared.updateStoryRoleAvatar(userId: self.userId,roleId: roleId,avatar: roleAvatar)
        if err != nil{
            print("likeStoryboard failed: ",err!)
        }
        return
    }
    
    func updateStoryRoleBackground(roleId: Int64,backgroundAvatar: String) async{
        let err = await APIClient.shared.updateStoryRoleBackgroud(userId: self.userId,roleId: roleId,backgrondUrl: backgroundAvatar)
        if err != nil{
            print("likeStoryboard failed: ",err!)
        }
        return
    }
    
}
