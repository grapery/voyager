//
//  GroupProfile.swift
//  voyager
//
//  Created by grapestree on 2024/9/30.
//

import SwiftUI
import Kingfisher
import Combine

struct GroupProfileView: View{
    @State var groupId: Int64
    @State var userId: Int64
    @State var currentUserId: Int64
    @State var viewModel: GroupProfileViewModel?
    @Environment(\.presentationMode) var presentationMode
    init(groupId: Int64, userId: Int64) {
        self.groupId = groupId
        self.userId = userId
        self.currentUserId = userId
        self.viewModel = GroupProfileViewModel(groupId: groupId, userId: userId)
    }
    var body: some View{
        return NavigationView {
            Form {
                Section(header: Text("Group Details")) {
                    Text("群组设置")
                }
            }
            .navigationTitle("群组设置")
            .navigationBarItems(leading: cancelButton)
        }
    }
    private var cancelButton: some View {
        Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
