//
//  LoginView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject public var viewModel:LoginViewModel
    @EnvironmentObject var globalEnv: LoginViewModel
    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
    }
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                VStack (alignment: .center){
                    Image(systemName: "infinity.circle")
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: 80, maxHeight: 80)
                        .foregroundColor(Color.theme.accent)
                }
                VStack (alignment: .center){
                    VStack {
                        TextField("邮箱", text: $viewModel.email)
                            .autocapitalization(.none)
                            .font(.subheadline)
                            .padding(14)
                            .background(Color.theme.inputBackground)
                            .foregroundColor(Color.theme.inputText)
                            .cornerRadius(14)
                            .padding(.top, 48)
                            .padding(.horizontal, 30)
                        SecureField("密码", text: $viewModel.password)
                            .font(.subheadline)
                            .padding(14)
                            .background(Color.theme.inputBackground)
                            .foregroundColor(Color.theme.inputText)
                            .cornerRadius(14)
                            .padding(.horizontal, 30)
                    }
                    Spacer()
                        .frame(maxWidth: .infinity, maxHeight: 80)
                    Button {
                        action: do{
                            viewModel.signIn()
                        }
                    } label: {
                        Text("登入")
                            .font(.headline)
                            .foregroundColor(Color.theme.buttonText)
                            .fontWeight(.bold)
                            .frame(width: 330, height: 50)
                            .background(Color.theme.buttonBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                    }
                }
                NavigationLink {
                    RegistrationView().navigationBarBackButtonHidden(true)
                } label: {
                    Text("还不是voyager用户? ") + Text("注册")
                        .fontWeight(.bold)
                }
                .padding(.top, 8)
                .foregroundColor(Color.theme.secondaryText)
                
                Spacer()
            }
            .background(Color.theme.background)
            .ignoresSafeArea()
        }
    }
}
