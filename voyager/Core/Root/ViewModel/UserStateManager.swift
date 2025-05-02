//
//  UserStateManager.swift
//  voyager
//
//  Created by grapestree on 2024/3/31.
//

import Foundation
import SwiftUI

@MainActor
class UserStateManager: ObservableObject {
    static let shared = UserStateManager()
    
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    @Published var token: String = ""
    @Published var isLoading: Bool = true  // 添加加载状态
    
    // UserDefaults keys
    private let tokenKey = "VoyagerUserToken"
    private let tokenExpirationKey = "VoyagerTokenExpiration"
    private let userEmailKey = "VoyagerUserEmail"
    private let currentUserKey = "VoyagerCurrentUser"
    
    private init() {
        
    }
    
    // App 启动时调用的初始化方法
    func initialize() async {
        print("before initialize ",self.token,self.currentUser as Any)
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 1. 加载保存的 token
            loadUserToken()
            print("after load user token")
            // 2. 如果有 token，验证并刷新
            if !token.isEmpty {
                print("last token is exist",token as Any)
                if isTokenExpired() {
                    print("token is expired,尝试重新获取")
                    try await refreshToken()
                }
                
                // 3. 获取用户信息
                if let user = AuthService.shared.currentUser {
                    print("获取到的最新的用户信息：",user as Any)
                    setCurrentUser(user)
                } else {
                    print("获取的最新的用户信息为空，需要清理并重新登录")
                    clearUserToken()
                }
            } else {
                print("need clear user token")
                clearUserToken()
            }
        } catch {
            print("Initialization error: \(error.localizedDescription)")
            clearUserToken()
        }
        print("after initialize ",self.token,self.currentUser as Any)
    }
    
    // 获取有效的 token
    func getValidToken() async throws -> String {
        if token.isEmpty {
            throw AuthError.noToken
        }
        
        if isTokenExpired() {
            try await refreshToken()
        }
        
        return token
    }
    
    func setCurrentUser(_ user: User?) {
        self.currentUser = user
        self.isLoggedIn = user != nil
        if let user = user {
            saveCurrentUser(user)
        }
    }
    
    func setToken(_ token: String) {
        self.token = token
        print("setToken: ",token)
        saveUserToken(token)
    }
    
    func loadUserToken() {
        let defaults = UserDefaults.standard
        if let savedToken = defaults.string(forKey: tokenKey),
           let expirationDate = defaults.object(forKey: tokenExpirationKey) as? Date,

           let savedUser = loadCurrentUser() {
            print("savedToken: ",savedToken)
            print("expirationDate: ",expirationDate)
            print("savedUser: ",savedUser)
            print("tokenExpirationKey: ",tokenExpirationKey)
            if expirationDate > Date() {
                print("token not expired")
                self.token = savedToken
                self.currentUser = savedUser
                AuthService.shared.currentUser = savedUser
                AuthService.shared.token = savedToken
                globalUserToken = savedToken
                self.isLoggedIn = true
            } else {
                clearUserToken()
                print("token expired")
            }
        } else {
            print("token info not exist")
            clearUserToken()
        }
    }
    
    func logout() {
        clearUserToken()
    }
    
    // 判断是否是当前用户
    func isCurrentUser(_ userId: Int64) -> Bool {
        return currentUser?.userID == userId
    }
    
    // 检查用户是否有特定权限
    func hasPermission(_ permission: UserPermission) -> Bool {
        guard let currentUser = currentUser else { return false }
        
        switch permission {
        case .editProfile:
            return true // 用户可以编辑自己的资料
        case .createStory:
            return true // 所有登录用户都可以创建故事
        case .deleteStory(let storyUserId):
            return currentUser.userID == storyUserId // 只能删除自己的故事
        case .moderateComments:
            return false // 暂时没有评论管理权限
        }
    }
    
    // MARK: - Token Management
    
    func refreshToken() async throws {
        guard !token.isEmpty else { 
            throw AuthError.noToken
        }
        
        do {
            // 调用 AuthService 刷新 token
            let newToken: () = try await AuthService.shared.refreshUserData(token: token)
            if let refreshedToken = AuthService.shared.token {
                setToken(refreshedToken)
            } else {
                throw AuthError.refreshFailed
            }
        } catch {
            print("Failed to refresh token: \(error.localizedDescription)")
            clearUserToken()
            throw error
        }
    }
    
    func isTokenExpired() -> Bool {
        guard let expirationDate = UserDefaults.standard.object(forKey: tokenExpirationKey) as? Date else {
            return true
        }
        return expirationDate <= Date()
    }
    
    // MARK: - Private Methods
    
    private func saveCurrentUser(_ user: User) {
        do {
            let encoder = JSONEncoder()
            let userData = try encoder.encode(user)
            UserDefaults.standard.set(userData, forKey: currentUserKey)
        } catch {
            print("Error saving user data: \(error.localizedDescription)")
        }
    }
    
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
    
    private func saveUserToken(_ token: String) {
        print("saveUserToken: ",token)
        let defaults = UserDefaults.standard
        defaults.set(token, forKey: tokenKey)
        if let email = currentUser?.email {
            defaults.set(email, forKey: userEmailKey)
        }
        
        // Set token expiration (e.g., 30 days from now)
        let expirationDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        defaults.set(expirationDate, forKey: tokenExpirationKey)
    }
    
    private func clearUserToken() {
        print("clearUserToken")
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: tokenKey)
        defaults.removeObject(forKey: tokenExpirationKey)
        defaults.removeObject(forKey: userEmailKey)
        defaults.removeObject(forKey: currentUserKey)
        
        self.token = ""
        self.currentUser = nil
        self.isLoggedIn = false
    }
}

// 用户权限枚举
enum UserPermission {
    case editProfile
    case createStory
    case deleteStory(userId: Int64)
    case moderateComments
}

// 认证相关错误
enum AuthError: Error {
    case noToken
    case refreshFailed
    case invalidToken
    
    var localizedDescription: String {
        switch self {
        case .noToken:
            return "No token available"
        case .refreshFailed:
            return "Failed to refresh token"
        case .invalidToken:
            return "Invalid token"
        }
    }
}
