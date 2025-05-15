//
//  DeleteGroupView.swift
//  voyager
//
//  Created by grapestree on 2024/4/11.
//

import SwiftUI
import ActivityIndicatorView

struct DeleteGroupView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var showConfirmation: Bool = false
    let group: BranchGroup // 假设有一个 Group 模型
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Delete Group")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Are you sure you want to delete this group?")
                .multilineTextAlignment(.center)
            
            Button(action: {
                showConfirmation = true
            }) {
                Text("Delete Group")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
            }
        }
        .padding()
        .alert(isPresented: $showConfirmation) {
            Alert(
                title: Text("Confirm Deletion"),
                message: Text("This action cannot be undone. Are you sure?"),
                primaryButton: .destructive(Text("Delete")) {
                    deleteGroup()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func deleteGroup() {
        // 在这里实现删除 Group 的逻辑
        // 例如: GroupManager.shared.deleteGroup(group)
        
        // 删除后关闭视图
        presentationMode.wrappedValue.dismiss()
    }
}

