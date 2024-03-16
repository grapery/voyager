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
            FeedView()
                .tabItem {
                    Image(systemName: "tornado")
                }
                .tag(1)
            
            HotmapView()
                .tabItem {
                    Image(systemName: "map")
                }
                .tag(2)
            
            Text("New...")
                .tabItem {
                    Image(systemName: "rectangle.and.pencil.and.ellipsis")
                }
                .tag(3)
            
            Text("Subscript")
                .tabItem {
                    Image(systemName: "bubble")
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
            NewLeafView(user: user)
        }
    }
}
