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
    @Published var isLogin = false
    
    @Published var LoginError = ""
    
    @MainActor
    func signIn(){
        loadUserToken()
        if token.isEmpty {
            Task{
                let ret = await service.login(withEmail: email, password: password)
                if ret.1 != nil {
                    self.isLogin = false
                    self.LoginError = ret.1!.localizedDescription
                    return
                }else{
                    self.token = service.token!
                    self.currentUser = service.currentUser
                    self.email = self.currentUser!.email
                    self.saveUserToken()
                    isLogin = true
                }
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
