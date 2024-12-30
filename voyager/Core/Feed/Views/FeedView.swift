//
//  FeedView.swift
//  voyager
//
//  Created by grapestree on 2023/11/16.
//

import SwiftUI
import Kingfisher

enum FeedType{
    case Groups
    case Story
    case StoryRole
}
    
// 获取用户的关注以及用户参与的故事，以及用户关注或者参与的小组的故事动态。不可以用户关注用户，只可以关注小组或者故事,以及故事的角色
struct FeedView: View {
    @StateObject var viewModel: FeedViewModel
    @State private var selectedTab: FeedType = .Groups
    @State private var searchText = ""
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: FeedViewModel(user: user))
    }
    
    // 定义标签页数组
    let tabs: [(type: FeedType, title: String)] = [
        (.Groups, "小组"),
        (.Story, "故事"),
        (.StoryRole, "角色")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部导航栏
                TopNavigationBar()
                
                // 搜索栏
                FeedSearchBar(text: $searchText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                
                // 分类标签
                CategoryTabs(selectedTab: $selectedTab, tabs: tabs)
                    .padding(.vertical, 8)
                
                // 内容列表
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(0..<10) { _ in
                            FeedItemCard()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color(hex: "1C1C1E"))
            }
            .background(Color(hex: "1C1C1E"))
            .navigationBarHidden(true)
        }
    }
}

// 顶部导航栏
private struct TopNavigationBar: View {
    var body: some View {
        HStack(spacing: 20) {
            Text("最新动态")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            Text("发现")
                .font(.system(size: 17))
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "2C2C2E"))
    }
}

// 搜索栏
private struct FeedSearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            TextField("搜索", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(8)
            
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.trailing, 8)
        }
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(20)
    }
}

// 分类标签
private struct CategoryTabs: View {
    @Binding var selectedTab: FeedType
    let tabs: [(type: FeedType, title: String)]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(tabs, id: \.type) { tab in
                    Button(action: { selectedTab = tab.type }) {
                        Text(tab.title)
                            .font(.system(size: 14))
                            .foregroundColor(selectedTab == tab.type ? .black : .gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedTab == tab.type ? Color(hex: "A5D661") : Color(hex: "2C2C2E"))
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// Feed 内容卡片
private struct FeedItemCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 左侧绿色装饰条
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color(hex: "A5D661").opacity(0.3))
                    .frame(width: 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    // 标题和头像
                    HStack {
                        Text("蓝雀")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        KFImage(URL(string: defaultAvator)) // 替换为实际头像
                            .resizable()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    }
                    
                    // 内容
                    Text("欢迎大家来一起创作好玩的故事吧！")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    // 底部统计
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left")
                            Text("10")
                        }
                        .foregroundColor(.gray)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "heart")
                            Text("10")
                        }
                        .foregroundColor(.gray)
                        
                        // 参与者头像
                        HStack(spacing: -8) {
                            ForEach(0..<3) { _ in
                                KFImage(URL(string: defaultAvator)) 
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color(hex: "2C2C2E"), lineWidth: 2)
                                    )
                            }
                        }
                        .padding(.leading, 8)
                    }
                    .font(.system(size: 14))
                }
                .padding(12)
            }
        }
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(8)
    }
}
