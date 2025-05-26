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
                RandomCirclesBackground()
                    .ignoresSafeArea()
                VStack(spacing: 24) {
                    Spacer(minLength: 42)
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
                            ZStack {
                                RandomCirclesAvatar()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                Image(systemName: "infinity.circle")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(Color.theme.accent)
                            }
                        }
                    }
                    // 输入区域
                    VStack(spacing: 8) {
                        HStack(alignment: .center, spacing: 8) {
                            Text("小组名称")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                                .frame(width: 72, alignment: .leading)
                            TextField("请输入小组名称", text: $name)
                                .foregroundColor(.white)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        HStack(alignment: .center, spacing: 8) {
                            Text("小组描述")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                                .frame(width: 72, alignment: .leading)
                            TextField("请输入小组描述", text: $description)
                                .foregroundColor(.white)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    Spacer()
                    // 按钮区域
                    HStack(spacing: 16) {
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
        isLoading = true
        Task {
            var avatarImage: UIImage? = avatar
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
