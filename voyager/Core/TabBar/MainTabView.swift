//
//  ContentView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI

struct MainTabView: View {
    
    let user: User
    
    @State private var showingNewPostView = false
    @State private var selectedItem = 1
    @State private var oldSelectedItem = 1
    
    var body: some View {
        TabView (selection: $selectedItem){
            FeedView(user: self.user)
                .onTapGesture {
                    self.selectedItem = 1
                }
                .tabItem {
                    Image(systemName: "tornado")
                }
                .tag(1)
            
            GroupView(user: self.user, name:"group")
                .onTapGesture {
                    self.selectedItem = 2
                }
                .tabItem {
                    Image(systemName: "map")
                }
                .tag(2)
            SearchView()
                .onTapGesture {
                    self.selectedItem = 3
                }
                .tabItem {
                    Image(systemName: "bubble")
                }
                .tag(3)
            ProjectView(textValue: "dev")
                .onTapGesture {
                    self.selectedItem = 4
                }
                .tabItem {
                    Image(systemName: "compass")
                }
                .tag(4)
            MainUserProfileView(user: user)
                .onTapGesture {
                    self.selectedItem = 5
                }
                .tabItem {
                    Image(systemName: "shared.with.you")
                }
                .tag(5)
        }
        .accentColor(.primary)
    }
}
