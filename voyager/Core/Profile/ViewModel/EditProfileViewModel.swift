//
//  EditProfileViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation
import PhotosUI
import SwiftUI

@MainActor
class EditProfileViewModel: ObservableObject {
    
    @Published var user: User
    
    @Published var selectedImage: PhotosPickerItem? {
        didSet { Task { await loadImage(fromItem: selectedImage)}}
    }
    
    @Published var userImage: Image?
    
    @Published var fullname = ""
    @Published var bio = ""
    
    private var uiImage: UIImage?
    
    init(user: User) {
        self.user = user
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
            let imageUrl = try? await ImageUploader.uploadImage(image: uiImage)
            data["profileImageUrl"] = imageUrl
        }
        if !fullname.isEmpty && user.name != fullname {
            data["fullname"] = fullname
            
        }
    }
}

@MainActor
class EditProjectProfileViewModel: ObservableObject {
    @Published var projectProfile: ProjectProfile
    
    @Published var selectedImage: PhotosPickerItem? {
        didSet { Task { await loadImage(fromItem: selectedImage)}}
    }
    @Published var projetImage: Image?
    
    private var uiImage: UIImage?
    
    init(profile: ProjectProfile) {
        self.projectProfile = profile
    }
    
    func loadImage(fromItem item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        self.uiImage = uiImage
        self.projetImage = Image(uiImage: uiImage)
    }
}

@MainActor
class EditGroupProfileViewModel: ObservableObject {
    @Published var profile: GroupProfile
    @Published var selectedImage: PhotosPickerItem? {
        didSet { Task { await loadImage(fromItem: selectedImage)}}
    }
    @Published var groupImage: Image?
    private var uiImage: UIImage?
    
    init(profile: GroupProfile) {
        self.profile = profile
    }
    
    func loadImage(fromItem item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        self.uiImage = uiImage
        self.groupImage = Image(uiImage: uiImage)
    }
}


