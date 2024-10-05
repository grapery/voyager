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
var token : String?

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
    public func Login(account: String, password: String) async throws -> Common_LoginResponse {
        do {
            let authClient = Common_TeamsApiClient(client: self.client!)
            // Performed within an async context.
            let request = Common_LoginRequest.with {
                $0.account = account
                $0.password = password
            }
            let resp = await authClient.login(request: request, headers: [:])
            print("resp \(resp)")
            
            guard let message = resp.message, !message.token.isEmpty else {
                throw NSError(domain: "LoginError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Login failed: Empty token"])
            }
            
            token = message.token
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
            header[GrpcGatewayCookie] = ["\(token!)"]
            resp = await authClient.userInfo(request: request, headers:header)
            result = resp.message!.info
        }
        return result
    }
    
    public func RefreshToken(curToken: String) async throws -> String{
        return ""
    }
    
    public func Logout() async throws ->Common_LogoutResponse{
        var resp: ResponseMessage<Common_LogoutResponse>
        let result = Common_LogoutResponse()
        do{
            let authClient = Common_TeamsApiClient(client: self.client!)
            // Performed within an async context.
            let request = Common_LogoutRequest.with {
                $0.token = token!
            }
            var header = Connect.Headers()
            header[GrpcGatewayCookie] = ["\(token!)"]
            resp = await authClient.logout(request: request, headers: header)
            print("resp \(resp)")
        }
        return result
    }
}

