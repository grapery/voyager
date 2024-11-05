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
    func login(withEmail email: String, password: String) async -> (Int64, Error?) {
        do {
            let result = try await APIClient.shared.Login(account: email, password: password)
            if result.token.isEmpty {
                return (-1, NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "登录失败：令牌为空"]))
            }
            self.token = result.token
            self.currentUser = try await APIClient.shared.GetUserInfo(userId: result.userID)
            print("user \(String(describing: self.currentUser))")
            return (0, nil) // 成功登录
        } catch  {
            print("Unexpected login error: \(error)")
            return (-1, error)
        }
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
    @MainActor
    func signout() async{
        // TODO： 删除本地缓存的token，然后和服务器交互、或者写入本地标记位需要重新登录
        if self.token == "" {
            return 
        }
        self.token = ""
        do {
            let result = try await APIClient.shared.Logout()
            print("logout result:\(result)")
        }catch {
            print("logout error")
        }
    }
    
    @MainActor
    func refreshUserData(token: String) -> Error?{
       // 程序自动和服务程序交互，刷新token
        var err :Error?
        Task{@MainActor in
            do {
                if self.token != "" {
                    let result = try await APIClient.shared.RefreshToken(curToken: token)
                    print("refresh new token: \(result)")
                    if result.2 != nil {
                        err = result.2
                        return
                    }
                    self.token = result.1
                    self.currentUser = try await APIClient.shared.GetUserInfo(userId: result.0)
                    print("user \(String(describing: self.currentUser))")
                    return
                }
            }catch{
                print("refresh token failed")
                return
            }
        }
        if err != nil{
            return err
        }
        return nil
    }
    
    @MainActor
    func register(account email: String,password: String,name: String,full_name: String) async  -> Int32{
        // 注册用户
        do {
            let result = try await APIClient.shared.Register(account: email, password: password, name: name)
            
            print("register result:\(result.code)")
            return result.code
        }catch{
            print("register error")
        }
        return -1
    }
}
