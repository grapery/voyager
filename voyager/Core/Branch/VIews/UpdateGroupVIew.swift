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
                    
                    TextField("Group Name", text: $groupName)
                    TextField("Description", text: $groupDescription)
                    TextField("Location (Optional)", text: $groupLocation)
                    TextField("Status (Optional)", text: $groupStatusStr)
                }
                
                Section {
                    Button(action: updateGroup) {
                        Text("Update Group")
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
        if let avatarImage = avatarImage {
            Task{
                self.avatar = try await APIClient.shared.uploadImage(image: avatarImage, filename: "data.jpg")
            }
        }
        // Update group without changing avatar
        Task{
            await self.updateGroupInfo(avatarURL: self.avatar)
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
            alertMessage = "Invalid status value. Please enter a valid number."
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
            alertMessage = "Failed to update group"
            showAlert = true
        }else{
            presentationMode.wrappedValue.dismiss()
        }
    }
}

