//
//  RegistrationViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation

@MainActor
class RegistrationViewModel: ObservableObject {
    private let service = AuthService.shared
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var fullname = ""
    init(username: String = "", email: String = "", password: String = "", fullname: String = "") {
        self.username = username
        self.email = email
        self.password = password
        self.fullname = fullname
    }
    
    func createUser() async throws{
        Task{
            let result = try await service.register(account: self.email, password: self.password, name: self.username, full_name: self.fullname)
            print("register result:\(result)")
        }
    }
}
