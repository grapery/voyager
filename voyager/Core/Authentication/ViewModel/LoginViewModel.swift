//
//  LoginViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation

class LoginViewModel: ObservableObject {
    private let service = AuthService.shared
    @Published var email = ""
    @Published var password = ""
    @Published var token = ""
    @Published var currentUser: User?
    
    @MainActor
    func signIn(){
        loadUserToken()
        if token.isEmpty {
            Task{
                await service.login(withEmail: email, password: password)
                self.token = service.token!
                self.currentUser = service.currentUser
                self.email = self.currentUser!.email
                self.saveUserToken()
            }
        }
    }
    init() {
        loadUserToken()
    }
    
    func loadUserToken() {
        
    }
    
    func saveUserToken(){
        
    }
}
