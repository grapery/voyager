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
        print("MainTabView init user",self.user )
    }
    var body: some View {
        TabView (selection: $selectedItem){
            FeedView(userId: user.userID)
                .onTapGesture {
                    self.selectedItem = 1
                }
                .tabItem {
                    Image(systemName: "ellipsis.viewfinder")
                }
                .tag(1)
            GroupView(user: self.user)
                .onTapGesture {
                    self.selectedItem = 2
                }
                .tabItem {
                    Image(systemName: "rectangle.3.group")
                }
                .tag(2)
            MessageView(user: self.user)
                .onTapGesture {
                    self.selectedItem = 3
                }
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                }
                .tag(3)
            UserProfileView(user: user)
                .onTapGesture {
                    self.selectedItem = 4
                }
                .tabItem {
                    Image(systemName: "person.circle")
                }
                .tag(4)
        }
        .accentColor(.primary)
    }
}
