//
//  StoryRolesView.swift
//  voyager
//
//  Created by grapestree on 2024/9/24.
//

import SwiftUI
import Kingfisher
import Combine

struct StoryRolesView: View{
    @State var storyId: Int64
    @State var boardId: Int64
    @State var roles: [StoryRole]
    var body: some View{
        return VStack{}
    }
}

struct StoryRoleView: View{
    @State var storyId: Int64
    @State var boardId: Int64
    @State var role: StoryRole
    var body: some View{
        return VStack{
            
        }
    }
}
