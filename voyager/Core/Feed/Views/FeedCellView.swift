//
//  FeedCellView.swift
//  voyager
//
//  Created by grapestree on 2024/3/29.
//

import Foundation
import SwiftUI

struct FeedCellView: View{
    @ObservedObject var viewModel : FeedCellViewModel
    
    @State private var showComments = false
    @State var showAlert = false
    
    public var user: User? {
        return viewModel.user
    }
    public var didLike: Bool {
        return  false
    }
    
    public var items: StoryItem? {
        return self.viewModel.items
    }
    
    init(viewModel: FeedCellViewModel, showComments: Bool = false, showAlert: Bool = false) {
        self.viewModel = viewModel
        self.showComments = showComments
        self.showAlert = showAlert
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Divider()

            HStack {
                if viewModel.user != nil {
                    CircularProfileImageView(avatarUrl: self.user!.avatar, size: .profile)
                    
                    Text(self.user!.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
            .padding(.leading, 8)
            
            // Post Image
            Text(" ")
                .padding(.trailing, 8)
                .padding(.leading, 54)
            
            // Actions Buttons
            HStack(spacing: 16) {
                HStack(spacing: 3) {
                    Button {
                        handleLikeTapped()
                    } label: {
                        Image(systemName: didLike ? "heart.fill" : "heart")
                            .imageScale(.large)
                            .foregroundColor(didLike ? .red : .black)
                    }
                    
                    //Likes Label
                    if (viewModel.items?.realItem.ctime)!  > 0 {
                        Text("likes")
                            .font(.footnote)
                    }
                }
                
                Button {
                    handleCommentTapped()
                } label: {
                    Image(systemName: "bubble.right")
                }
                
                Spacer()
                
                Text(String((viewModel.items?.realItem.ctime)!))
                    .font(.footnote)
                    .padding(.trailing, 20)
                    .foregroundColor(.gray)
                
            }
            .padding(.leading, 10)
            .padding(.top, 4)
            .tint(.black)
            
            
        }
        .alert("Log In to Interact", isPresented: $showAlert, actions: {
            Button("OK"){
                
            }
        })
        .sheet(isPresented: $showComments) {
            CommentsView(user: self.user!, item: self.items!)
                .presentationDragIndicator(.visible)
        }
    }
    
    func handleCommentTapped() {
        if (user != nil) {
            showComments.toggle()
        } else {
            showAlert.toggle()
        }
    }
    
    private func handleLikeTapped() {
        Task {
            if didLike {
                await viewModel.unlike()
            } else {
                await viewModel.like()
            }
        }
    }
}
