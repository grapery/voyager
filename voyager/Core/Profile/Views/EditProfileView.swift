//
//  EditProfileView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI
import PhotosUI

struct EditUserProfileView: View {
    @State private var selectedImage: PhotosPickerItem?
    @StateObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
    }
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                    Spacer()
                    Text("Edit profile")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Button("Done") {
                        Task {
                            try await viewModel.updateUserDate()
                        }
                        dismiss()
                    }
                }
                .padding()
            }
            Divider()
            Spacer()
            VStack {
                PhotosPicker(selection: $viewModel.selectedImage) {
                    if let image = viewModel.userImage {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .background(.gray)
                            .foregroundColor(.primary)
                            .clipShape(Circle())
                    } else {
                        CircularProfileImageView(avatarUrl: viewModel.user!.avatar, size: .InProfile)
                    }
                }
            }
            Divider()
            VStack {
                VStack(alignment: .leading, spacing: 6){
                    Text("Name:")
                        .padding(.horizontal, 25)
                        .font(.subheadline)
                    TextField("Name", text: $viewModel.fullname)
                        .autocapitalization(.none)
                        .font(.subheadline)
                        .padding(14)
                        .background(Color(.systemGray5))
                        .cornerRadius(14)
                        .padding(.horizontal, 24)
                        .autocorrectionDisabled()
                }
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bio:")
                        .padding(.horizontal, 25)
                        .font(.subheadline)
                    TextField("Bio", text: $viewModel.bio)
                        .autocapitalization(.none)
                        .font(.subheadline)
                        .padding(14)
                        .background(Color(.systemGray5))
                        .cornerRadius(14)
                        .padding(.horizontal, 24)
                        .autocorrectionDisabled()
                }
            }
            Spacer()
        }
    }
}

