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
                .padding(.top, 4)
            
            // 数量和搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("搜索小组", text: $searchText)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // 小组列表
            List {
                ForEach(viewModel.groups) { group in
                    GroupListItemView(group: group, viewModel: viewModel)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
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
    @State private var showGroupDetail = false
    
    var body: some View {
        Button(action: { showGroupDetail = true }) {
            HStack(spacing: 12) {
                // 优化头像显示
                KFImage(URL(string: group.info.avatar))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .overlay(
                        Text("999+")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(8)
                            .offset(x: 20, y: 20)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.info.name)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("最近更新: \(group.info.desc)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Menu {
                    Button("分享", action: {})
                    Button("设置", action: {})
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.vertical, 4)
        }
        .fullScreenCover(isPresented: $showGroupDetail) {
            NavigationView {
                GroupDetailView(user: self.viewModel.user, group: group)
                    .navigationBarItems(leading: Button(action: {
                        showGroupDetail = false
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    })
            }
        }
    }
}
