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
    }
    var body: some View {
        TabView (selection: $selectedItem){
            FeedView(userId: self.user.userID)
                .onTapGesture {
                    self.selectedItem = 1
                }
                .tabItem {
                    Image(systemName: "ellipsis.viewfinder")
                    Text("发现")
                }
                .tag(1)
            GroupView(user: self.user)
                .onTapGesture {
                    self.selectedItem = 2
                }
                .tabItem {
                    Image(systemName: "rectangle.3.group")
                    Text("小组")
                }
                .tag(2)
            MessageView(user: self.user)
                .onTapGesture {
                    self.selectedItem = 3
                }
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("消息")
                }
                .tag(3)
            UserProfileView(user: self.user)
                .onTapGesture {
                    self.selectedItem = 4
                }
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("个人")
                }
                .tag(4)
        }
        .accentColor(.primary)
    }
}
