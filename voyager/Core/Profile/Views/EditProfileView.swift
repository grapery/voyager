//
//  EditProfileView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI
import PhotosUI

struct EditUserProfileView: View {
    @State private var selectedImage: PhotosPickerItem?
    @StateObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingImagePicker = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 头像部分
                    VStack(spacing: 16) {
                        PhotosPicker(selection: $viewModel.selectedImage) {
                            VStack(spacing: 8) {
                                if let image = viewModel.userImage {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.theme.border, lineWidth: 0.5)
                                        )
                                } else {
                                    CircularProfileImageView(avatarUrl: viewModel.user!.avatar, size: .InProfile)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.theme.border, lineWidth: 0.5)
                                        )
                                }
                                
                                Text("更换头像")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.theme.accent)
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    // 基本信息部分
                    VStack(spacing: 20) {
                        // 用户名输入框
                        ProfileInputField(
                            title: "用户名",
                            text: $viewModel.fullname,
                            placeholder: "请输入用户名"
                        )
                        
                        // 个人简介输入框
                        ProfileInputField(
                            title: "个人简介",
                            text: $viewModel.bio,
                            placeholder: "介绍一下自己吧",
                            isMultiline: true
                        )
                    }
                    .padding(.horizontal, 16)
                }
            }
            .background(Color.theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(Color.theme.tertiaryText)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("编辑资料")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.theme.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        saveProfile()
                    }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color.theme.accent)
                    .disabled(isLoading)
                }
            }
            .alert("错误", isPresented: $showingErrorAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                }
            }
        }
    }
    
    private func saveProfile() {
        isLoading = true
        
        Task {
            do {
                // 如果有新的头像图片，先上传到阿里云
                if let selectedImage = viewModel.selectedImage {
                    do {
                        // 从 PhotosPickerItem 获取 UIImage
                        guard let data = try await selectedImage.loadTransferable(type: Data.self),
                              let uiImage = UIImage(data: data) else {
                            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法加载图片"])
                        }
                        
                        // 上传图片到阿里云 OSS
                        let imageUrl = try await Task.detached {
                            try AliyunClient.UploadImage(image: uiImage)
                        }.value
                        let err = await viewModel.updateAvator(userId: viewModel.user!.userID, newAvatorUrl: imageUrl)
                        if err != nil {
                            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "上传图片失败"])
                        }
                        // 更新 viewModel 中的头像 URL
                        viewModel.user?.avatar = imageUrl
                    } catch {
                        await MainActor.run {
                            errorMessage = "上传图片失败"
                            showingErrorAlert = true
                            isLoading = false
                        }
                        return
                    }
                }
                
                // 更新用户资料
                try await viewModel.updateUserData()
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "保存失败：\(error.localizedDescription)"
                    showingErrorAlert = true
                    isLoading = false
                }
            }
        }
    }
}

// 输入框组件
private struct ProfileInputField: View {
    let title: String
    @Binding var text: String
    var placeholder: String
    var isMultiline: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(Color.theme.secondaryText)
            
            if isMultiline {
                TextEditor(text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(Color.theme.primaryText)
                    .frame(height: 100)
                    .padding(12)
                    .background(Color.theme.inputBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.theme.border, lineWidth: 0.5)
                    )
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(Color.theme.primaryText)
                    .padding(12)
                    .background(Color.theme.inputBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.theme.border, lineWidth: 0.5)
                    )
            }
        }
    }
}

