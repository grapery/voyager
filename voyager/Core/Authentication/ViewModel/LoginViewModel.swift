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
    
    // UserDefaults keys
    private let tokenKey = "VoyagerUserToken"
    private let tokenExpirationKey = "VoyagerTokenExpiration"
    private let userEmailKey = "VoyagerUserEmail"
    private let currentUserKey = "VoyagerCurrentUser"
    
    @MainActor
    func signIn() {
        Task {
            if token.isEmpty {
                let ret = await service.login(withEmail: email, password: password)
                if let error = ret.1 {
                    self.isLogin = false
                    self.LoginError = error.localizedDescription
                    return
                } else {
                    self.token = service.token!
                    self.currentUser = service.currentUser
                    self.email = self.currentUser!.email
                    // Save token and user data
                    saveUserToken()
                    saveCurrentUser()
                    isLogin = true
                }
            }
        }
    }
    
    // Save current user to UserDefaults
    private func saveCurrentUser() {
        guard let currentUser = currentUser else { return }
        
        do {
            let encoder = JSONEncoder()
            let userData = try encoder.encode(currentUser)
            UserDefaults.standard.set(userData, forKey: currentUserKey)
        } catch {
            print("Error saving user data: \(error.localizedDescription)")
        }
    }
    
    // Load current user from UserDefaults
    private func loadCurrentUser() -> User? {
        guard let userData = UserDefaults.standard.data(forKey: currentUserKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let user = try decoder.decode(User.self, from: userData)
            return user
        } catch {
            print("Error loading user data: \(error.localizedDescription)")
            return nil
        }
    }
    @MainActor
    func loadUserToken() {
        let defaults = UserDefaults.standard
        print("Starting loadUserToken, current token: \(token)")
        
        // Check if we have a saved token and it's not expired
        if let savedToken = defaults.string(forKey: tokenKey),
           let expirationDate = defaults.object(forKey: tokenExpirationKey) as? Date,
           let savedEmail = defaults.string(forKey: userEmailKey),
           let savedUser = loadCurrentUser() {
            
            // Check if token is still valid
            if expirationDate > Date() {
                self.token = savedToken
                self.email = savedEmail
                self.currentUser = savedUser
                self.isLogin = true
                service.setSavedToken(savedToken: savedToken)
                print("Successfully loaded saved user data. Token: \(savedToken)..., User: \(savedUser)")
                
                // 使用 await 直接等待刷新完成
                Task {
                    await refreshUserData()
                }
            } else {
                print("Token expired")
                clearUserToken()
            }
        } else {
            print("No saved token found or missing data")
            clearUserToken()
        }
    }
    
    func saveUserToken() {
        let defaults = UserDefaults.standard
        
        // Save token and email
        defaults.set(token, forKey: tokenKey)
        defaults.set(email, forKey: userEmailKey)
        print("saving token: ",token)
        // Save current user data
        saveCurrentUser()
        
        // Set token expiration (e.g., 30 days from now)
        let expirationDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        defaults.set(expirationDate, forKey: tokenExpirationKey)
    }
    
    func clearUserToken() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: tokenKey)
        defaults.removeObject(forKey: tokenExpirationKey)
        defaults.removeObject(forKey: userEmailKey)
        defaults.removeObject(forKey: currentUserKey)  // Clear saved user data
        
        // Reset current state
        self.token = ""
        self.email = ""
        self.currentUser = nil
        self.isLogin = false
    }
    
    @MainActor
    private func refreshUserData() async {
        print("refreshUserData: ",token)
        if !token.isEmpty {
            let result = service.refreshUserData(token: token)
            if result == nil {  // 如果没有错误
                //self.currentUser = service.currentUser  // 更新当前用户
                self.token = service.token ?? ""
                self.isLogin = true
                saveCurrentUser()  // 保存更新后的用户数据
                saveUserToken()    // 确保token也被保存
                print("Successfully refreshed user data, currentUser: \(String(describing: self.currentUser?.name))")
            } else {
                print("Failed to refresh user data: \(result?.localizedDescription ?? "")")
                clearUserToken()
            }
        }
    }
    
    func signOut() {
        clearUserToken()
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
