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
    
    @State private var leafText = ""
    @State public  var projectId: Int64
    @State public var timelineId: Int64
    @State public var user: User
    @State private var imagePickerPresented = false
    @StateObject var viewModel = NewStoryItemViewModel(user: user,projectId: projectId,timelineId: timelineId)
    
    
    
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
                Text("新的分叉点")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 32)
                
                Spacer()
                
                Button("发布") {
                    Task {
                        await viewModel.uploadLeaf(text: leafText)
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
