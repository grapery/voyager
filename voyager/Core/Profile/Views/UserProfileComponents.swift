import SwiftUI
import Kingfisher
import PhotosUI
import ActivityIndicatorView


struct StoryboardActiveCell: View {
    let board: StoryBoardActive
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 主要内容
            VStack(alignment: .leading, spacing: 12) {
                // 标题行
                HStack {
                    Text(board.boardActive.storyboard.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.theme.primaryText)
                    
                    Spacer()
                    
                    Text(formatDate(board.boardActive.storyboard.ctime))
                        .font(.system(size: 13))
                        .foregroundColor(Color.theme.tertiaryText)
                }
                
                // 内容
                Text(board.boardActive.storyboard.content)
                    .font(.system(size: 15))
                    .foregroundColor(Color.theme.secondaryText)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                
                
                // 底部统计
                HStack(spacing: 24) {
                    StatLabel(
                        icon: "heart",
                        count: Int(board.boardActive.totalLikeCount),
                        iconColor: Color.theme.accent,
                        countColor: Color.theme.tertiaryText
                    )
                    
                    StatLabel(
                        icon: "bubble.left",
                        count: Int(board.boardActive.totalCommentCount),
                        iconColor: Color.theme.accent,
                        countColor: Color.theme.tertiaryText
                    )
                    
                    StatLabel(
                        icon: "signpost.right.and.left",
                        count: Int(board.boardActive.totalForkCount),
                        iconColor: Color.theme.accent,
                        countColor: Color.theme.tertiaryText
                    )
                    
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


struct ProfileRoleCell: View {
    let role: StoryRole
    @StateObject var viewModel: ProfileViewModel
    @State private var showRoleDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                // 角色头像
                KFImage(URL(string: convertImagetoSenceImage(url: role.role.characterAvatar, scene: .small)))
                    .cacheMemoryOnly()
                    .fade(duration: 0.25)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.theme.border, lineWidth: 0.5)
                    )
                
                // 角色信息
                VStack(alignment: .leading, spacing: 8) {
                    // 角色名称
                    Text(role.role.characterName)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Color.theme.primaryText)
                    
                    // 故事信息
                    HStack(spacing: 4) {
                        Text("参与故事：")
                            .font(.system(size: 14))
                            .foregroundColor(Color.theme.tertiaryText)
                        Text(role.role.characterName)
                            .font(.system(size: 14))
                            .foregroundColor(Color.theme.accent)
                            .lineLimit(1)
                    }
                    
                    // 角色描述
                    Text(role.role.characterDescription)
                        .font(.system(size: 14))
                        .foregroundColor(Color.theme.secondaryText)
                        .lineLimit(2)
                    
                    // 创建时间
                    Text("创建于：\(formatDate(timestamp: role.role.ctime))")
                        .font(.system(size: 12))
                        .foregroundColor(Color.theme.tertiaryText)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            
            Divider()
                .background(Color.theme.divider)
                .padding(.horizontal,16)
        }
        .background(Color.theme.background)
        .contentShape(Rectangle())
        .onTapGesture {
            showRoleDetail = true
        }
        .fullScreenCover(isPresented: $showRoleDetail) {
            NavigationStack {
                StoryRoleDetailView(
                    roleId: role.role.roleID,
                    userId: viewModel.user?.userID ?? 0,
                    role: role
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            // 关闭当前 NavigationStack
                            showRoleDetail = false
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(Color.theme.primaryText)
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showRoleDetail)
            }
        }
    }
    
    private func formatDate(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// 修改统计标签组件
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
                .font(.system(size: 14))
                .foregroundColor(countColor)
        }
    }
}



struct StatItem: View {
    let count: Int
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Text("\(count)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct StatItemShortCut: View {
    let count: Int
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color.theme.buttonText)
            
            Text("\(count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.theme.buttonText)
        }
    }
}

// MARK: - Segmented Control View
private struct SegmentedControlView: View {
    @Binding var selectedIndex: Int
    let titles: [String]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 24) {
                ForEach(0..<titles.count, id: \.self) { index in
                    VStack(spacing: 8) {
                        Text(titles[index])
                            .font(.system(size: 14))
                            .foregroundColor(selectedIndex == index ? Color.theme.primaryText : Color.theme.tertiaryText)
                        
                        // 下划线
                        Rectangle()
                            .fill(selectedIndex == index ? Color.theme.accent : Color.clear)
                            .frame(height: 2)
                    }
                    .onTapGesture {
                        withAnimation {
                            selectedIndex = index
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

