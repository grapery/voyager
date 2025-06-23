import SwiftUI
import Kingfisher
import ActivityIndicatorView

struct AllGroupsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: GroupViewModel
    @State private var selectedTab = "关注的小组"
    @State private var searchText = ""
    private let tabs = ["关注的小组","创建的小组"]
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color.theme.primaryText)
                }
                Spacer()
                if viewModel.user.avatar.isEmpty {
                    KFImage(URL(string: convertImagetoSenceImage(url: defaultAvator, scene: .small)))
                        .cacheMemoryOnly().fade(duration: 0.25).resizable().scaledToFill()
                        .frame(width: 40, height: 40).clipShape(Circle())
                } else {
                    KFImage(URL(string: convertImagetoSenceImage(url: viewModel.user.avatar, scene: .small)))
                        .cacheMemoryOnly().fade(duration: 0.25).resizable().scaledToFill()
                        .frame(width: 40, height: 40).clipShape(Circle())
                }
                Text("\(self.viewModel.user.name)的小组")
                    .font(.headline)
                    .foregroundColor(Color.theme.primaryText)
                    .lineLimit(1)
                Spacer()
            }
            .padding()

            TabBarView(selectedTab: $selectedTab, tabs: tabs)

            GroupSearchBar(searchText: $searchText)
                .padding(.vertical, 8)

            // TabView Content
            TabView(selection: $selectedTab) {
                ForEach(tabs, id: \.self) { tab in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.groups) { group in
                                GroupListItemView(group: group, viewModel: viewModel)
                                if group.id != viewModel.groups.last?.id {
                                    Divider().background(Color.clear)
                                }
                            }
                            if !viewModel.groups.isEmpty && viewModel.hasMorePages {
                                LoadMoreView(isLoading: $isLoading)
                                    .onAppear { Task { await loadMoreGroups() } }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .tag(tab)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color.theme.secondaryBackground) // Use white background
        .navigationBarHidden(true)
    }

    private func loadMoreGroups() async {
        guard !isLoading else { return }
        isLoading = true
        await viewModel.fetchMoreGroups()
        isLoading = false
    }
}

// Search Bar
struct GroupSearchBar: View {
    @Binding var searchText: String
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.gray)
            TextField("搜索小组", text: $searchText).foregroundColor(.primary)
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.theme.background) // Light gray background
        .clipShape(Capsule())
        .padding(.horizontal, 16)
    }
}

// List Item View
struct GroupListItemView: View {
    let group: BranchGroup
    let viewModel: GroupViewModel
    @State private var showGroupDetail = false

    var body: some View {
        Button(action: { showGroupDetail = true }) {
            HStack(spacing: 12) {
                KFImage(URL(string: convertImagetoSenceImage(url: group.info.avatar, scene: .small)))
                    .cacheMemoryOnly().fade(duration: 0.25).resizable().scaledToFill()
                    .frame(width: 52, height: 52).clipShape(Circle())

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(group.info.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        Spacer()
                        Text(formatDate(group.info.mtime))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(group.info.desc)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 16) {
                        GroupStatLabel(title: "成员", count: Int(group.info.profile.groupMemberNum), icon: "person.2")
                        GroupStatLabel(title: "故事", count: Int(group.info.profile.groupStoryNum), icon: "doc.text")
                        GroupStatLabel(title: "关注者", count: Int(group.info.profile.groupFollowerNum), icon: "person.2")
                    }
                }
            }
            .padding(12)
            .background(Color.theme.background) // Light gray background
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showGroupDetail) {
             GroupDetailView(user: self.viewModel.user, group: group)
        }
    }
    
    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")

        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
            return "今天 \(formatter.string(from: date))"
        } else if Calendar.current.isDateInYesterday(date) {
            formatter.dateFormat = "HH:mm"
            return "昨天 \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "MM-dd HH:mm"
            return formatter.string(from: date)
        }
    }
}

// Stat Label
struct GroupStatLabel: View {
    let title: String
    var count: Int? = nil
    var text: String? = nil
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            if let count = count {
                Text("\(count)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}

// Tab Bar
struct TabBarView: View {
    @Binding var selectedTab: String
    let tabs: [String]

    var body: some View {
        HStack(spacing: 30) {
            ForEach(tabs, id: \.self) { tab in
                Button(action: {
                    withAnimation { selectedTab = tab }
                }) {
                    VStack(spacing: 8) {
                        Text(tab)
                            .font(.system(size: 15, weight: selectedTab == tab ? .medium : .regular))
                            .foregroundColor(selectedTab == tab ? .primary : .secondary)
                        
                        Rectangle()
                            .frame(width: 30, height: 2)
                            .foregroundColor(selectedTab == tab ? .blue : .clear)
                    }
                }
            }
        }
        .padding(.horizontal)
        .frame(height: 44)
    }
}

// 加载更多视图组件
struct LoadMoreView: View {
    @Binding var isLoading: Bool
    
    var body: some View {
        HStack {
            ActivityIndicatorView(isVisible: $isLoading, type: .growingArc(Color.theme.accent))
                .frame(width: 64, height: 64)
                .foregroundColor(Color.theme.accent)
        }
        .frame(height: 50)
    }
}
