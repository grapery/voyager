import SwiftUI
import Combine
import Foundation

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showLogoutAlert = false
    @State private var selectedDetail: SettingsDetailType? = nil
    
    var body: some View {
        NavigationView {
            List {
                // 第一组设置
                Section {
                    Button(action: { selectedDetail = .accountSecurity }) {
                        SettingsRow(
                            icon: "shield.checkered",
                            title: "账号与安全",
                            iconColor: .blue
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { selectedDetail = .feedback }) {
                        SettingsRow(
                            icon: "exclamationmark.bubble",
                            title: "投诉与反馈",
                            iconColor: .orange
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { selectedDetail = .socialMedia }) {
                        SettingsRow(
                            icon: "person.3",
                            title: "社交媒体",
                            iconColor: .purple
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { selectedDetail = .aboutApp }) {
                        SettingsRow(
                            icon: "info.circle",
                            title: "关于应用",
                            subtitle: "2.0.0-2429",
                            iconColor: .gray
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { selectedDetail = .teenMode }) {
                        SettingsRow(
                            icon: "person.crop.circle.badge.clock",
                            title: "青少年模式",
                            iconColor: .green
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
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
                    Task {
                        // 1. 调用 AuthService 的登出方法
                        await AuthService.shared.signout()
                        
                        // 2. 清理 UserDefaults 中的用户数据
                        UserDefaults.standard.removeObject(forKey: "VoyagerUserToken")
                        UserDefaults.standard.removeObject(forKey: "VoyagerTokenExpiration")
                        UserDefaults.standard.removeObject(forKey: "VoyagerUserEmail")
                        UserDefaults.standard.removeObject(forKey: "VoyagerCurrentUser")
                        
                        //                        // 3. 清理 Kingfisher 图片缓存
                        //                        KingfisherManager.shared.cache.clearMemoryCache()
                        //                        KingfisherManager.shared.cache.clearDiskCache()
                        
                        // 4. 清理 CoreData 中的消息数据
                        do {
                            try CoreDataManager.shared.cleanupOldMessages(olderThan: 0)
                        } catch {
                            print("Failed to cleanup messages: \(error)")
                        }
                        
                        // // 5. 清理本地文件缓存
                        // if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
                        //     do {
                        //         let fileURLs = try FileManager.default.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil)
                        //         for fileURL in fileURLs {
                        //             try FileManager.default.removeItem(at: fileURL)
                        //         }
                        //     } catch {
                        //         print("Failed to cleanup cache directory: \(error)")
                        //     }
                        // }
                        
                        // 6. 重置用户状态
                        UserStateManager.shared.logout()
                        
                        // 7. 关闭设置页面
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedDetail) { detail in
                SettingsDetailView(detailType: detail)
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
                .foregroundColor(Color.theme.primaryText)
            
            Spacer()
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .foregroundColor(Color.theme.tertiaryText)
                    .font(.system(size: 14))
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color.theme.tertiaryText)
                .font(.system(size: 14))
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(10)
    }
}

// 枚举每个设置项
enum SettingsDetailType: Identifiable {
    case accountSecurity, feedback, socialMedia, aboutApp, teenMode
    var id: Int { hashValue }
    var title: String {
        switch self {
        case .accountSecurity: return "账号与安全"
        case .feedback: return "投诉与反馈"
        case .socialMedia: return "社交媒体"
        case .aboutApp: return "关于应用"
        case .teenMode: return "青少年模式"
        }
    }
    var content: String {
        switch self {
        case .accountSecurity:
            return "在这里，您可以管理您的账号信息、修改密码、设置安全选项，保障您的账户安全。"
        case .feedback:
            return "如有任何问题或建议，欢迎通过此页面向我们反馈，我们会尽快处理您的意见。"
        case .socialMedia:
            return "您可以在这里绑定或管理您的社交媒体账号，方便与好友互动和分享内容。"
        case .aboutApp:
            return "Voyager 2.0.0-2429\n\n感谢您使用本应用！如需了解更多信息、隐私政策或用户协议，请访问我们的官方网站。"
        case .teenMode:
            return "青少年模式可为未成年人提供更健康的使用环境，限制部分功能和内容，守护青少年成长。"
        }
    }
}

// 通用详情视图
struct SettingsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let detailType: SettingsDetailType
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景视图
                TrapezoidTriangles()
                    .opacity(0.1)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer().frame(height: 16)
                    Text(detailType.title)
                        .font(.title2).bold()
                        .multilineTextAlignment(.center)
                    ScrollView {
                        Text(detailType.content)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("好的") { dismiss() }
                        .foregroundColor(.blue)
                }
            }
        }
    }
}
