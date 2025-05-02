//
//  ContentView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI

struct GraperyApp: View {
    @StateObject private var userState = UserStateManager.shared
    @StateObject var registrationViewModel = RegistrationViewModel()
    
    var body: some View {
        Group {
            if userState.isLoading {
                // 显示加载界面
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else if userState.isLoggedIn && userState.currentUser != nil {
                MainTabView(user: userState.currentUser!)
            } else {
                LoginView()
                    .environmentObject(registrationViewModel)
            }
        }
        .task {
            // 初始化用户状态
            await userState.initialize()
        }
    }
}

