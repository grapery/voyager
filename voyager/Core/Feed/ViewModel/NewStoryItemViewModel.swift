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
    @Published var description: String
    @Published var prompt: String
    
    @Published var userImage: Image?
    private var uiImage: UIImage?
    @Published var user: User
    @Published var projectId: Int64
    @Published var timelineId: Int64
    @Published var selectedImage: PhotosPickerItem? {
        didSet {
            Task {
                await loadImage(fromItem: selectedImage)
            }
        }
    }
    
    init(user: User, projectId: Int64, timelineId: Int64) {
        self.description = ""
        self.prompt = ""
        self.uiImage = UIImage()
        self.userImage = Image(uiImage: self.uiImage!)
        self.user = user
        self.projectId = projectId
        self.timelineId = timelineId
        self.selectedImage = PhotosPickerItem(itemIdentifier: "default")
    }
    
    
    func loadImage(fromItem item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        self.uiImage = uiImage
        self.userImage = Image(uiImage: uiImage)
    }
    
    func uploadItem() async {
        
        return
    }
}
