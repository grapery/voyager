//
//  ImageUploader.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import UIKit

struct ImageUploader {
    
    static func uploadImage(image: UIImage) async throws -> String? {
//        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return nil }
//        
//        let filename = NSUUID().uuidString
//        let ref = Storage.storage().reference(withPath: "/profile_images/\(filename)")
//        
//        do {
//            let _ = try await ref.putDataAsync(imageData)
//            let url = try await ref.downloadURL()
//            return url.absoluteString
//        } catch {
//            print("DEBUG: Failed to upload image with error \(error.localizedDescription)")
//            return nil
//        }
        return ""
    }
    static func downloadImage(url: String) async throws -> UIImage?{
        return nil
    }
    
}
