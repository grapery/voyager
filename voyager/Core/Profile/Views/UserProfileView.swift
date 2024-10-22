//
//  UserProfileView.swift
//  voyager
//
//  Created by grapestree on 2024/10/2.
//


import SwiftUI

struct UserProfileView: View {
    @State private var selectedFilter: UserProfileFilterViewModel = .storys
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
                            
                            Text(user.desc)
                                .font(.subheadline)
                        }
                        Spacer()
                        CircularProfileImageView(avatarUrl: user.avatar.isEmpty ? defaultAvator : user.avatar, size: .profile)
                        
                    }
                    
                    HStack{
                        VStack{
                            Text("加入 \(viewModel.profile.inGroupNum) 个群组")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 5)
                            Spacer()
                        }
                        VStack{
                            Text("参与 \(viewModel.profile.contriProjectNum) 个故事")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 5)
                            Spacer()
                        }
                    }
                    Divider()
                    HStack {
                        ForEach(UserProfileFilterViewModel.allCases, id: \.rawValue) { item in
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
                        Image(systemName: "gearshape.circle")
                    }
                    .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingEditProfile.toggle()
                    } label : {
                        Image(systemName: "slider.vertical.3")
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
