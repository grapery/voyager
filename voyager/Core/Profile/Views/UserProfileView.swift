//
//  UserProfileView.swift
//  voyager
//
//  Created by grapestree on 2024/10/2.
//


import SwiftUI

struct UserProfileView: View {
    @State private var selectedFilter: LeafFilterViewModel = .storyitems
    @State private var showingEditProfile = false
    @Namespace var animation
    var user: User
    @StateObject var viewModel: ProfileViewModel
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
        self.user = user
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.name)
                                .foregroundColor(.primary)
                                .font(.title)
                                .bold()
                            
                            Text(user.name)
                                .font(.subheadline)
                        }
                        Spacer()
                        
                        CircularProfileImageView(avatarUrl: user.avatar, size: .profile)
                    }
                    
                    Text("\(10) Followers")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 5)
                    
                    Button("Edit Profile") {
                        showingEditProfile.toggle()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(height: 32)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.primary)
                    .overlay(RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary, lineWidth: 1))
                    HStack {
                        ForEach(LeafFilterViewModel.allCases, id: \.rawValue) { item in
                            VStack {
                                Text(item.title)
                                    .font(.subheadline)
                                    .fontWeight(selectedFilter == item ? .semibold : .regular)
                                    .foregroundColor(selectedFilter == item ? .primary : .secondary)
                                
                                
                                Capsule()
                                    .foregroundColor(selectedFilter == item ? .primary : .secondary)
                                    .frame(height: 3)
                                
                            }
                            .onTapGesture {
                                withAnimation(.easeInOut) {
                                    selectedFilter = item
                                }
                            }
                        }
                    }
                    .overlay(Divider().offset(x: 0, y: 17))
                    
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        
                    } label: {
                        Image(systemName: "lock")
                    }
                    .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        //AuthService.shared.signout()
                    } label : {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            ProfileView(user: user)
        }
    }
}
