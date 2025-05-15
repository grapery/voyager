//
//  NewGroupView.swift
//  voyager
//
//  Created by grapestree on 2024/4/11.
//

import SwiftUI
import UIKit
import PhotosUI
import ActivityIndicatorView

struct NewGroupView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) private var dismiss
    public var viewModel: GroupViewModel
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isLoading = false
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var avatar: UIImage?
    @State private var showImagePicker: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    init(userId: Int64, viewModel: GroupViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // 头像选择区域
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        if let avatar = avatar {
                            Image(uiImage: avatar)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.theme.border, lineWidth: 1))
                        } else {
                            Image(systemName: "infinity.circle")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .foregroundColor(Color.theme.accent)
                        }
                    }
                    .padding(.top, 32)
                    
                    // 输入区域
                    VStack(spacing: 16) {
                        TextField("小组名称", text: $name)
                            .textFieldStyle(CustomTextFieldStyle())
                        
                        TextField("小组描述", text: $description)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // 按钮区域
                    VStack(spacing: 16) {
                        Button(action: createGroup) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("创建小组")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .disabled(isLoading)
                        
                        Button(action: { dismiss() }) {
                            Text("取消")
                                .font(.headline)
                                .foregroundColor(Color.theme.secondaryText)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.theme.secondaryBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.theme.border, lineWidth: 1)
                                )
                        }
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            self.avatar = image
                        }
                    }
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("错误"),
                message: Text(alertMessage),
                dismissButton: .default(Text("确定"))
            )
        }
        .overlay {
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .tint(.white)
                    }
            }
        }
    }
    
    private func createGroup() {
        guard !name.isEmpty else {
            showAlert(message: "请输入小组名称")
            return
        }
        
        guard let avatar = avatar else {
            showAlert(message: "请选择小组头像")
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let imageUrl = try await Task.detached {
                    try AliyunClient.UploadImage(image: avatar)
                }.value
                
                let (result, err) = await viewModel.createGroup(
                    creatorId: viewModel.user.userID,
                    name: name,
                    description: description,
                    avatar: imageUrl
                )
                
                await MainActor.run {
                    isLoading = false
                    if err == nil {
                        presentationMode.wrappedValue.dismiss()
                        print("create group success \(result?.info.name ?? name)")
                    } else {
                        showAlert(message: err!.localizedDescription)
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showAlert(message: "上传图片失败：\(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

// 自定义输入框样式
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textInputAutocapitalization(.none)
            .font(.system(size: 16))
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.theme.tertiaryBackground)
            .cornerRadius(12)
    }
}
