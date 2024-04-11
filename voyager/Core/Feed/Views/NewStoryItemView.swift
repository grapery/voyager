//
//  NewThreadView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI
import PhotosUI

struct NewStoryItemView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State public var leafText = ""
    @State public  var projectId: Int64
    @State public var timelineId: Int64
    @State public var user: User
    @State private var imagePickerPresented = false
    @State var viewModel :NewStoryItemViewModel
    
    @MainActor
    init(projectId: Int64, timelineId: Int64, user: User) {
        self.leafText = ""
        self.projectId = projectId
        self.timelineId = timelineId
        self.user = user
        self.imagePickerPresented = false
        self.viewModel = NewStoryItemViewModel(user: user,projectId: projectId,timelineId: timelineId)
    }
    
    
    var body: some View {
        VStack {
            HStack {
                Button("取消") {
                    action:do{
                        leafText = ""
                        viewModel.userImage = nil
                        viewModel.selectedImage = nil
                        dismiss()
                    }
                }
                Spacer()
                Button("分叉") {
                    Task {
                        await viewModel.uploadItem()
                        clearLeafDataAndReturn()
                    }
                }
                Spacer()
                
                Button("发布") {
                    Task {
                        await viewModel.uploadItem()
                        clearLeafDataAndReturn()
                    }
                }
            }
            .padding()
            
            HStack {
                VStack {
                    CircularProfileImageView(avatarUrl: user.avatar, size: .leaf)
                    Rectangle()
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .foregroundColor(.secondary)
                    
                
                    CircularProfileImageView(avatarUrl: user.avatar, size: .leaf)
                            .opacity(0.5)
                }
                .padding(8)
                
                VStack(alignment: .leading) {
                    Text(user.name)
                        .font(.headline)
                        .padding(.top, 24)
                    
                    
                    TextField("创建一个新的时间线", text: $leafText, axis: .vertical)
                        .lineLimit(25)
                        .autocorrectionDisabled()
                    
                    Button {
                        imagePickerPresented.toggle()
                    } label: {
                        Image(systemName: "paperclip")
                    }
                    .foregroundColor(.primary)
                    .imageScale(.large)
                    
                    VStack(spacing: 12) {
                        
                        if let image = viewModel.userImage {
                            image.resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                    }
                    }
                    Spacer()
                }
            }
        }
        .photosPicker(isPresented: $imagePickerPresented, selection: $viewModel.selectedImage)
    }
    
    func clearLeafDataAndReturn() {
        leafText = ""
        dismiss()
    }
}
