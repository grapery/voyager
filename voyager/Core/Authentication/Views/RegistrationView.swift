//
//  RegistrationView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI

struct RegistrationView: View {
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: RegistrationViewModel
    @State private var showCompleteRegistration = false
    
    private var isDisabled: Bool {
        return viewModel.email.isEmpty || viewModel.password.isEmpty || viewModel.username.isEmpty || viewModel.fullname.isEmpty
    }
    
    var body: some View {
        VStack {
            Image("VoyagerLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 50)
                .foregroundColor(.primary)
            Text("创建一个新的用户")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.vertical, 40)
            
            VStack {
                
                TextField("邮箱", text: $viewModel.email)
                    .autocapitalization(.none)
                    .font(.subheadline)
                    .padding(14)
                    .background(Color(.systemGray5))
                    .cornerRadius(14)
                    .padding(.horizontal, 24)
                    .autocorrectionDisabled()
                
                Divider()
                
                
                TextField("用户名", text: $viewModel.username)
                    .autocapitalization(.none)
                    .font(.subheadline)
                    .padding(14)
                    .background(Color(.systemGray5))
                    .cornerRadius(14)
                    .padding(.horizontal, 24)
                    .autocorrectionDisabled()
                
                Divider()
                
                TextField("真实用户名（用户可以选择是否展示）", text: $viewModel.fullname)
                    .font(.subheadline)
                    .padding(14)
                    .background(Color(.systemGray5))
                    .cornerRadius(14)
                    .padding(.horizontal, 24)
                    .autocorrectionDisabled()
                
                Divider()
                
                SecureField("密码", text: $viewModel.password)
                    .font(.subheadline)
                    .padding(14)
                    .background(Color(.systemGray5))
                    .cornerRadius(14)
                    .padding(.horizontal, 24)
                    .autocorrectionDisabled()
                
                Divider()
            }
            
            Spacer()
            
            Button {
                showCompleteRegistration = true
            } label: {
                Text("注册")
                    .font(.headline)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .frame(width: 330, height: 50)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [.purple, .pink, .red, .yellow]), startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .opacity(isDisabled ? 0.5 : 1)
            }
            .disabled(isDisabled)
            
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Image(systemName: "chevron.left")
                    .imageScale(.large)
                    .onTapGesture {
                        dismiss()
                    }
            }
        }
        .navigationDestination(isPresented: $showCompleteRegistration) {
            CompleteRegistrationView(onComplete: {
                // 注册完成后，关闭所有视图，返回到登录页面
                dismiss()
            })
            .navigationBarBackButtonHidden()
        }
    }
}

