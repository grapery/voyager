//
//  aliyun.swift
//  voyager
//
//  Created by grapestree on 2023/11/18.
//

import Foundation
import Tea
import AlibabacloudNAS20170626
import AlibabacloudOpenApi
import TeaUtils
import UIKit
import PhotosUI
import CryptoKit

open class AliyunClient {
    
    /*
     GET /oss.jpg HTTP/1.1
     Host: oss-example.oss-cn-hangzhou.aliyuncs.com
     Date: Fri, 24 Feb 2012 06:38:30 GMT
     Authorization: OSS qn6q**************:77Dv****************
    */
    // 参考如上注释，构造http 请求上传图片
    public static func UploadImage(image: UIImage) throws -> String{
        // 配置 OSS 参数
        let endpoint = "oss-cn-shanghai.aliyuncs.com"
        let bucketName = "grapery-dev"
        let accessKeyId = "LTAI5t9opRTB3NKb3nBiikx5"
        let accessKeySecret = "YxeCMpnWeY82KLnElGVNaNZ4RdMJuI"
        
        // 生成唯一的文件名
        let fileName = UUID().uuidString + ".jpg"
        let objectKey =  fileName
        
        // 准备图片数据
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "AliyunOSS", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        // 构造请求 URL
        let urlString = "https://\(bucketName).\(endpoint)/\(objectKey)"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "AliyunOSS", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // 准备请求头
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        let date = formatter.string(from: Date())
        let contentType = "image/jpeg"
        
        // 构造签名字符串
        let stringToSign = "PUT\n\n\(contentType)\n\(date)\n/\(bucketName)/\(objectKey)"
        
        // 计算签名
        let signature = try computeSignature(stringToSign: stringToSign, secretKey: accessKeySecret)
        let authorization = "OSS \(accessKeyId):\(signature)"
        print("stringToSign: ",stringToSign)
        print("signature: ",signature)
        print("authorization : ",authorization)
        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(date, forHTTPHeaderField: "Date")
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        request.httpBody = imageData
        print("request: ",request)
        // Create semaphore for synchronous request
        let semaphore = DispatchSemaphore(value: 0)
        var uploadError: Error?
        
        // Send the request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                uploadError = error
                semaphore.signal()
                print("URLSession.shared.dataTask")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                uploadError = NSError(domain: "AliyunOSS", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                semaphore.signal()
                print("AliyunOSS error: Invalid response")
                return
            }
            
            // Check response status code
            guard (200...299).contains(httpResponse.statusCode) else {
                uploadError = NSError(domain: "AliyunOSS", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error: \(httpResponse.statusCode)"])
                semaphore.signal()
                print("AliyunOSS error: ",httpResponse as Any)
                return
            }
            
            semaphore.signal()
        }
        
        // Start the task
        task.resume()
        
        // Wait for completion
        _ = semaphore.wait(timeout: .now() + 30) // 30 second timeout
    
        // Handle any errors
        if let error = uploadError {
            print("upload error: ",error)
            throw error
        }
        // 返回完整的访问 URL
        return urlString
    }
    
    // 辅助函数：计算签名
    private static func computeSignature(stringToSign: String, secretKey: String) throws -> String {
        guard let stringData = stringToSign.data(using: .utf8),
              let keyData = secretKey.data(using: .utf8) else {
            throw NSError(domain: "AliyunOSS", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid string encoding"])
        }
        
        // 使用 HMAC-SHA1 计算签名
        let key = SymmetricKey(data: keyData)
        let signature = HMAC<Insecure.SHA1>.authenticationCode(for: stringData, using: key)
        
        // 转换为 Base64 字符串
        return Data(signature).base64EncodedString()
    }
    
    // 使用aliyun oss下载图片
    public static func DownloadImage(imageUrl: String) throws -> UIImage {
    // 解析 URL
    guard let url = URL(string: imageUrl) else {
        throw NSError(domain: "AliyunOSS", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
    }
    
    // 配置 OSS 参数
    let accessKeyId = "LTAI5t9opRTB3NKb3nBiikx5"
    let accessKeySecret = "YxeCMpnWeY82KLnElGVNaNZ4RdMJuI"
    
    // 准备请求头
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
    formatter.timeZone = TimeZone(abbreviation: "GMT")
    let date = formatter.string(from: Date())
    
    // 构造签名字符串
    let stringToSign = "GET\n\n\n\(date)\n\(url.path)"
    
    // 计算签名
    let signature = try computeSignature(stringToSign: stringToSign, secretKey: accessKeySecret)
    let authorization = "OSS \(accessKeyId):\(signature)"
    
    // 创建请求
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(date, forHTTPHeaderField: "Date")
    request.setValue(authorization, forHTTPHeaderField: "Authorization")
    
    // 创建信号量用于同步请求
    let semaphore = DispatchSemaphore(value: 0)
    var resultImage: UIImage?
    var resultError: Error?
    
    // 发起请求
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        if let error = error {
            resultError = error
            semaphore.signal()
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            resultError = NSError(domain: "AliyunOSS", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            semaphore.signal()
            return
        }
        
        // 检查响应状态码
        guard (200...299).contains(httpResponse.statusCode) else {
            resultError = NSError(domain: "AliyunOSS", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error: \(httpResponse.statusCode)"])
            semaphore.signal()
            return
        }
        
        // 确保有数据返回
        guard let imageData = data else {
            resultError = NSError(domain: "AliyunOSS", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
            semaphore.signal()
            return
        }
        
        // 转换数据为图片
        if let image = UIImage(data: imageData) {
            resultImage = image
        } else {
            resultError = NSError(domain: "AliyunOSS", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        }
        
        semaphore.signal()
    }
    
    // 开始任务
    task.resume()
    
    // 等待完成
    _ = semaphore.wait(timeout: .now() + 30) // 30秒超时
    
    // 处理结果
    if let error = resultError {
        throw error
    }
    
    guard let image = resultImage else {
        throw NSError(domain: "AliyunOSS", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to download image"])
    }
    
    return image
}
}
