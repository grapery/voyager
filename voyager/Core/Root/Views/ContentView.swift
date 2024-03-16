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
            if viewModel.token.isEmpty{
                LoginView(viewModel: viewModel).environmentObject(registrationViewModel)
            } else if let currentUser = viewModel.currentUser {
                MainTabView(user: currentUser)
            }
        }
    }
}

