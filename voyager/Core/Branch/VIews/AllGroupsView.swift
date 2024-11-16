import SwiftUI
import Kingfisher

struct AllGroupsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: GroupViewModel
    @State private var selectedTab = "我的小组"
    @State private var searchText = ""
    private let tabs = ["我的小组", "关注", "参与"]
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部头像和标题
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
                
                Spacer().scaledToFit()
                if viewModel.user.avatar.isEmpty {
                    KFImage(URL(string: defaultAvator))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                }else{
                    KFImage(URL(string: viewModel.user.avatar))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                }
                
                
                Text("葡萄树的小组")
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer().scaledToFit()
            }
            .padding()
            
            // 主要标签栏
            TabBarView(selectedTab: $selectedTab, tabs: tabs)
            
            // 数量和搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("搜索小组", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()
            
            // 小组列表
            List {
                ForEach(viewModel.groups) { group in
                    GroupListItemView(group: group, viewModel: viewModel)
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationBarHidden(true)
    }
}

// 自定义标签栏
struct TabBarView: View {
    @Binding var selectedTab: String
    let tabs: [String]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 30) {
                ForEach(tabs, id: \.self) { tab in
                    VStack {
                        Text(tab)
                            .foregroundColor(selectedTab == tab ? .primary : .gray)
                            .padding(.bottom, 8)
                        
                        // 选中指示器
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedTab == tab ? .black : .clear)
                    }
                    .onTapGesture {
                        withAnimation {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            Divider()
        }
    }
}

// 列表项视图
struct GroupListItemView: View {
    let group: BranchGroup
    let viewModel: GroupViewModel
    
    var body: some View {
        NavigationLink(destination: GroupDetailView(user: viewModel.user, group: Binding(
            get: { group },
            set: { _ in }
        ))) {
            HStack(spacing: 1) {
                // 小组头像
                KFImage(URL(string: group.info.avatar))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(
                        Text("999+")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 1)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.6))
                            .cornerRadius(8)
                            .offset(x: 30, y: 30)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.info.name)
                        .font(.headline)
                    
                    Text("最近更新: \(group.info.desc)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 更多按钮
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 8)
        }
    }
} 
