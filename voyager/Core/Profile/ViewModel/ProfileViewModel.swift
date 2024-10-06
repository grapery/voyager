//
//  ProfileViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation
import PhotosUI
import SwiftUI

class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var profile: UserProfile
    @Published var selectedImage: PhotosPickerItem? {
        didSet { Task { await loadImage(fromItem: selectedImage)}}
    }
    
    @Published var userImage: Image?
    @Published var fullname = ""
    @Published var bio = ""
    
    private var uiImage: UIImage?
    
    init(user: User) {
        self.user = user
        self.profile = UserProfile()
        Task{
            await fetchUserProfile()
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
}
