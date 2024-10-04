//
//  GroupProfileViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/10/2.
//

import Foundation
import PhotosUI
import SwiftUI

class ProjectProfileViewModel: ObservableObject {
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

class GroupProfileViewModel: ObservableObject {
    @Published var groupId: Int64
    @Published var userId: Int64
    @Published var profile = GroupProfile(profile: Common_GroupProfileInfo())
    @Published var selectedImage: PhotosPickerItem? {
        didSet { Task { await loadImage(fromItem: selectedImage)}}
    }
    
    @Published var groupImage: Image?
    private var uiImage: UIImage?
    
    init(groupId: Int64, userId: Int64) {
        self.groupId = groupId
        self.userId = userId
        var err:Error?
        var profile: Common_GroupProfileInfo
        (profile,err) = APIClient.shared.GetGroupProfile(groupId: groupId, userId: userId)
        if err == nil{
            self.profile = GroupProfile(profile: profile)
        }
    }
    
    func loadImage(fromItem item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        self.uiImage = uiImage
        self.groupImage = Image(uiImage: uiImage)
    }
    
    func fetchGroupProfile(){
        
    }
}

