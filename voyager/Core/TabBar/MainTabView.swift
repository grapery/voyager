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
                .tabItem {
                    Image(systemName: "tornado")
                }
                .tag(1)
            
            GroupView(user: self.user, name:"group")
                .tabItem {
                    Image(systemName: "map")
                }
                .tag(2)
            SearchView()
                .tabItem {
                    Image(systemName: "bubble")
                }
                .tag(3)
            ProjectView(textValue: "dev")
                .tabItem {
                    Image(systemName: "compass")
                }
                .tag(4)
            MainUserProfileView(user: user)
                .tabItem {
                    Image(systemName: "shared.with.you")
                }
                .tag(5)
        }
        .accentColor(.primary)
        .onChange(of: selectedItem) {
            if selectedItem == 3 {
                self.showingNewPostView.toggle()
                self.selectedItem = oldSelectedItem
            } else if (showingNewPostView == false) {
                self.oldSelectedItem = $0
            }
        }
        .sheet(isPresented: $showingNewPostView) {
            NewStoryItemView(user: user)
        }
    }
}
