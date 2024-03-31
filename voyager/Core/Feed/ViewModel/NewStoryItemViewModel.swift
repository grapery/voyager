//
//  NewThreadViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation
import PhotosUI
import SwiftUI

@MainActor
class NewStoryItemViewModel: ObservableObject {
    
    @Published var selectedImage: PhotosPickerItem? {
        didSet {
            Task {
                await loadImage(fromItem: selectedImage)
            }
        }
    }
    
    @Published var userImage: Image?
    @Published var content: String?
    
    private var uiImage: UIImage?
    
    func loadImage(fromItem item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        self.uiImage = uiImage
        self.userImage = Image(uiImage: uiImage)
    }
    
    func uploadLeaf(text: String) async {
//        guard let uiImage = uiImage else { return }
//        let data = uiImage.jpegData(compressionQuality: 0.9)!
//        let result = try await UploadLeaf(text: text, image: data)
//        print(result)
    }
}
