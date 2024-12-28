//
//  ContentView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI

struct GraperyApp: View {
    @StateObject var viewModel = LoginViewModel()
    @StateObject var registrationViewModel = RegistrationViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLogin && viewModel.currentUser != nil {
                MainTabView(user: viewModel.currentUser!)
            } else {
                LoginView(viewModel: viewModel)
                    .environmentObject(registrationViewModel)
            }
        }
        .task {
            viewModel.loadUserToken()
            print("View appeared, isLogin: \(viewModel.isLogin), currentUser: \(viewModel.currentUser?.name ?? "nil")")
            print("Token: \(viewModel.token.isEmpty ? "empty" : "exists")")
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                print("After loadUserToken - isLogin: \(viewModel.isLogin), currentUser: \(viewModel.currentUser?.name ?? "nil")")
                print("Token status: \(viewModel.token.isEmpty ? "empty" : "exists")")
            }
            if viewModel.token.isEmpty{
                viewModel.isLogin = false
                viewModel.currentUser = nil
            }
        }
    }
}

