//
//  EditProjectProfileViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/4/7.
//

import Foundation
import PhotosUI
import SwiftUI

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
#Preview {
    EditProjectProfileViewModel(profile: ProjectProfile()) as! any View
}
