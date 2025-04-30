//
//  UpdateStoryRole.swift
//  voyager
//
//  Created by grapestree on 2024/10/21.
//

import SwiftUI
import Kingfisher

// 编辑角色视图
struct EditStoryRoleDetailView: View {
    let role: StoryRole?
    let userId: Int64
    @Binding var viewModel: StoryRoleModel?
    @Environment(\.dismiss) private var dismiss
    
    @State private var roleName: String = ""
    @State private var roleDescription: String = ""
    @State private var roleAvatar: String = ""
    @State private var rolePrompt: String = ""
    @State private var roleRefs: [String] = [String]()
    @State private var selectedVoice: String = "默认"
    @State private var selectedLanguage: String = "中文"
    @State private var isPublic: Bool = true
    @State private var showAdvancedSettings: Bool = false
    @State private var isLoading = false
    @State private var showImagePicker = false
    @State private var selectedImages: [UIImage]? = []
    @State private var errorMessage: String = ""
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationBarView(dismiss: dismiss)
            
            ScrollView {
                VStack(spacing: 24) {
                    AvatarSectionView(
                        roleAvatar: $roleAvatar,
                        showImagePicker: $showImagePicker
                    )
                    
                    BasicInfoSectionView(
                        roleName: $roleName,
                        roleDescription: $roleDescription,
                        rolePrompt: $rolePrompt
                    )
                    
                    ReferenceImagesSectionView(
                        roleRefs: $roleRefs,
                        showImagePicker: $showImagePicker
                    )
                    
                    AdvancedSettingsButton(showAdvancedSettings: $showAdvancedSettings)
                }
            }
            
            UpdateRoleButton(
                isLoading: $isLoading,
                roleName: roleName,
                roleAvatar: roleAvatar,
                rolePrompt: rolePrompt,
                action: updateRole
            )
        }
        .background(Color(.systemGroupedBackground))
        .imagePickerSheet(
            isPresented: $showImagePicker,
            selectedImages: $selectedImages,
            roleAvatar: $roleAvatar,
            roleRefs: $roleRefs,
            errorMessage: $errorMessage,
            showError: $showError,
            uploadImage: uploadImage
        )
        .errorAlert(errorMessage: errorMessage, isPresented: $showError)
        .overlay(ToastView(message: errorMessage, isShowing: $showError))
        .onAppear {
            if let role = role {
                roleName = role.role.characterName
                roleDescription = role.role.characterDescription
                roleAvatar = role.role.characterAvatar
                rolePrompt = role.role.characterPrompt
                roleRefs = role.role.characterRefImages
            }
        }
    }
    
    // 更新角色方法
    private func updateRole() {
        guard !roleName.isEmpty else { return }
        isLoading = true
        
        Task {
            var updatedRole = Common_StoryRole()
            updatedRole.characterName = roleName
            updatedRole.characterDescription = roleDescription
            updatedRole.characterAvatar = roleAvatar
            updatedRole.characterPrompt = rolePrompt
            updatedRole.characterRefImages = roleRefs
            updatedRole.creatorID = userId
            
            if let err = await viewModel?.updateStoryRole(role: updatedRole) {
                await MainActor.run {
                    errorMessage = "更新失败: \(err.localizedDescription)"
                    showError = true
                }
            }
            
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        }
    }
    
    // 图片上传方法
    private func uploadImage(_ image: UIImage) async -> String? {
        await MainActor.run { isLoading = true }
        defer {
            Task { @MainActor in isLoading = false }
        }
        
        do {
            let imageUrl = try AliyunClient.UploadImage(image: image)
            return imageUrl
        } catch {
            await MainActor.run {
                errorMessage = "图片上传失败: \(error.localizedDescription)"
                showError = true
            }
            return nil
        }
    }
}

// 导航栏视图
private struct NavigationBarView: View {
    let dismiss: DismissAction
    
    var body: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .foregroundColor(.primary)
            }
            
            Spacer()
            Text("编辑角色")
                .font(.headline)
            
            Spacer()
            Button(action: { /* 一键完善操作 */ }) {
                Text("一键完善")
                    .foregroundColor(.pink)
            }
        }
        .padding()
    }
}

// 更新按钮视图
private struct UpdateRoleButton: View {
    @Binding var isLoading: Bool
    let roleName: String
    let roleAvatar: String
    let rolePrompt: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text("更新角色")
            }
        }
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(isDisabled ? Color.gray : Color.blue)
        .cornerRadius(10)
        .disabled(isDisabled)
        .padding()
    }
    
    private var isDisabled: Bool {
        roleName.isEmpty || isLoading
    }
}

// 复用 NewStoryRole 中的其他视图组件
private struct AvatarSectionView: View {
    @Binding var roleAvatar: String
    @Binding var showImagePicker: Bool
    
    var body: some View {
        VStack {
            ZStack {
                if roleAvatar.isEmpty {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Text("😊")
                        .font(.system(size: 40))
                } else {
                    KFImage(URL(string: convertImagetoSenceImage(url: roleAvatar, scene: .small)))
                        .cacheMemoryOnly()
                        .fade(duration: 0.25)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                }
                
                AddImageButton(action: { showImagePicker = true })
                    .offset(x: 35, y: 35)
            }
            
            Text("AI 生成形象")
                .foregroundColor(.gray)
                .padding(.top, 8)
        }
        .padding(.vertical)
    }
}

private struct BasicInfoSectionView: View {
    @Binding var roleName: String
    @Binding var roleDescription: String
    @Binding var rolePrompt: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            NameField(roleName: $roleName)
            DescriptionField(roleDescription: $roleDescription)
            PromptField(rolePrompt: $rolePrompt)
        }
        .padding(.horizontal)
    }
}

private struct ReferenceImagesSectionView: View {
    @Binding var roleRefs: [String]
    @Binding var showImagePicker: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("参考图像")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    AddReferenceImageButton(action: { showImagePicker = true })
                    ReferenceImagesList(roleRefs: $roleRefs)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(.horizontal)
    }
}

private struct AddImageButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.black)
        }
    }
}

private struct AddReferenceImageButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                    .frame(width: 80, height: 80)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                Text("添加图片")
                    .font(.caption)
            }
        }
    }
}

private struct ReferenceImagesList: View {
    @Binding var roleRefs: [String]
    
    var body: some View {
        ForEach(roleRefs, id: \.self) { imageUrl in
            ReferenceImageItem(imageUrl: imageUrl) {
                if let index = roleRefs.firstIndex(of: imageUrl) {
                    roleRefs.remove(at: index)
                }
            }
        }
    }
}

private struct ReferenceImageItem: View {
    let imageUrl: String
    let onDelete: () -> Void
    
    var body: some View {
        VStack {
            KFImage(URL(string: imageUrl))
                .cacheMemoryOnly()
                .fade(duration: 0.25)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .cornerRadius(8)
                .overlay(
                    DeleteImageButton(action: onDelete)
                        .offset(x: 35, y: -35),
                    alignment: .topTrailing
                )
        }
    }
}

private struct DeleteImageButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "minus.circle.fill")
                .foregroundColor(.red)
                .background(Color.white)
                .clipShape(Circle())
        }
    }
}

private struct NameField: View {
    @Binding var roleName: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("名称")
                .font(.headline)
            TextField("输入名称", text: $roleName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

private struct DescriptionField: View {
    @Binding var roleDescription: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("设定描述")
                .font(.headline)
            TextEditor(text: $roleDescription)
                .frame(height: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    Group {
                        if roleDescription.isEmpty {
                            Text("示例：你是一位经验丰富的英语老师，拥有激发学生学习热情的教学方法。你善于运用幽默和实际应用案例，使对话充满趣味。")
                                .foregroundColor(.gray)
                                .padding(12)
                        }
                    }
                )
        }
    }
}

private struct PromptField: View {
    @Binding var rolePrompt: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("角色提示词")
                .font(.headline)
            TextEditor(text: $rolePrompt)
                .frame(height: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    Group {
                        if rolePrompt.isEmpty {
                            Text("输入角色的详细设定和行为提示，这将指导AI扮演该角色...")
                                .foregroundColor(.gray)
                                .padding(12)
                        }
                    }
                )
        }
    }
}

private struct AdvancedSettingsButton: View {
    @Binding var showAdvancedSettings: Bool
    
    var body: some View {
        Button(action: { showAdvancedSettings.toggle() }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                Text("更多高级设置")
            }
            .foregroundColor(.blue)
        }
        .padding(.vertical)
    }
}
