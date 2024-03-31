//
//  ProfileViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation

class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var profile: UserProfile
    init(user: User) {
        self.user = user
        self.profile = UserProfile()
        Task{
            await fetchUserProfile()
        }
    }
    func fetchUserProfile() async -> UserProfile{
        let profile = await APIClient.shared.fetchUserProfile(userId: self.user?.userID ?? -1)
        return profile
    }
    @MainActor
    public func signOut() async {
        await AuthService.shared.signout()
    }
    @MainActor
    public func updateProfile() async {
        let newProfile = await APIClient.shared.updateUserProfile(userId: self.user!.userID,profile: self.profile)
        print(newProfile)
    }
}
