//
//  NewGroupView.swift
//  voyager
//
//  Created by grapestree on 2024/4/11.
//

import SwiftUI

struct NewGroupView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var groupName: String = ""
    @State private var groupDescription: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var createdGroupId: Int64 = 0
    
    public var userId: Int64 = 0
    init(userId: Int64) {
        self.userId = userId
        print("userid: ",self.userId)
    }
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Group Details")) {
                    TextField("Group Name", text: $groupName)
                    TextField("Description (Optional)", text: $groupDescription)
                }
                
                Section {
                    Button(action: createGroup) {
                        Text("Create Group")
                    }
                }
            }
            .navigationTitle("New Group")
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
    
    private func createGroup()  {
        guard !groupName.isEmpty else {
            alertMessage = "Group name cannot be empty"
            showAlert = true
            return
        }
        var result: BranchGroup?
        var err: Error?
        // 在这里实现创建 Group 的逻辑
        var userId: Int64 = self.userId
        Task{
            (result,err) = await APIClient.shared.CreateGroup(userId: userId, name: self.groupName)
            if err != nil {
                showAlert = true
                alertMessage = "create group failed!"
            }else{
                self.createdGroupId = (result?.info.groupID)!
            }
        }
        // 创建成功后关闭视图
        presentationMode.wrappedValue.dismiss()
    }
}

struct NewGroupView_Previews: PreviewProvider {
    static var previews: some View {
        NewGroupView(userId: 1)
    }
}
