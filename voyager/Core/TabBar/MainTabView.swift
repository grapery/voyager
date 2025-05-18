//
//  ContentView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI

enum MainTab: Int, CaseIterable {
    case bold, italic, underline, highlight, code

    var icon: String {
        switch self {
        case .bold: return "bold"
        case .italic: return "italic"
        case .underline: return "underline"
        case .highlight: return "textformat"
        case .code: return "chevron.left.slash.chevron.right"
        }
    }
    var label: String {
        switch self {
        case .bold: return "B"
        case .italic: return "I"
        case .underline: return "U"
        case .highlight: return "Aa"
        case .code: return "</>"
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
                                Circle()
                                    .fill(.white)
                                    .frame(width: 36, height: 36)
                                    .matchedGeometryEffect(id: "selectedTab", in: animation)
                            }
                            if tab == .bold {
                                Image(systemName: "target")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(selected == tab ? Color(hex: "#23202A") : Color(hex: "#5B4B8A"))
                            } else if tab == .italic {
                                Image(systemName: "circle.hexagonpath")
                                    .font(.system(size: 18, weight: .regular)).italic()
                                    .foregroundColor(selected == tab ? Color(hex: "#23202A") : Color(hex: "#5B4B8A"))
                            } else if tab == .underline {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .regular)).underline()
                                    .foregroundColor(selected == tab ? Color(hex: "#23202A") : Color(hex: "#5B4B8A"))
                            } else if tab == .highlight {
                                Image(systemName: "message")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(selected == tab ? Color(hex: "#23202A") : Color(hex: "#5B4B8A"))
                            } else if tab == .code {
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
    @State private var selectedTab: MainTab = .bold
    @State private var oldSelectedTab: MainTab = .bold
    init(user: User) {
        self.user = user
        self.selectedTab = .bold
        self.oldSelectedTab = .bold
        
        // 设置 UITabBar 的外观
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(Color.clear)
        
        // 调整 TabBar 的高度
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().frame.size.height = 30 // 设置标准高度
    }
    var body: some View {
        ZStack(alignment: .bottom) {
            // 主内容区域，背景透明
            Group {
                switch selectedTab {
                case .bold: FeedView(user: user)
                case .italic: GroupView(user: user)
                case .underline: MessageView(user: user)
                case .highlight: UserProfileView(user: user)
                case .code: Text("Code View")
                }
            }
            .background(Color.clear)
            // CustomTabBar 紧贴底部，8pt 间距
            CustomTabBar(selected: $selectedTab)
                .padding(.bottom, 8)
        }
        .background(Color.clear)
    }
}

