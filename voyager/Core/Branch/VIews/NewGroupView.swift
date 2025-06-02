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
import Kingfisher

struct NewGroupView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) private var dismiss
    public var viewModel: GroupViewModel
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isLoading = false
    
    @State private var groupName: String = ""
    @State private var groupDescription: String = ""
    @State private var privacy: String = "Public"
    @State private var showPrivacyPicker = false
    @State private var groupAvatar: UIImage?
    @State private var showAvatarPicker = false
    @State private var backgroundImage: UIImage?
    @State private var showBackgroundPicker = false
    
    let privacyOptions = ["Public", "Private"]
    
    init(userId: Int64, viewModel: GroupViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    // 顶部栏
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Color.theme.primaryText)
                        }
                        Spacer()
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 20)

                    // 标题
                    Text("Create Group")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color.theme.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 8)

                    // Group Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group Name")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.theme.primaryText)
                        TextField("Enter groupname", text: $groupName)
                            .padding()
                            .background(Color.theme.inputBackground)
                            .foregroundColor(Color.theme.inputText)
                            .cornerRadius(12)
                            .font(.system(size: 15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.theme.border, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)

                    // Group Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group Description")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.theme.primaryText)
                        TextEditor(text: $groupDescription)
                            .frame(height: 80)
                            .padding(8)
                            .background(Color.theme.inputBackground)
                            .foregroundColor(Color.theme.inputText)
                            .cornerRadius(12)
                            .font(.system(size: 15))
                    }
                    .padding(.horizontal, 20)

                    // Privacy
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacy")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.theme.primaryText)
                        Menu {
                            ForEach(privacyOptions, id: \.self) { option in
                                Button(option) {
                                    privacy = option
                                }
                                .padding(8)
                                .background(Color.theme.inputBackground)
                            }
                        } label: {
                            HStack {
                                Text(privacy)
                                    .foregroundColor(Color.theme.inputText)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color.theme.tertiaryText)
                            }
                            .padding()
                            .background(Color.theme.inputBackground)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Group Avatar
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group Avatar")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.theme.primaryText)
                        Button(action: {
                            showAvatarPicker = true
                        }) {
                            if let avatar = groupAvatar {
                                Image(uiImage: avatar)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 180, height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 24))
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(Color.theme.inputBackground)
                                        .frame(width: 180, height: 180)
                                    Image(systemName: "person.crop.square")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        .foregroundColor(Color.theme.tertiaryText)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)

                    // Background Image
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Background Image")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.theme.primaryText)
                        Button(action: { showBackgroundPicker = true }) {
                            if let bg = backgroundImage {
                                Image(uiImage: bg)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                            } else {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.theme.inputBackground)
                                    .frame(height: 120)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 40))
                                            .foregroundColor(Color.theme.tertiaryText)
                                    )
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)

                    HStack{
                        Spacer()
                        // Create Group Button
                        Button(action: {
                            // 创建小组逻辑
                            self.createGroup()
                        }) {
                            Text("Create")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color.theme.buttonText)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.theme.buttonBackground)
                                .cornerRadius(26)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                        Spacer()
                        // Create Group Button
                        Button(action: {
                            // 取消创建小组逻辑
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Cancel")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color.theme.buttonText)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.theme.buttonBackground)
                                .cornerRadius(26)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                        Spacer()
                    }
                }
                .padding(.top, 8)
            }
            .sheet(isPresented: $showAvatarPicker) {
                // 头像选择器
                SingleImagePicker(image: $groupAvatar)
            }
            .sheet(isPresented: $showBackgroundPicker) {
                // 背景图片选择器
                SingleImagePicker(image: $backgroundImage)
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
                            .tint(Color.theme.primaryText)
                    }
            }
        }
    }
    
    private func createGroup() {
        guard !groupName.isEmpty else {
            showAlert(message: "请输入小组名称")
            return
        }
        isLoading = true
        Task {
            var avatarImage: UIImage? = groupAvatar
            // 如果没有上传头像，自动生成一张随机圆图片
            if avatarImage == nil {
                avatarImage = RandomCirclesAvatar().snapshot()
            }
            do {
                let imageUrl = try await Task.detached {
                    try AliyunClient.UploadImage(image: avatarImage!)
                }.value
                let (result, err) = await viewModel.createGroup(
                    creatorId: viewModel.user.userID,
                    name: groupName,
                    description: groupDescription,
                    avatar: imageUrl
                )
                await MainActor.run {
                    isLoading = false
                    if err == nil {
                        presentationMode.wrappedValue.dismiss()
                        print("create group success \(result?.info.name ?? groupName)")
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

// 随机圆背景
struct RandomCirclesBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let count = 18
            ZStack {
                ForEach(0..<count, id: \ .self) { i in
                    let radius = CGFloat.random(in: w*0.08...w*0.18)
                    let x = CGFloat.random(in: 0...(w-radius*2))
                    let y = CGFloat.random(in: 0...(h-radius*2))
                    Circle()
                        .fill(RandomCirclesAvatar.randomColor(index: i))
                        .frame(width: radius*2, height: radius*2)
                        .position(x: x + radius, y: y + radius)
                }
            }
        }
    }
}

// 随机圆头像
struct RandomCirclesAvatar: View {
    static func randomColor(index: Int) -> Color {
        let colors: [Color] = [
            .yellow, .orange, .blue, .green, .purple, .pink, .red, .mint, .teal, .indigo
        ]
        return colors[index % colors.count].opacity(0.32)
    }
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let count = 6
            ZStack {
                ForEach(0..<count, id: \ .self) { i in
                    let radius = CGFloat.random(in: w*0.18...w*0.38)
                    let x = CGFloat.random(in: 0...(w-radius*2))
                    let y = CGFloat.random(in: 0...(h-radius*2))
                    Circle()
                        .fill(Self.randomColor(index: i))
                        .frame(width: radius*2, height: radius*2)
                        .position(x: x + radius, y: y + radius)
                }
            }
        }
    }
}

// UIImage 快照扩展
import UIKit
extension View {
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
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


