//
//  ContentView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI
import ConcentricOnboarding
import ActivityIndicatorView

struct GraperyApp: View {
    @StateObject private var userState = UserStateManager.shared
    @StateObject var registrationViewModel = RegistrationViewModel()
    @AppStorage("hasSeenOnboarding1") var hasSeenOnboarding: Bool = false
    @State private var showOnboarding: Bool = false

    var body: some View {
        Group {
            if userState.isLoading {
                // 显示加载界面
                ActivityIndicatorView(isVisible: .constant(userState.isLoading), type: .arcs())
                                            .frame(width: 100, height: 100)
                                            .foregroundColor(.red)
            } else if userState.isLoggedIn && userState.currentUser != nil {
                MainTabView(user: userState.currentUser!)
            } else {
                LoginView()
                    .environmentObject(registrationViewModel)
            }
        }
        .onAppear {
            if !hasSeenOnboarding {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnBoardingView {
                hasSeenOnboarding = true
                showOnboarding = false
            }
        }
        .task {
            // 初始化用户状态
            await userState.initialize()
        }
    }
}



struct OnBoardingView: View {
    
    @State private var currentIndex: Int = 0
    var onFinish: (() -> Void)? = nil

    var body: some View {
        ConcentricOnboardingView(pageContents: MockData.pages.map { (PageView(page: $0), $0.color) })
            .duration(1.0)
            .nextIcon("chevron.forward")
            .animationDidEnd {
                print("Animation Did End")
                onFinish?()
            }
    }
}

