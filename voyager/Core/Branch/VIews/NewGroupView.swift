//
//  NewGroupView.swift
//  voyager
//
//  Created by grapestree on 2024/4/11.
//

import SwiftUI

struct NewGroupView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) private var dismiss
    public var viewModel: GroupViewModel
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var avatar: UIImage?
    @State private var showImagePicker: Bool = false
    
    init(userId: Int64,viewModel: GroupViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            
            VStack {
                Spacer()
                
                VStack(alignment: .center) {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        if let avatar = avatar {
                            Image(uiImage: avatar)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "infinity.circle")
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: 80, maxHeight: 80)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.bottom, 20)
                }
                
                VStack(alignment: .center) {
                    TextField("小组名称", text: $name)
                        .autocapitalization(.none)
                        .font(.subheadline)
                        .padding(14)
                        .background(Color(.systemGray5))
                        .cornerRadius(14)
                        .padding(.horizontal, 30)
                    
                    TextField("小组描述", text: $description)
                        .autocapitalization(.none)
                        .font(.subheadline)
                        .padding(14)
                        .background(Color(.systemGray5))
                        .cornerRadius(14)
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                }
                
                Spacer()
                    .frame(maxWidth: .infinity, maxHeight: 80)
                
                VStack(spacing: 16) {
                    Button(action: createGroup) {
                        Text("创建小组")
                            .font(.headline)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .frame(width: 330, height: 50)
                            .background(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("取消")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .fontWeight(.medium)
                            .frame(width: 330, height: 50)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                    }
                }
                .padding(.bottom, 32)
            }
            .padding(.top, 50)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("错误"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
        }
        .sheet(isPresented: $showImagePicker) {
            SingleImagePicker(image: $avatar)
        }
        .navigationBarItems(leading: cancelButton)
        .navigationBarBackButtonHidden(true)
    }
    
    private var cancelButton: some View {
        Button("取消") {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    @MainActor
    private func createGroup()  {
        guard !name.isEmpty else {
            showAlert(message: "请输入小组名称")
            return
        }
        
        // 创建小组的逻辑
        var result: BranchGroup?
        var err: Error?
        Task{
            (result,err) = await viewModel.createGroup(creatorId: self.viewModel.user.userID ,name: name, description: description, avatar: avatar!)
        }
        if err == nil{
            presentationMode.wrappedValue.dismiss()
            print("create group success \(result?.info.name ?? name)")
            return
        }
        showAlert(message: err!.localizedDescription)
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}
