//
//  CommentDetailView.swift
//  voyager
//
//  Created by grapestree on 2024/10/18.
//

import Foundation
import SwiftUI

struct CommentsCell: View {
    let comment: Comment
    private var user: User? {
        return comment.commentUser
    }
    
    var body: some View {
        HStack {
            CircularProfileImageView(avatarUrl: self.comment.commentUser.avatar, size: .profile)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 2) {
                    Text(self.comment.commentUser.name)
                        .fontWeight(.semibold)
                    Text(comment.realComment.ctime.formatted())
                        .foregroundColor(.gray)
                }
                
                Text(comment.realComment.content)
            }
            .font(.caption)
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct CommentsView: View {
    @State public var commentText = ""
    @StateObject var viewModel : CommentsViewModel
    var user: User
    init(user:User,item: StoryItem) {
        self.user = user
        _viewModel = StateObject(wrappedValue: CommentsViewModel(user: user,itemId:item.itemId))
    }
    var body: some View {
        VStack {
            Text("Comments")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.top, 24)
            
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(viewModel.comments) { comment in
                        CommentsCell(comment: comment)
                    }
                }
            }
            .padding(.top)
            Divider()
            HStack(spacing: 12) {
                CircularProfileImageView(avatarUrl: viewModel.user!.avatar, size: .profile)
                ZStack(alignment: .trailing) {
                    TextField("Add a comment...", text: $commentText, axis: .vertical)
                        .font(.footnote)
                        .padding(12)
                        .padding(.trailing, 40)
                        .overlay {
                            Capsule()
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        }
                    Button {
                        Task {
                            await viewModel.uploadComment(commentText: commentText)
                            commentText = ""
                        }
                    } label: {
                        Text("Post")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal)
                    
                }
            }
            .padding()
        }
    }
}

