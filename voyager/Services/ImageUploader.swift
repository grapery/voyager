//
//  ImageUploader.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import UIKit
import NIO
import Connect

enum ImageUploadError: Error {
    case invalidImage
    case compressionFailed
    case rpcError(Error)
    case invalidResponse
}

extension APIClient {
    func uploadImage(image: UIImage, filename: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ImageUploadError.compressionFailed
        }
        // 假设我们有一个gRPC服务定义了上传图片的方法
        let request = Common_UploadImageRequest.with {
            $0.filename = filename
            $0.imageData = imageData
        }
        
        
        // 假设我们有一个gRPC客户端实例
        let apiClient = Common_TeamsApiClient(client: self.client!)
        var header = Connect.Headers()
        header[GrpcGatewayCookie] = ["\(globalUserToken!)"]
        let response = await apiClient.uploadImageFile(request: request, headers: header)
        if response.code.rawValue != 0 {
            return ""
        }
        let imageUrl = (response.message?.data.url)!
        print("upload image : ",response.message?.data as Any)
        return imageUrl
        
    }
    
    func downloadImage(url: String) async throws -> UIImage? {
        guard let imageURL = URL(string: url) else {
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: imageURL)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw ImageUploadError.invalidResponse
            }
            
            guard let image = UIImage(data: data) else {
                throw ImageUploadError.invalidImage
            }
            
            return image
        } catch {
            throw ImageUploadError.rpcError(error)
        }
    }
}
