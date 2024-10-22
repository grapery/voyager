//
//  ProfileView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI

struct ProfileView: View {
    
    var user: User
    
    @State private var selectedFilter: UserProfileFilterViewModel = .storys
    
    @Namespace var animation
    
    @StateObject var viewModel: ProfileViewModel
    
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
        self.user = user
    }
    
    var body: some View {
        ScrollView {
            // Header
            VStack(alignment: .leading) {
                
                //Profile info
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
                
                Button("Follow") {
                    //Edit Profile
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(height: 32)
                .frame(maxWidth: .infinity)
                .foregroundColor(.primary)
                .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary, lineWidth: 1))
                
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    
                } label : {
                    Image(systemName: "ellipsis.circle")
                }
                .foregroundColor(.primary)
            }
        }
        
    }
}
