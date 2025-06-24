//
//  EditProfileView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI
import PhotosUI

// 编辑资料页面枚举
enum EditProfileSection: Int, CaseIterable {
    case basic = 0
    case industry = 1
    case education = 2
    
    var title: String {
        switch self {
        case .basic: return "基本资料"
        case .industry: return "行业经历"
        case .education: return "教育经历"
        }
    }
}

struct EditUserProfileView: View {
    @State private var selectedImage: PhotosPickerItem?
    @StateObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingImagePicker = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var selectedSection: EditProfileSection = .basic
    
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 分段控制器
                Picker("编辑资料", selection: $selectedSection) {
                    ForEach(EditProfileSection.allCases, id: \.rawValue) { section in
                        Text(section.title).tag(section)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(Color.theme.secondaryBackground)
                
                // 内容区域
                TabView(selection: $selectedSection) {
                    BasicInfoSection(viewModel: viewModel)
                        .tag(EditProfileSection.basic)
                    
                    IndustryExperienceSection(viewModel: viewModel)
                        .tag(EditProfileSection.industry)
                    
                    EducationExperienceSection(viewModel: viewModel)
                        .tag(EditProfileSection.education)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: selectedSection)
            }
            .background(Color.theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .regular))
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
                    Color.theme.overlay
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(Color.theme.loadingIndicator)
                            .scaleEffect(1.2)
                        Text("保存中...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.theme.primaryText)
                    }
                    .padding(24)
                    .background(Color.theme.modalBackground)
                    .cornerRadius(16)
                    .shadow(color: Color.theme.shadow, radius: 20, x: 0, y: 10)
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
                            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "上传头像失败"])
                        }
                        // 更新 viewModel 中的头像 URL
                        viewModel.user?.avatar = imageUrl
                    } catch {
                        await MainActor.run {
                            errorMessage = "上传头像失败"
                            showingErrorAlert = true
                            isLoading = false
                        }
                        return
                    }
                }
                
                // 如果有新的背景图片，先上传到阿里云
                if let backgroundSelectedImage = viewModel.backgroundSelectedImage {
                    do {
                        // 从 PhotosPickerItem 获取 UIImage
                        guard let data = try await backgroundSelectedImage.loadTransferable(type: Data.self),
                              let uiImage = UIImage(data: data) else {
                            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法加载背景图片"])
                        }
                        
                        // 上传图片到阿里云 OSS
                        let imageUrl = try await Task.detached {
                            try AliyunClient.UploadImage(image: uiImage)
                        }.value
                        let err = await viewModel.updateUserbackgroud(userId: viewModel.user!.userID, backgroundImageUrl: imageUrl)
                        if err != nil {
                            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "上传背景图片失败"])
                        }
                        // 更新 viewModel 中的背景图片 URL
                        viewModel.profile.backgroundImage = imageUrl
                    } catch {
                        await MainActor.run {
                            errorMessage = "上传背景图片失败"
                            showingErrorAlert = true
                            isLoading = false
                        }
                        return
                    }
                }
                
                // 更新用户资料
                await viewModel.updateProfile()
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

// MARK: - 基本资料部分
struct BasicInfoSection: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // 头像和背景图片部分
                VStack(spacing: 24) {
                    // 背景图片
                    VStack(spacing: 16) {
                        PhotosPicker(selection: $viewModel.backgroundSelectedImage) {
                            ZStack {
                                if let backgroundImage = viewModel.backgroundImage {
                                    Image(uiImage: backgroundImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 140)
                                        .clipped()
                                        .cornerRadius(16)
                                } else {
                                    Rectangle()
                                        .fill(Color.theme.inputBackground)
                                        .frame(height: 140)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.theme.cardBorder, lineWidth: 1)
                                        )
                                }
                                
                                VStack(spacing: 6) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("更换背景")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .padding(12)
                                .background(Color.theme.overlay)
                                .cornerRadius(10)
                            }
                        }
                        .scaleEffect(viewModel.backgroundSelectedImage != nil ? 0.98 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.backgroundSelectedImage != nil)
                    }
                    
                    // 头像
                    VStack(spacing: 12) {
                        PhotosPicker(selection: $viewModel.selectedImage) {
                            VStack(spacing: 10) {
                                if let image = viewModel.userImage {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 90, height: 90)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.theme.cardBorder, lineWidth: 2)
                                        )
                                        .shadow(color: Color.theme.shadow, radius: 8, x: 0, y: 4)
                                } else {
                                    CircularProfileImageView(avatarUrl: viewModel.user?.avatar ?? "", size: .InProfile2)
                                        .frame(width: 90, height: 90)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.theme.cardBorder, lineWidth: 2)
                                        )
                                        .shadow(color: Color.theme.shadow, radius: 8, x: 0, y: 4)
                                }
                                
                                Text("更换头像")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.theme.accent)
                            }
                        }
                        .scaleEffect(viewModel.selectedImage != nil ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedImage != nil)
                    }
                }
                .padding(.top, 24)
                
                // 基本信息输入框
                VStack(spacing: 24) {
                    ProfileInputField(
                        title: "姓名",
                        text: $viewModel.fullname,
                        placeholder: "请输入姓名",
                        icon: "person.fill"
                    )
                    
                    ProfileInputField(
                        title: "地址",
                        text: $viewModel.address,
                        placeholder: "请输入地址",
                        icon: "location.fill"
                    )
                    
                    ProfileInputField(
                        title: "个人简介",
                        text: $viewModel.bio,
                        placeholder: "介绍一下自己吧",
                        isMultiline: true,
                        icon: "text.quote"
                    )
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 32)
        }
        .background(Color.theme.background)
    }
}

// MARK: - 行业经历部分
struct IndustryExperienceSection: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 显示控制开关
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("行业经历")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color.theme.primaryText)
                        Text("展示您的职业发展历程")
                            .font(.system(size: 14))
                            .foregroundColor(Color.theme.tertiaryText)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $viewModel.showIndustryExperience)
                        .toggleStyle(SwitchToggleStyle(tint: Color.theme.accent))
                        .scaleEffect(0.9)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 8)
                
                if viewModel.showIndustryExperience {
                    VStack(spacing: 20) {
                        ForEach(Array(viewModel.industryExperiences.enumerated()), id: \.element.id) { index, experience in
                            IndustryExperienceCard(
                                experience: Binding(
                                    get: { viewModel.industryExperiences[index] },
                                    set: { viewModel.industryExperiences[index] = $0 }
                                ),
                                onDelete: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        viewModel.removeIndustryExperience(at: index)
                                    }
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        }
                        
                        // 添加按钮
                        if viewModel.industryExperiences.count < 10 {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.addIndustryExperience()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                    Text("添加行业经历")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(Color.theme.accent)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .frame(maxWidth: .infinity)
                                .background(Color.theme.inputBackground)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.theme.accent.opacity(0.3), lineWidth: 1.5)
                                )
                            }
                            .scaleEffect(viewModel.industryExperiences.count == 9 ? 0.95 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.industryExperiences.count)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 32)
        }
        .background(Color.theme.background)
    }
}

// MARK: - 教育经历部分
struct EducationExperienceSection: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 显示控制开关
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("教育经历")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color.theme.primaryText)
                        Text("展示您的学习成长历程")
                            .font(.system(size: 14))
                            .foregroundColor(Color.theme.tertiaryText)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $viewModel.showEducationExperience)
                        .toggleStyle(SwitchToggleStyle(tint: Color.theme.accent))
                        .scaleEffect(0.9)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 8)
                
                if viewModel.showEducationExperience {
                    VStack(spacing: 20) {
                        ForEach(Array(viewModel.educationExperiences.enumerated()), id: \.element.id) { index, experience in
                            EducationExperienceCard(
                                experience: Binding(
                                    get: { viewModel.educationExperiences[index] },
                                    set: { viewModel.educationExperiences[index] = $0 }
                                ),
                                onDelete: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        viewModel.removeEducationExperience(at: index)
                                    }
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        }
                        
                        // 添加按钮
                        if viewModel.educationExperiences.count < 10 {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.addEducationExperience()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                    Text("添加教育经历")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(Color.theme.accent)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .frame(maxWidth: .infinity)
                                .background(Color.theme.inputBackground)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.theme.accent.opacity(0.3), lineWidth: 1.5)
                                )
                            }
                            .scaleEffect(viewModel.educationExperiences.count == 9 ? 0.95 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.educationExperiences.count)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 32)
        }
        .background(Color.theme.background)
    }
}

// MARK: - 行业经历卡片
struct IndustryExperienceCard: View {
    @Binding var experience: IndustryExperience
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.theme.accent)
                    Text("行业经历")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.theme.primaryText)
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(Color.theme.error)
                        .padding(8)
                        .background(Color.theme.error.opacity(0.1))
                        .clipShape(Circle())
                }
                .scaleEffect(0.9)
            }
            
            VStack(spacing: 16) {
                ProfileInputField(
                    title: "公司名称",
                    text: $experience.company,
                    placeholder: "请输入公司名称",
                    icon: "building.2.fill"
                )
                
                ProfileInputField(
                    title: "职位",
                    text: $experience.position,
                    placeholder: "请输入职位",
                    icon: "person.badge.plus.fill"
                )
                
                ProfileInputField(
                    title: "工作时间",
                    text: $experience.duration,
                    placeholder: "例如：2020-2023",
                    icon: "calendar.fill"
                )
                
                ProfileInputField(
                    title: "工作描述",
                    text: $experience.description,
                    placeholder: "请描述您的工作内容",
                    isMultiline: true,
                    icon: "text.alignleft"
                )
            }
        }
        .padding(20)
        .background(Color.theme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.theme.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.theme.shadow, radius: 8, x: 0, y: 4)
    }
}

// MARK: - 教育经历卡片
struct EducationExperienceCard: View {
    @Binding var experience: EducationExperience
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.theme.accent)
                    Text("教育经历")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.theme.primaryText)
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(Color.theme.error)
                        .padding(8)
                        .background(Color.theme.error.opacity(0.1))
                        .clipShape(Circle())
                }
                .scaleEffect(0.9)
            }
            
            VStack(spacing: 16) {
                ProfileInputField(
                    title: "学校名称",
                    text: $experience.school,
                    placeholder: "请输入学校名称",
                    icon: "building.columns.fill"
                )
                
                ProfileInputField(
                    title: "专业",
                    text: $experience.major,
                    placeholder: "请输入专业",
                    icon: "book.fill"
                )
                
                ProfileInputField(
                    title: "学位",
                    text: $experience.degree,
                    placeholder: "例如：学士、硕士、博士",
                    icon: "award.fill"
                )
                
                ProfileInputField(
                    title: "学习时间",
                    text: $experience.duration,
                    placeholder: "例如：2016-2020",
                    icon: "calendar.fill"
                )
                
                ProfileInputField(
                    title: "学习描述",
                    text: $experience.description,
                    placeholder: "请描述您的学习经历",
                    isMultiline: true,
                    icon: "text.alignleft"
                )
            }
        }
        .padding(20)
        .background(Color.theme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.theme.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.theme.shadow, radius: 8, x: 0, y: 4)
    }
}

// MARK: - 输入框组件
private struct ProfileInputField: View {
    let title: String
    @Binding var text: String
    var placeholder: String
    var isMultiline: Bool = false
    var icon: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(Color.theme.accent)
                }
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.theme.secondaryText)
            }
            
            if isMultiline {
                TextEditor(text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(Color.theme.primaryText)
                    .frame(minHeight: 100)
                    .padding(16)
                    .background(Color.theme.inputBackground)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.theme.inputBorder, lineWidth: 1)
                    )
                    .onTapGesture {
                        // 聚焦时的边框颜色变化
                    }
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(Color.theme.primaryText)
                    .padding(16)
                    .background(Color.theme.inputBackground)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.theme.inputBorder, lineWidth: 1)
                    )
                    .onTapGesture {
                        // 聚焦时的边框颜色变化
                    }
            }
        }
    }
}

