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
            CircularProfileImageView(avatarUrl: self.comment.commentUser.avatar, size: .InContent)
            
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

struct StoryCommentsView: View {
    @State public var commentText = ""
    @StateObject var viewModel : CommentsViewModel
    var storyId: Int64
    var user: User
    init(storyId:Int64,user:User) {
        self.user = user
        self.storyId = storyId
        _viewModel = StateObject(wrappedValue: CommentsViewModel())
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
                CircularProfileImageView(avatarUrl: self.user.avatar, size: .InProfile)
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
                            if commentText.isEmpty {
                                print("empty comment")
                                commentText = ""
                            }else{
                                await viewModel.submitCommentForStory(commentText: commentText, storyId: self.storyId, userId: self.user.userID)
                            }
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

