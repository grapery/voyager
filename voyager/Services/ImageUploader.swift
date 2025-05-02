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
    if url!.isEmpty {
        return ""
    }
    
    // 根据场景获取对应的图片规格
    let spec: ImageSpec
    switch scene {
    case .small:
        spec = .fixedWidth(200)  // 小图使用200宽度，自适应高度
    case .thumbnail:
        spec = .fixedScale(width: 400, height: 300)  // 缩略图使用400x300比例
    case .preview:
        spec = .fixedWidth(800)  // 预览图使用800宽度，自适应高度
    case .content:
        spec = .fixedWidth(1200)  // 内容图使用1200宽度，自适应高度
    case .original:
        spec = .original  // 原始图不做处理
    }
    
    // 使用自定义规格或场景默认规格
    let finalSpec = customSpec ?? spec
    
    // 如果是原始图且没有其他处理参数，直接返回原始URL
    if case .original = finalSpec, case .original = format, quality == nil {
        return url!
    }
    
    // 构建处理参数数组
    var processes: [String] = []
    
    // 添加规格处理参数
    if finalSpec.processParam.isEmpty == false {
        processes.append(finalSpec.processParam)
    }
    
    // 添加格式转换参数
    if format.processParam.isEmpty == false {
        processes.append(format.processParam)
    }
    
    // 添加质量参数
    if let quality = quality {
        processes.append(quality.processParam)
    }
    
    // 如果没有处理参数，返回原始URL
    if processes.isEmpty {
        return url!
    }
    
    // 组合所有处理参数
    let finnalUrl = url! + "?x-oss-process=image/" + processes.joined(separator: "/")
    // AliyunClient.ProcessAndStoreImageByHTTP(objectUrl: url!, scene: scene, completion: {
    //     success, targetObject in
    //     if success {
    //         print("convert success: ",url as Any)
    //     } else {
    //         print("convert failed: ",url as Any)
    //     }
    // })
    let objectUrl = url // 你的 OSS object key
    var results: [ImageScene: String] = [:]
    let group = DispatchGroup()
    
    for scene in ImageScene.allCases {
        group.enter()
        AliyunClient.ProcessAndStoreImageByHTTP(objectUrl: objectUrl!, scene: scene) { success, targetObject in
            if success, let path = targetObject {
                results[scene] = path
                print("scene \(scene): \(path)")
            } else {
                print("scene \(scene) convert failed")
            }
            group.leave()
        }
    }

    // 等待所有异步任务完成
    group.notify(queue: .main) {
        print("所有scene处理完成，结果：\(results)")
        // 你可以在这里使用 results 字典
    }
    return finnalUrl
}

