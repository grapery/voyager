//
//  LoginView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject public var viewModel:LoginViewModel
    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
    }
    var body: some View {
            VStack {
                VStack {
                    Image("Pattern")
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: 500)
                }
                VStack {
                    TextField("邮箱", text: $viewModel.email)
                        .autocapitalization(.none)
                        .font(.subheadline)
                        .padding(14)
                        .background(Color(.systemGray5))
                        .cornerRadius(14)
                        .padding(.top, 48)
                        .padding(.horizontal, 30)
                    SecureField("密码", text: $viewModel.password)
                        .font(.subheadline)
                        .padding(14)
                        .background(Color(.systemGray5))
                        .cornerRadius(14)
                        .padding(.horizontal, 30)
                }
                Button {
                    action: do{
                        viewModel.signIn()
                    }
                } label: {
                    Text("登入")
                        .font(.headline)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .frame(width: 330, height: 50)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                }
                
                NavigationLink {
                    RegistrationView().navigationBarBackButtonHidden(true)
                } label: {
                    Text("还不是voyager用户? ") + Text("注册")
                        .fontWeight(.bold)
                }
                .padding(.top, 8)
                .foregroundColor(.secondary)
                
                Spacer()
            }
            .ignoresSafeArea()
            .background(Color(.systemGray6))
            .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
    }
}
