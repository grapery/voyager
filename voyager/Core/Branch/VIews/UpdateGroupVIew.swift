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
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    let group: BranchGroup 
    
    init(group: BranchGroup) {
        self.group = group
        _groupName = State(initialValue: group.info.name)
        _groupDescription = State(initialValue: group.info.desc ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Group Details")) {
                    TextField("Group Name", text: $groupName)
                    TextField("Description (Optional)", text: $groupDescription)
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
        
        // 在这里实现更新 Group 的逻辑
        // 例如: 
        // var updatedGroup = group
        // updatedGroup.name = groupName
        // updatedGroup.description = groupDescription
        // GroupManager.shared.updateGroup(updatedGroup)
        
        // 更新成功后关闭视图
        presentationMode.wrappedValue.dismiss()
    }
}

