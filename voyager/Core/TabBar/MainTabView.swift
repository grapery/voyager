//
//  ContentView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI

enum MainTab: Int, CaseIterable {
    case home, messages,groups, profile

    var icon: String {
        switch self {
        case .home: return "house"
        //case .stories: return "book"
        case .messages: return "message"
        case .groups: return "person.2"
        case .profile: return "person"
        }
    }
    var label: String {
        switch self {
        case .home: return "Home"
        //case .stories: return "Stories"
        case .messages: return "Messages"
        case .groups: return "Groups"
        case .profile: return "Profile"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selected: MainTab

    var body: some View {
        VStack(spacing: 0) {
            // 顶部分割线
            Rectangle()
                .fill(Color.theme.divider)
                .frame(height: 1)
                .edgesIgnoringSafeArea(.horizontal)
            HStack {
                ForEach(MainTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selected = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: selected == tab ? .bold : .regular))
                                .foregroundColor(selected == tab ? Color.white: Color.theme.tertiaryText)
                            Text(tab.label)
                                .font(.system(size: 12, weight: selected == tab ? .bold : .regular))
                                .foregroundColor(selected == tab ? Color.white: Color.theme.tertiaryText)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 18)
            .background(
                Color.theme.secondaryBackground
                    .clipShape(RoundedRectangle(cornerRadius: 1, style: .continuous))
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: -2)
            )
        }
        .padding(.horizontal, 0)
    }
}

struct MainTabView: View {
    @State var user: User
    @State private var selectedTab: MainTab = .home
    @State private var showTabBar: Bool = true

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home: FeedView(user: user, showTabBar: $showTabBar)
                //case .stories: GroupView(user: user) // 这里假设 GroupView 是处理故事的视图
                case .messages: MessageView(user: user) // 这里假设 MessageView 是处理消息的视图
                case .groups: GroupView(user: user)
                case .profile: UserProfileView(user: user)
                }
            }
            .background(Color.theme.background)
            if showTabBar {
                CustomTabBar(selected: $selectedTab)
                    .transition(.move(edge: .bottom))
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .background(Color.theme.background)
    }
}

