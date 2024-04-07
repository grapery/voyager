//
//  EditGroupProfileViewModel.swift
//  voyager
//
//  Created by grapestree on 2024/4/7.
//

import Foundation
import PhotosUI
import SwiftUI


class EditGroupProfileViewModel: ObservableObject {
    @Published var profile = GroupProfile(profile: Common_GroupProfileInfo())
    @Published var selectedImage: PhotosPickerItem? {
        didSet { Task { await loadImage(fromItem: selectedImage)}}
    }
    @Published var groupImage: Image?
    private var uiImage: UIImage?
    
    init() {
    }
    
    func loadImage(fromItem item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        self.uiImage = uiImage
        self.groupImage = Image(uiImage: uiImage)
    }
}

#Preview {
    EditGroupProfileViewModel() as! any View
}
