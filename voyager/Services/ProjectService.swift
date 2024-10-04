//
//  ProjectService.swift
//  voyager
//
//  Created by grapestree on 2023/12/5.
//

import Foundation
import Connect

extension APIClient {
    // ptype: create/transfer/owned
    func getUserProjects(userId: Int64,offset: Int64,size: Int64,ptype: Int32,filter: [String]) async  -> ([Project],Int64,Int64) {
        var resp: ResponseMessage<Common_GetProjectListResponse>
        var result = Common_GetProjectListResponse()
        do{
            let projectClient = Common_TeamsApiClient(client: self.client!)
            // Performed within an async context.
            let request = Common_GetProjectListRequest.with {
                $0.userID = userId
            }
            resp = await projectClient.getProjectList(request: request, headers: [:])
            result = resp.message!
        }
        let ret = result.list
        return (ret,result.offset,result.pageSize)
    }
    
    func getProjectInfo(userId: Int64,projectId: Int64) async  -> Project {
        var resp: ResponseMessage<Common_GetProjectResponse>
        var result = Common_GetProjectResponse()
        do{
            let projectClient = Common_TeamsApiClient(client: self.client!)
            // Performed within an async context.
            let request = Common_GetProjectRequest.with {
                $0.projectID = projectId;
                $0.userID = userId
            }
            resp = await projectClient.getProjectInfo(request: request, headers: [:])
            result = resp.message!
        }
        return result.info
    }
    
    func getProjectProfile(userId: Int64,projectId: Int64) async  -> ProjectProfile {
        var resp: ResponseMessage<Common_GetProjectProfileResponse>
        var result = Common_GetProjectProfileResponse()
        do{
            let projectClient = Common_TeamsApiClient(client: self.client!)
            // Performed within an async context.
            let request = Common_GetProjectProfileRequest.with {
                $0.projectID = projectId;
                $0.userID = userId
            }
            resp = await projectClient.getProjectProfile(request: request, headers: [:])
            result = resp.message!
        }
        return result.info
    }
    
    func UpdateProjectProfile(userId: Int64,projectId: Int64,profile: ProjectProfile) async  -> ProjectProfile {
        return ProjectProfile()
    }
    
    func getUserWatchingProject(uid: UInt64,offset: Int64,size: Int64) async  -> [Project] {
        let items: [Project] = []
        return items
    }
    
    func getProjectJoinedUsers(projectId: Int64,filter: [String])async -> ([User],Int64,Int64){
        var resp: ResponseMessage<Common_GetProjectMembersResponse>
        var result = Common_GetProjectMembersResponse()
        do{
            let projectClient = Common_TeamsApiClient(client: self.client!)
            // Performed within an async context.
            let request = Common_GetProjectMembersRequest.with {
                $0.projectID = Int32(projectId);
            }
            resp = await projectClient.getProjectMembers(request: request, headers: [:])
            result = resp.message!
        }
        let ret = result.data.list
        return (ret,Int64(result.data.total),Int64(result.data.total))
    }
    
    func UnWatchingProject(uid: UInt64,offset: Int64,size: Int64) async  {
        return
    }
    
    func CreateProject(userId: Int64,name: String) async  -> Project {
        return Project()
    }
    
    func ArchiveProject(projectId: Int64,userId: Int64) async  {
        return
    }
    
    func CreateTimelineForProject(userId: Int64,projectId: Int64,currentId: Int64) async ->TimeLineBranch{
        let info = Common_TimeLine()
        return TimeLineBranch(info: info)
    }
    
    
    
    func CloseProject(projectId: Int64,userId: Int64) async   {
        return
    }
    
    func DeleteProject(projectId: Int64,userId: Int64) async   {
        return
    }
    
}
