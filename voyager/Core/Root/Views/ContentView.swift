//
//  ContentView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI
import ConcentricOnboarding

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



struct ContentView: View {
    
    @State private var currentIndex: Int = 0
    
    var body: some View {
        ConcentricOnboardingView(pageContents: MockData.pages.map { (PageView(page: $0), $0.color) })
            .duration(1.0)
            .nextIcon("chevron.forward")
            .animationDidEnd {
                print("Animation Did End")
            }
    }
}

