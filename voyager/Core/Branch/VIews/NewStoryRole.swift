//
//  NewStoryRole.swift
//  voyager
//
//  Created by grapestree on 2024/10/20.
//

import SwiftUI
import Kingfisher

// 创建角色视图
struct NewStoryRole: View {
    let storyId: Int64
    let userId: Int64
    @ObservedObject var viewModel: StoryDetailViewModel
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
            
            CreateRoleButton(
                isLoading: $isLoading,
                roleName: roleName,
                roleAvatar: roleAvatar,
                rolePrompt: rolePrompt,
                action: createRole
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
    }
    
    // 添加创建角色方法
    private func createRole() {
        guard !roleName.isEmpty else { return }
        isLoading = true
        
        Task {
            do {
                await viewModel.createStoryRole(
                    storyId: self.storyId,
                    name: self.roleName,
                    description: self.roleDescription,
                    avatar: self.roleAvatar,
                    characterPrompt: self.rolePrompt,
                    userId: self.userId,
                    characterRefImages: self.roleRefs
                )
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                print("Error creating role: \(error)")
                await MainActor.run {
                    isLoading = false
                    // 这里可以添加错误提示
                }
            }
        }
    }
    
    // 添加图片上传方法
    private func uploadImage(_ image: UIImage) async -> String? {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        do {
            let imageUrl = try await viewModel.uploadImage(image)
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
            Text("创建角色")
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

// 头像部分视图
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
                    KFImage(URL(string: roleAvatar))
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

// 基本信息部分视图
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

// 参考图片部分视图
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

// 创建按钮视图
private struct CreateRoleButton: View {
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
                Text("创建故事角色")
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
        roleName.isEmpty ||  isLoading
    }
}

// 添加一个简单的 Toast 视图
struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        if isShowing {
            VStack {
                Spacer()
                Text(message)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding(.bottom, 20)
            }
            .transition(.move(edge: .bottom))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
        }
    }
}

// 扩展 View 以添加加载指示器
extension View {
    func loadingOverlay(isLoading: Bool) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        )
                }
            }
        )
    }
}

// MARK: - 基本信息字段组件
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

// MARK: - 参考图片相关组件
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

// MARK: - 通用按钮组件
private struct AddImageButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.blue)
                .background(Color.white)
                .clipShape(Circle())
        }
    }
}

private struct AdvancedSettingsButton: View {
    @Binding var showAdvancedSettings: Bool
    
    var body: some View {
        Button(action: { showAdvancedSettings.toggle() }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("更多高级设置")
            }
            .foregroundColor(.blue)
        }
        .padding(.vertical)
    }
}

// MARK: - 图片选择器扩展
extension View {
    func imagePickerSheet(
        isPresented: Binding<Bool>,
        selectedImages: Binding<[UIImage]?>,
        roleAvatar: Binding<String>,
        roleRefs: Binding<[String]>,
        errorMessage: Binding<String>,
        showError: Binding<Bool>,
        uploadImage: @escaping (UIImage) async -> String?
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            MultiImagePicker(images: selectedImages)
        }
    }
    
    func errorAlert(errorMessage: String, isPresented: Binding<Bool>) -> some View {
        self.alert("错误", isPresented: isPresented) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}


