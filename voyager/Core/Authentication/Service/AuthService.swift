//
//  AuthService.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import Connect

class AuthService {
    
    @Published var token: String?
    @Published var currentUser: User?
    
    static let shared = AuthService()
    
    init() {
        Task { try await loadUserData() }
    }
    
    @MainActor
    func login(withEmail email: String, password: String) async throws{
        let result = try await APIClient.shared.Login(account: email, password: password)
        if result.token == "" {
            return
        }
        self.token = result.token
        self.currentUser = try await APIClient.shared.GetUserInfo(userId: result.userID)
        print("user \(String(describing: self.currentUser))")
    }
    
     
    @MainActor
    func loadUserData() async throws {
        if self.token == "" || self.currentUser == nil {
            return
        }
//        self.userSession = Auth.auth().currentUser
//        guard let currentUid = self.userSession?.uid else { return }
//        self.currentUser = try await UserService.fetchUser(withUid: currentUid)
    }
    
    func signout() async throws{
        // TODO： 删除本地缓存的token，然后和服务器交互、或者写入本地标记位需要重新登录
        if self.token == "" {
            return 
        }
        self.token = ""
        let result = try await APIClient.shared.Logout()
        print("logout result:\(result)")
    }
    
    func refreshToken() async throws{
       // 程序自动和服务程序交互，刷新token
        if self.token != "" {
            let result = try await APIClient.shared.RefreshToken(curToken:self.token!)
            print("refresh new token: \(result)")
        }
        return
    }
    
    func register(account email: String,password: String,name: String,full_name: String) async throws -> Int32{
        // 注册用户
        let result = try await APIClient.shared.Register(account: email, password: password, name: name)
        
        print("register result:\(result.status)")
        return result.status
    }
    
    func uploadUserData(uid: String, username: String, email: String, fullname: String) async {
//        let user = User(id: uid, email: email, username: username, fullname: fullname, isCurrentUser:true)
//        self.currentUser = user
    }
}

