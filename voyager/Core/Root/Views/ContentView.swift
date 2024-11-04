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
            print("View appeared, isLogin: \(viewModel.isLogin), currentUser: \(viewModel.currentUser?.name ?? "nil")")
            print("Token: \(viewModel.token.isEmpty ? "empty" : "exists")")
            await viewModel.loadUserToken()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("After loadUserToken - isLogin: \(viewModel.isLogin), currentUser: \(viewModel.currentUser?.name ?? "nil")")
                print("Token status: \(viewModel.token.isEmpty ? "empty" : "exists")")
            }
        }
    }
}

