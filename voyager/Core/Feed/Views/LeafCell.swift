//
//  ThreadCell.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI
import Kingfisher

struct LeafCell: View {
    let leaves: LeafItem
    init(info: Common_ItemInfo) {
        self.leaves = LeafItem(info: info)
    }
    var body: some View {
        HStack {
            VStack {
                Text(leaves.title).font(.headline)
                if let avator = leaves.avator {
                    CircularProfileImageView(avatarUrl: avator, size: .leaf)
                }
                Section{
                    Rectangle()
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .foregroundColor(.secondary)
                    
                    ZStack{
                        Image("Harry")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                            .clipShape(Circle())
                            .offset(x: 0, y: 30)
                        Image("Draco")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25)
                            .clipShape(Circle())
                            .offset(x: -15, y: 10)
                        Image("Ron")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30)
                            .clipShape(Circle())
                            .offset(x: 15, y: 5)
                    }
                }
            }
            .padding(8)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(leaves.title)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("2h")
                        .foregroundColor(.secondary)
                    
                    Button() {
                        
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .foregroundColor(.primary)
                }
                
                
                Text(leaves.text ?? "")
                  
                if let threadImage = leaves.imageUrl {
                    
                    KFImage(URL(string: threadImage))
                        .resizable()
                        .scaledToFit()
                }
                
                HStack {
                    Button {
                        
                    } label: {
                        Image(systemName: "heart")
                    }
                    Button {
                        
                    } label: {
                        Image(systemName: "bubble.right")
                    }
                    Button {
                        
                    } label: {
                        Image(systemName: "arrow.2.squarepath")
                    }
                    Button {
                        
                    } label: {
                        Image(systemName: "paperplane")
                    }
                    
                }
                .foregroundColor(.primary)
                
                
                HStack {
                    Text("\(leaves.replies) replies")
                    Text("\(leaves.likes) likes")
                    Text("")
                }
                .foregroundColor(.secondary)

            }
            .padding(.trailing)
            .padding(.top)
            
        }
        .fixedSize(horizontal: false, vertical: true)
        
    }
}
