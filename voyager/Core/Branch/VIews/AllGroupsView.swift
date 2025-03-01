import SwiftUI
import Kingfisher

struct AllGroupsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: GroupViewModel
    @State private var selectedTab = "关注的小组"
    @State private var searchText = ""
    private let tabs = ["关注的小组","创建的小组"]
    
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
            
            // 搜索栏
            GroupSearchBar(searchText: $searchText)
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            // 使用TabView替换ScrollView来支持滑动切换
            TabView(selection: $selectedTab) {
                ForEach(tabs, id: \.self) { tab in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.groups) { group in
                                GroupListItemView(group: group, viewModel: viewModel)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .tag(tab)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color(hex: "1C1C1E"))
        }
        .navigationBarHidden(true)
    }
}

// 搜索栏组件
struct GroupSearchBar: View {
    @Binding var searchText: String
    
    var body: some View {
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
    }
}

// 列表项视图
struct GroupListItemView: View {
    let group: BranchGroup
    let viewModel: GroupViewModel
    @State private var showGroupDetail = false
    
    var body: some View {
        Button(action: { showGroupDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {
                // 头部：头像和名称
                HStack(spacing: 12) {
                    // 小组头像
                    KFImage(URL(string: group.info.avatar))
                        .placeholder {
                            Image(systemName: "person.2.circle.fill")
                                .resizable()
                                .foregroundColor(.gray)
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.info.name)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                        
                        Text(formatDate(group.info.mtime))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                // 小组描述
                Text(group.info.desc)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                // 统计信息
                HStack(spacing: 16) {
                    GroupStatLabel(title: "成员", count: 10, icon: "person.2.fill")
                    GroupStatLabel(title: "故事", count: 10, icon: "doc.text.fill")
                    GroupStatLabel(title: "活跃", text: formatTimeAgo(group.info.mtime), icon: "clock.fill")
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.95))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .fullScreenCover(isPresented: $showGroupDetail) {
            NavigationStack {
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
    
    // 格式化日期
    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let now = Date()
        let calendar = Calendar.current
        
        // 获取日期组件
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now))
        let daysAgo = components.day ?? 0
        
        // 创建日期格式化器
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN") // 使用中文locale
        
        switch daysAgo {
        case 0: // 今天
            formatter.dateFormat = "HH:mm"
            return "今天 " + formatter.string(from: date)
            
        case 1: // 昨天
            formatter.dateFormat = "HH:mm"
            return "昨天 " + formatter.string(from: date)
            
        case 2...7: // 最近一周
            formatter.dateFormat = "EEEE HH:mm" // EEEE 表示星期几的全称
            return formatter.string(from: date)
            
        default: // 更早的日期
            formatter.dateFormat = "MM-dd HH:mm"
            let yearComponents = calendar.dateComponents([.year], from: date, to: now)
            if yearComponents.year ?? 0 > 0 {
                formatter.dateFormat = "yyyy-MM-dd HH:mm"
            }
            return formatter.string(from: date)
        }
    }
    
    // 格式化时间间隔
    private func formatTimeAgo(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day)天前"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)小时前"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)分钟前"
        } else {
            return "刚刚"
        }
    }
}

// 新增统计标签组件
struct GroupStatLabel: View {
    let title: String
    var count: Int? = nil
    var text: String? = nil
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
            if let count = count {
                Text("\(count)")
                    .font(.system(size: 14))
            }
            if let text = text {
                Text(text)
                    .font(.system(size: 14))
            }
            Text(title)
                .font(.system(size: 14))
        }
        .foregroundColor(.gray)
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
                            .font(.system(size: 15))
                            .foregroundColor(selectedTab == tab ? .primary : .gray)
                            .padding(.bottom, 8)
                        
                        // 选中指示器
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedTab == tab ? .green : .clear)
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
