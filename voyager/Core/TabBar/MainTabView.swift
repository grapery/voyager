//
//  ContentView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI

enum MainTab: Int, CaseIterable {
    case DiscoverOption, GroupOption, MessgeOption, PersonOption

    var icon: String {
        switch self {
        case .DiscoverOption: return "discover"
        case .GroupOption: return "group"
        case .MessgeOption: return "message"
        case .PersonOption: return "person"
        }
    }
    var label: String {
        switch self {
        case .DiscoverOption: return "d"
        case .GroupOption: return "g"
        case .MessgeOption: return "m"
        case .PersonOption: return "p"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selected: MainTab
    @Namespace var animation

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(hex: "#D1C3F6"))
                .frame(height: 52)
                .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 6)
            HStack(spacing: 0) {
                ForEach(MainTab.allCases, id: \.self) { tab in
                    Spacer(minLength: 0)
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selected = tab
                        }
                    } label: {
                        ZStack {
                            if selected == tab {
                                Capsule()
                                    .fill(.white)
                                    .frame(width: 84, height:42)
                                    .matchedGeometryEffect(id: "selectedTab", in: animation)
                            }
                            if tab == .DiscoverOption {
                                Image(systemName: "target")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(selected == tab ? Color(hex: "#23202A") : Color(hex: "#5B4B8A"))
                            } else if tab == .GroupOption {
                                Image(systemName: "circle.hexagonpath")
                                    .font(.system(size: 18, weight: .regular)).italic()
                                    .foregroundColor(selected == tab ? Color(hex: "#23202A") : Color(hex: "#5B4B8A"))
                            } else if tab == .MessgeOption {
                                Image(systemName: "message")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(selected == tab ? Color(hex: "#23202A") : Color(hex: "#5B4B8A"))
                            } else if tab == .PersonOption {
                                Image(systemName: "person")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(selected == tab ? Color(hex: "#23202A") : Color(hex: "#5B4B8A"))
                            }
                        }
                        .frame(width: 44, height: 44)
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }
}


struct MainTabView: View {
    @State var user: User
    @State private var selectedTab: MainTab = .DiscoverOption
    @State private var oldSelectedTab: MainTab = .DiscoverOption
    @State private var showTabBar: Bool = true
    
    
    init(user: User) {
        self.user = user
        self.selectedTab = .DiscoverOption
        self.oldSelectedTab = .DiscoverOption
        
        // 设置 UITabBar 的外观
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(Color.clear)
        
        // 调整 TabBar 的高度
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().frame.size.height = 5 // 设置标准高度
    }
    var body: some View {
        ZStack(alignment: .bottom) {
            // 主内容区域，背景透明
            Group {
                switch selectedTab {
                case .DiscoverOption: FeedView(user: user, showTabBar: $showTabBar)
                case .GroupOption: GroupView(user: user)
                case .MessgeOption: MessageView(user: user)
                case .PersonOption: UserProfileView(user: user)
                }
            }
            .background(Color.clear)
            // CustomTabBar 紧贴底部，去除多余间距
            if showTabBar {
                CustomTabBar(selected: $selectedTab)
                    .padding(.bottom, 0)
            }
        }
        .background(Color.clear)
    }
}

