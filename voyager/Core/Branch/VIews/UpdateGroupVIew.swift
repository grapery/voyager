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
        _avatarImage = State(initialValue: UIImage(systemName: "infinity.circle"))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Group Details")) {
                    // Avatar picker
                    Button(action: { isImagePickerPresented = true }) {
                        if let avatarImage = avatarImage {
                            Image(uiImage: avatarImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                        } else {
                            Text("Select Avatar")
                        }
                    }
                    
                    TextField("小组名称", text: $groupName)
                    TextField("小组简介", text: $groupDescription)
                    TextField("地址（可以虚拟、可以真实）", text: $groupLocation)
                    TextField("小组状态", text: $groupStatusStr)
                }
                
                Section {
                    Button(action: updateGroup) {
                        Text("更新小组信息")
                    }
                }
            }
            .navigationTitle("Update Group")
            .navigationBarItems(leading: cancelButton)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $isImagePickerPresented) {
            SingleImagePicker(image: $avatarImage)
        }
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
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
            self.avatar = try await APIClient.shared.uploadImage(image: self.avatarImage!, filename: defaultAvator)
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

