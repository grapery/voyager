//
//  ProfileViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation

class ProfileViewModel: ObservableObject {
    public let user: User
    init(user: User) {
        self.user = user
        Task { try await fetchUserProfile(uid: user.userID) }
    }
    @MainActor
    func fetchUserProfile(uid: Int64) async throws {
        
    }
}
