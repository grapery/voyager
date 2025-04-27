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
            if viewModel.token.isEmpty{
                viewModel.isLogin = false
                viewModel.currentUser = nil
            }
        }
    }
}

