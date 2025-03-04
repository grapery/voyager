//
//  api.swift
//  voyager
//
//  Created by grapestree on 2023/11/18.
//

import OpenAPIRuntime
import OpenAPIURLSession
import Connect
import Foundation

let GrpcGatewayCookie = "grpcgateway-cookie"
var globalUserToken : String?

struct APIClient{
    // Instantiate your chosen transport library.
    var client : ProtocolClient?
    
    static let shared = APIClient()
    public init(){
        do{
            self.client = ProtocolClient(
                httpClient: URLSessionHTTPClient(),
                config: ProtocolClientConfig(
                    host: "http://127.0.0.1:12305",
                    networkProtocol: .connect, // Or .grpcWeb
                    codec: ProtoCodec()
                )
            )
        }
    }
    
    public func setGlobalToken(savedToken: String) {
        globalUserToken = savedToken
    }
    
    public func Login(account: String, password: String) async throws -> Common_LoginResponse {
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            // Performed within an async context.
            let request = Common_LoginRequest.with {
                $0.account = account
                $0.password = password
            }
            let resp = await authClient.login(request: request, headers: [:])
            
            guard let message = resp.message, !message.data.token.isEmpty else {
                throw NSError(domain: "LoginError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Login failed: Empty token"])
            }
            
            globalUserToken = message.data.token
            return message
        } catch {
            throw error
        }
    }
    
    public func Register(account: String,password: String,name: String) async throws -> Common_RegisterResponse{
        var resp: ResponseMessage<Common_RegisterResponse>
        var result = Common_RegisterResponse()
        do{
            let authClient = Common_TeamsApiClient(client: self.client!)
            // Performed within an async context.
            let request = Common_RegisterRequest.with {
                $0.account = account;
                $0.password = password;
                $0.name = name;
            }
            resp = await authClient.register(request: request, headers: [:])
            result.code = resp.message!.code
            result = resp.message!
        }
        return result
    }
    
    public func GetUserInfo(userId: Int64) async throws -> Common_UserInfo{
        var resp: ResponseMessage<Common_UserInfoResponse>
        var result = Common_UserInfo()
        do{
            let authClient = Common_TeamsApiClient(client: self.client!)
            // Performed within an async context.
            let request = Common_UserInfoRequest.with {
                $0.userID = userId;
                $0.account = ""
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            resp = await authClient.userInfo(request: request, headers:header)
            result = resp.message!.data.info
        }
        return result
    }
    
    public func RefreshToken(curToken: String) async throws -> (Int64,String,Error?){
        var resp: ResponseMessage<Common_RefreshTokenResponse>
        var result = Common_RefreshTokenResponse()
        do{
            let authClient = Common_TeamsApiClient(client: self.client!)
            // Performed within an async context.
            let request = Common_RefreshTokenRequest.with {
                $0.token = curToken
            }
            print("APICllient.RefreshToken: ",request)
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(curToken)"]
            resp = await authClient.refreshToken(request: request, headers: header)
            guard let message = resp.message, !message.token.isEmpty else {
                throw NSError(domain: "RefreshTokenError", code: 0, userInfo: [NSLocalizedDescriptionKey: "RefreshToken failed: Empty token"])
            }
            
            globalUserToken = message.token
            print("APIClient.RefreshToken globalUserToken: ",globalUserToken as Any)
            result.token = message.token
            result.userID = message.userID
        }
        return (result.userID,result.token,nil)
    }
    
    public func Logout() async throws ->Common_LogoutResponse{
        var resp: ResponseMessage<Common_LogoutResponse>
        let result = Common_LogoutResponse()
        do{
            let authClient = Common_TeamsApiClient(client: self.client!)
            // Performed within an async context.
            let request = Common_LogoutRequest.with {
                $0.token = globalUserToken!
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
            resp = await authClient.logout(request: request, headers: header)
            print("Logout resp \(resp)")
        }
        return result
    }
}

