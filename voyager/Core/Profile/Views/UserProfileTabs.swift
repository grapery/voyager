import SwiftUI
import Kingfisher

// MARK: - Stories Tab
struct StoriesTab: View {
    @ObservedObject var viewModel: ProfileViewModel
    let isLoading: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if viewModel.storyboards.isEmpty {
                    EmptyStateView(
                        image: "doc.text",
                        title: "还没有故事",
                        message: "开始创作你的第一个故事吧"
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(viewModel.storyboards) { board in
                        StoryboardCell(board: board)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.top, 16)
        }
        .background(Color.theme.background)
    }
}

// MARK: - Roles Tab
struct RolesTab: View {
    @ObservedObject var viewModel: ProfileViewModel
    let isLoading: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if viewModel.storyRoles.isEmpty {
                    EmptyStateView(
                        image: "person.circle",
                        title: "还没有角色",
                        message: "创建你的第一个角色吧"
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(viewModel.storyRoles) { role in
                        ProfileRoleCell(role: role, viewModel: viewModel)
                    }
                }
            }
            .padding(.top, 16)
        }
        .background(Color.theme.background)
    }
}

// MARK: - Story Board Cell
struct StoryboardCell: View {
    let board: StoryBoard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {    
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(board.boardInfo.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.theme.primaryText)
                    
                    Spacer()
                    
                    Text(formatDate(board.boardInfo.ctime))
                        .font(.system(size: 13))
                        .foregroundColor(Color.theme.tertiaryText)
                }
                
                Text(board.boardInfo.content)
                    .font(.system(size: 15))
                    .foregroundColor(Color.theme.secondaryText)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 24) {
                    StatLabel(icon: "bubble.left.fill", count: 10)
                    StatLabel(icon: "heart.fill", count: 10)
                    StatLabel(icon: "arrow.triangle.2.circlepath", count: 10)
                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
        }
        .background(Color.theme.secondaryBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.theme.border, lineWidth: 0.5)
        )
    }
    
    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Profile Role Cell
struct ProfileRoleCell: View {
    let role: StoryRole
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showRoleDetail = false
    
    var body: some View {
        Button(action: { showRoleDetail = true }) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    KFImage(URL(string: role.role.characterAvatar.isEmpty ? defaultAvator : role.role.characterAvatar))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(role.role.characterName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.theme.primaryText)
                        
                        Text(role.role.characterDescription)
                            .font(.system(size: 14))
                            .foregroundColor(Color.theme.secondaryText)
                            .lineLimit(2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                    .background(Color.theme.divider)
            }
            .background(Color.theme.background)
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showRoleDetail) {
            NavigationStack {
                StoryRoleDetailView(
                    storyId: role.role.storyID,
                    roleId: role.role.roleID,
                    userId: viewModel.user?.userID ?? 0,
                    role: role
                )
                .navigationBarItems(leading: Button(action: {
                    showRoleDetail = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(Color.theme.primaryText)
                })
            }
        }
    }
}

// MARK: - Stat Label
struct StatLabel: View {
    let icon: String
    let count: Int
    var iconColor: Color = Color.theme.tertiaryText
    var countColor: Color = Color.theme.tertiaryText
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(iconColor)
            Text("\(count)")
                .font(.system(size: 13))
                .foregroundColor(countColor)
        }
    }
} 