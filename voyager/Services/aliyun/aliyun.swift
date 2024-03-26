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

open class AliyunClient {
    public static func createClient(_ accessKeyId: String?, _ accessKeySecret: String?) throws -> AlibabacloudNAS20170626.Client {
        let config: AlibabacloudOpenApi.Config = AlibabacloudOpenApi.Config([
            "accessKeyId": accessKeyId!,
            "accessKeySecret": accessKeySecret!
        ])
        config.endpoint = "nas.cn-hangzhou.aliyuncs.com"
        return try AlibabacloudNAS20170626.Client(config)
    }
    
    public static func UploadImage(){
        
    }
    
    public static func DownloadImage(){
        
    }
    
    public static func UploadVideo(){
        
    }
    
    public static func DownloadVideo(){
        
    }
}
