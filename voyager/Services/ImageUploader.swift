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

// 阿里云图片处理质量枚举
enum ImageQuality {
    case relative(Int)    // 相对质量 1-100
    case absolute(Int)    // 绝对质量 1-100
    
    var processParam: String {
        switch self {
        case .relative(let quality):
            return "quality,q_\(max(1, min(100, quality)))"
        case .absolute(let quality):
            return "quality,Q_\(max(1, min(100, quality)))"
        }
    }
}

// 阿里云图片处理格式枚举
enum ImageFormat {
    case jpg
    case png
    case webp
    case original
    
    var processParam: String {
        switch self {
        case .original:
            return ""
        default:
            return "format,\(self)"
        }
    }
}

// 图片使用场景枚举
enum ImageScene: CaseIterable {
    case small      // 小图
    case thumbnail  // 缩略图
    case preview    // 预览图
    case content    // 内容图
    case original   // 原始图
}


// 阿里云图片规格枚举
enum ImageSpec {
    case fixedWidth(Int)         // 固定宽度，高度自适应
    case fixedHeight(Int)        // 固定高度，宽度自适应
    case fixedSize(width: Int, height: Int)  // 固定尺寸
    case fixedScale(width: Int, height: Int) // 固定比例缩放
    case original                // 原始尺寸
    
    var processParam: String {
        switch self {
        case .fixedWidth(let width):
            return "resize,m_lfit,w_\(width)"
        case .fixedHeight(let height):
            return "resize,m_lfit,h_\(height)"
        case .fixedSize(let width, let height):
            return "resize,m_fill,h_\(height),w_\(width)"
        case .fixedScale(let width, let height):
            return "resize,m_lfit,h_\(height),w_\(width)"
        case .original:
            return ""
        }
    }
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


func convertImagetoSenceImage(
    url: String?,
    scene: ImageScene,
    format: ImageFormat = .original,
    quality: ImageQuality? = nil,
    customSpec: ImageSpec? = nil
) -> String {
    // 如果URL为空，返回空字符串
    guard let url = url, !url.isEmpty else { return "" }
    print("[convertImagetoSenceImage] 原始URL: \(url)")
    // 根据 scene 参数拼接不同后缀
    let formatSuffix: String
    switch scene {
    case .content:    formatSuffix = "_content"
    case .preview:    formatSuffix = "_preview"
    case .small:      formatSuffix = "_small"
    case .thumbnail:  formatSuffix = "_thumbnail"
    case .original:   print("[convertImagetoSenceImage] 处理后URL: \(url)"); return url // 原图直接返回
    }
    // 在扩展名前插入后缀
    let resultUrl: String
    if let dotRange = url.range(of: ".", options: .backwards) {
        let prefix = url[..<dotRange.lowerBound]
        let ext = url[dotRange.lowerBound...] // 包含点
        resultUrl = "\(prefix)\(formatSuffix)\(ext)"
    } else {
        // 没有扩展名，直接拼接
        resultUrl = url + formatSuffix
    }
    print("[convertImagetoSenceImage] 处理后URL: \(resultUrl)")
    return resultUrl
}

