import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // 第一组设置
                Section {
                    SettingsRow(
                        icon: "shield.checkered",
                        title: "账号与安全",
                        iconColor: .blue
                    )
                    
                    SettingsRow(
                        icon: "exclamationmark.bubble",
                        title: "投诉与反馈",
                        iconColor: .orange
                    )
                    
                    SettingsRow(
                        icon: "person.3",
                        title: "社交媒体",
                        iconColor: .purple
                    )
                    
                    SettingsRow(
                        icon: "info.circle",
                        title: "关于应用",
                        subtitle: "2.0.0-2429",
                        iconColor: .gray
                    )
                    
                    SettingsRow(
                        icon: "person.crop.circle.badge.clock",
                        title: "青少年模式",
                        iconColor: .green
                    )
                }
                
                // 退出登录按钮
                Section {
                    Button(action: { showLogoutAlert = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("退出登录")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    }
                }
            }
            .alert("确认退出登录？", isPresented: $showLogoutAlert) {
                Button("取消", role: .cancel) { }
                Button("退出登录", role: .destructive) {
                    // TODO: 实现退出登录逻辑
                }
            }
        }
    }
}

// 设置行组件
struct SettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var iconColor: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14))
        }
    }
}
