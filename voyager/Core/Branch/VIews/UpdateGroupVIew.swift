//
//  UpdateGroupVIew.swift
//  voyager
//
//  Created by grapestree on 2024/4/11.
//

import SwiftUI

struct UpdateGroupView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var groupName: String
    @State private var groupDescription: String
    @State private var groupLocation: String
    @State private var groupStatus: Int32
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var avatarImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var groupStatusStr: String = ""
    @State private var isUpdating = false
    @State private var groupPrivacy: Bool = false
    @State private var groupTags: String = ""
    
    let group: BranchGroup
    let userId: Int64
    @State private var avatar: String = ""
    
    init(group: BranchGroup,userId:Int64) {
        self.group = group
        self.userId = userId
        _groupName = State(initialValue: group.info.name)
        _groupDescription = State(initialValue: group.info.desc)
        _groupLocation = State(initialValue: group.info.location)
        _groupStatus = State(initialValue: group.info.status)
        _groupStatusStr = State(initialValue: String(group.info.status))
        _avatarImage = State(initialValue: UIImage(systemName: "infinity.circle"))
        _groupPrivacy = State(initialValue: group.info.status == 1)
        //_groupTags = State(initialValue: group.info.tags ?? "")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    // 小组头像部分
                    Section(header: Text("小组头像").foregroundColor(.gray)) {
                        Button(action: { isImagePickerPresented = true }) {
                            HStack(spacing: 12) {
                                if let avatarImage = avatarImage {
                                    Image(uiImage: avatarImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 80, height: 80)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("点击更换头像")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.blue)
                                    Text("建议使用清晰的图片")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    // 基本信息部分
                    Section(header: Text("基本信息").foregroundColor(.gray)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("小组名称")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            TextField("请输入小组名称", text: $groupName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 15))
                        }
                        .padding(.vertical, 4)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("小组简介")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            TextEditor(text: $groupDescription)
                                .frame(height: 100)
                                .font(.system(size: 15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .overlay(
                                    Group {
                                        if groupDescription.isEmpty {
                                            Text("请输入小组简介...")
                                                .foregroundColor(.gray.opacity(0.8))
                                                .padding(.leading, 4)
                                                .padding(.top, 8)
                                        }
                                    },
                                    alignment: .topLeading
                                )
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // 详细设置部分
                    Section(header: Text("详细设置").foregroundColor(.gray)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("地址")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            TextField("请输入地址（可以虚拟、可以真实）", text: $groupLocation)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 15))
                        }
                        .padding(.vertical, 4)
                        
                        Toggle(isOn: $groupPrivacy) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("小组隐私")
                                    .font(.system(size: 15))
                                Text("开启后只有成员可见")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                        }
                        .onChange(of: groupPrivacy) { newValue in
                            groupStatusStr = newValue ? "1" : "0"
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("小组标签")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            TextField("请输入标签，用逗号分隔", text: $groupTags)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 15))
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // 底部按钮
                HStack(spacing: 20) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("取消")
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.gray)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        isUpdating = true
                        updateGroup()
                    }) {
                        Group {
                            if isUpdating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("更新")
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isUpdating)
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                .background(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
            }
            .navigationTitle("更新小组信息")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertMessage.contains("失败") ? "错误" : "提示"),
                message: Text(alertMessage),
                dismissButton: .default(Text("确定"))
            )
        }
        .sheet(isPresented: $isImagePickerPresented) {
            SingleImagePicker(image: $avatarImage)
        }
    }
    
    private func updateGroup() {
        guard !groupName.isEmpty else {
            alertMessage = "Group name cannot be empty"
            showAlert = true
            return
        }
        // Upload avatar image if selected
        Task{
            //self.avatar = try await APIClient.shared.uploadImage(image: self.avatarImage!, filename: defaultAvator)
            self.avatar = try await AliyunClient.UploadImage(image: self.avatarImage!)
            print("self.avatar: \(self.avatar)")
            if (self.avatarImage?.size.width)! > 10{
                await self.updateGroupInfo(avatarURL: self.avatar)
            }else{
                await self.updateGroupInfo(avatarURL: defaultAvator)
            }
            
        }
    }
    
    private func updateGroupInfo(avatarURL: String?) async {
        let updatedGroup = group
        updatedGroup.info.name = groupName
        updatedGroup.info.desc = groupDescription.isEmpty ? "这是一个神秘的小组" : groupDescription
        updatedGroup.info.location = groupLocation
        
        // Convert groupStatusStr to Int64
        if let status = Int64(groupStatusStr) {
            updatedGroup.info.status = Int32(status)
            self.groupStatus = Int32(status)
        } else {
            // Handle invalid input
            alertMessage = "小组状态设置错误"
            showAlert = true
            return
        }
        if let avatarURL = avatarURL {
            updatedGroup.info.avatar = avatarURL
        }
        
        // Assuming you have a GroupManager to handle updates
        let result = await APIClient.shared.UpdateGroup(
            groupId: self.group.info.groupID,
            userId: self.userId,
            avator: self.avatar,
            desc: self.groupDescription,
            owner: self.userId,
            location: self.groupLocation,
            status: Int64(self.groupStatus))
        if result.self != nil {
            alertMessage = "更新小组信息失败"
            showAlert = true
        }else{
            presentationMode.wrappedValue.dismiss()
        }
    }
}

