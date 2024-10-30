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
    
    init() {
        loadUserToken()
    }
    
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
    
    func loadUserToken() {
        let defaults = UserDefaults.standard
        
        // Check if we have a saved token and it's not expired
        if let savedToken = defaults.string(forKey: tokenKey),
           let expirationDate = defaults.object(forKey: tokenExpirationKey) as? Date,
           let savedEmail = defaults.string(forKey: userEmailKey),
           let savedUser = loadCurrentUser() {  // Load saved user data
            
            // Check if token is still valid
            if expirationDate > Date() {
                self.token = savedToken
                self.email = savedEmail
                self.currentUser = savedUser  // Restore user data
                self.isLogin = true
                
                // Optionally refresh user data
                Task {
                    await refreshUserData()
                }
            } else {
                // Token expired, clear saved data
                clearUserToken()
            }
        }
    }
    
    func saveUserToken() {
        let defaults = UserDefaults.standard
        
        // Save token and email
        defaults.set(token, forKey: tokenKey)
        defaults.set(email, forKey: userEmailKey)
        
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
        if !token.isEmpty {
            let result =  service.refreshUserData(token: token)
            if let err = result {
                saveCurrentUser()  // Save updated user data
                self.isLogin = true
                self.token = service.token!
            } else {
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
