//
//  LoginViewModel.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import Foundation
import SwiftUI

class LoginViewModel: ObservableObject {
    private let service = AuthService.shared
    private let userState = UserStateManager.shared
    
    @Published var email = ""
    @Published var password = ""
    @Published var loginError = ""
    
    @MainActor
    func signIn() async {
        do {
            let ret = try await service.login(withEmail: email, password: password)
            if let error = ret.1 {
                self.loginError = error.localizedDescription
                return
            } else {
                // 更新全局用户状态
                userState.setToken(service.token!)
                userState.setCurrentUser(service.currentUser)
                self.email = service.currentUser?.email ?? ""
            }
        } catch {
            self.loginError = error.localizedDescription
        }
    }
    
    @MainActor
    func refreshUserData() async {
        guard !userState.token.isEmpty else {
            print("Token is empty, cannot refresh")
            return
        }
        
        do {
            try await userState.refreshToken()
            // 刷新成功后，可以获取最新的用户信息
            if let newUser = service.currentUser {
                userState.setCurrentUser(newUser)
            }
        } catch {
            print("Failed to refresh user data: \(error.localizedDescription)")
            userState.logout()
        }
    }
    
    @MainActor func signOut() {
        userState.logout()
    }
}

// 确保 User 模型遵循 Codable 协议
extension User: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case avatarUrl
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(name, forKey: .username)
        try container.encode(avatar, forKey: .avatarUrl)
        // ... 编码其他属性
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userID = try container.decode(Int64.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decode(String.self, forKey: .username)
        avatar = try container.decode(String.self, forKey: .avatarUrl)
        // ... 解码其他属性
    }
}
