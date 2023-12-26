//
//  ProjectService.swift
//  voyager
//
//  Created by grapestree on 2023/12/5.
//

import Foundation

extension APIClient {
    // ptype: create/transfer/owned
    func getUserProjects(offset: Int64,size: Int64,ptype: Int32) async throws -> [Project] {
        let items: [Project] = []
        return items
    }
    
    func getProjectInfo(userId: Int64,projrctId: Int64) async throws -> Project {
        return Project()
    }
    
    func getProjectProfile(userId: Int64,projrctId: Int64) async throws -> ProjectProfile {
        return ProjectProfile()
    }
    
    func UpdateProjectProfile(userId: Int64,projrctId: Int64) async throws -> ProjectProfile {
        return ProjectProfile()
    }
    
    func getUserWatchingProject(uid: UInt64,offset: Int64,size: Int64) async throws -> [Project] {
        let items: [Project] = []
        return items
    }
    
    func UnWatchingProject(uid: UInt64,offset: Int64,size: Int64) async throws {
        return
    }
    
    func CreateProject(userId: Int64,name: String) async throws -> Project {
        return Project()
    }
    
    func ArchiveProject(projectId: Int64,userId: Int64) async throws {
        return
    }
    
    func CloseProject(projectId: Int64,userId: Int64) async throws  {
        return
    }
    
    func DeleteProject(projectId: Int64,userId: Int64) async throws  {
        return
    }
}
