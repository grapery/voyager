//
//  ContentView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI

struct MainTabView: View {
    @State var user: User
    @State private var selectedItem: Int = 1
    @State private var oldSelectedItem: Int = 1
    init(user: User) {
        self.user = user
        self.selectedItem = 1
        self.oldSelectedItem = 1
        
        // 设置 UITabBar 的外观
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(named: "2C2C2E")
        
        // 调整 TabBar 的高度
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().frame.size.height = 49 // 设置标准高度
    }
    var body: some View {
        TabView (selection: $selectedItem){
            FeedView(userId: self.user.userID)
                .onTapGesture {
                    self.selectedItem = 1
                }
                .tabItem {
                    Circle()
                        .fill(selectedItem == 1 ? Color(hex: "A5D661") : Color.clear)
                        .overlay(
                            Image(systemName: "target")
                                .foregroundColor(selectedItem == 1 ? .white : .gray)
                        )
                    Text("发现")
                        .foregroundColor(selectedItem == 1 ? Color(hex: "A5D661") : .gray)
                }
                .tag(1)
            GroupView(user: self.user)
                .onTapGesture {
                    self.selectedItem = 2
                }
                .tabItem {
                    Circle()
                        .fill(selectedItem == 2 ? Color(hex: "A5D661") : Color.clear)
                        .overlay(
                            Image(systemName: "circle.hexagonpath")
                                .foregroundColor(selectedItem == 2 ? .white : .gray)
                        )
                    Text("小组")
                        .foregroundColor(selectedItem == 2 ? Color(hex: "A5D661") : .gray)
                }
                .tag(2)
            MessageView(user: self.user)
                .onTapGesture {
                    self.selectedItem = 3
                }
                .tabItem {
                    Circle()
                        .fill(selectedItem == 3 ? Color(hex: "A5D661") : Color.clear)
                        .overlay(
                            Image(systemName: "message")
                                .foregroundColor(selectedItem == 3 ? .white : .gray)
                        )
                    Text("消息")
                        .foregroundColor(selectedItem == 3 ? Color(hex: "A5D661") : .gray)
                }
                .tag(3)
            UserProfileView(user: self.user)
                .onTapGesture {
                    self.selectedItem = 4
                }
                .tabItem {
                    Circle()
                        .fill(selectedItem == 4 ? Color(hex: "A5D661") : Color.clear)
                        .overlay(
                            Image(systemName: "person")
                                .foregroundColor(selectedItem == 4 ? .white : .gray)
                        )
                    Text("个人")
                        .foregroundColor(selectedItem == 4 ? Color(hex: "A5D661") : .gray)
                }
                .tag(4)
        }
        .background(Color(hex: "2C2C2E"))
        .accentColor(.primary)
    }
}
