//
//  ProfileViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation

class ProfileViewModel: ObservableObject {
    @Published var user: User?
    init(user: User) {
        self.user = user
        Task { try await fetchUserProfile(uid: user.userID) }
    }
    func fetchUserProfile(uid: Int64) async throws {
        
    }
    @MainActor
    public func signOut() async {
        await AuthService.shared.signout()
    }
    @MainActor
    public func updateProfile() async {
        await APIClient.shared.UpdateProjectProfile(userId: <#T##Int64#>, projrctId: <#T##Int64#>)
    }
}
