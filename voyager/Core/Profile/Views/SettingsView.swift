import SwiftUI
import Combine
import Foundation

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showLogoutAlert = false
    @State private var selectedDetail: SettingsDetailType? = nil
    
    // MARK: - 语言管理
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var showLanguagePicker = false
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - 第一组设置
                Section {
                    // 语言设置
                    Button(action: { showLanguagePicker = true }) {
                        SettingsRow(
                            icon: "globe",
                            title: LocalizedStrings.text(.language),
                            subtitle: languageManager.currentLanguage.displayName,
                            iconColor: Color.theme.accent
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { selectedDetail = .accountSecurity }) {
                        SettingsRow(
                            icon: "shield.checkered",
                            title: LocalizedStrings.text(.accountSecurity),
                            iconColor: Color.theme.accent
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { selectedDetail = .feedback }) {
                        SettingsRow(
                            icon: "exclamationmark.bubble",
                            title: LocalizedStrings.text(.feedback),
                            iconColor: Color.theme.warning
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { selectedDetail = .socialMedia }) {
                        SettingsRow(
                            icon: "person.3",
                            title: LocalizedStrings.text(.socialMedia),
                            iconColor: Color.theme.success
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { selectedDetail = .aboutApp }) {
                        SettingsRow(
                            icon: "info.circle",
                            title: LocalizedStrings.text(.aboutApp),
                            subtitle: LocalizedStrings.text(.appVersion),
                            iconColor: Color.theme.tertiaryText
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { selectedDetail = .teenMode }) {
                        SettingsRow(
                            icon: "person.crop.circle.badge.clock",
                            title: LocalizedStrings.text(.teenMode),
                            iconColor: Color.theme.success
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // MARK: - 退出登录按钮
                Section {
                    Button(action: { showLogoutAlert = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(Color.theme.error)
                            Text(LocalizedStrings.text(.logout))
                                .foregroundColor(Color.theme.error)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color.theme.tertiaryText)
                                .font(.system(size: 14))
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(LocalizedStrings.text(.settings))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color.theme.primaryText)
                    }
                }
            }
            .alert(LocalizedStrings.text(.confirmLogout), isPresented: $showLogoutAlert) {
                Button(LocalizedStrings.text(.cancel), role: .cancel) { }
                Button(LocalizedStrings.text(.logout), role: .destructive) {
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
            .sheet(isPresented: $showLanguagePicker) {
                LanguagePickerView()
            }
        }
    }
}

// MARK: - 语言选择器视图
struct LanguagePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(AppLanguage.allCases) { language in
                    Button(action: {
                        languageManager.setLanguage(language)
                        dismiss()
                    }) {
                        HStack {
                            Text(language.localizedName)
                                .foregroundColor(Color.theme.primaryText)
                            Spacer()
                            if languageManager.currentLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.theme.accent)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle(LocalizedStrings.text(.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.text(.good)) {
                        dismiss()
                    }
                    .foregroundColor(Color.theme.accent)
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
        case .accountSecurity: return LocalizedStrings.text(.accountSecurity)
        case .feedback: return LocalizedStrings.text(.feedback)
        case .socialMedia: return LocalizedStrings.text(.socialMedia)
        case .aboutApp: return LocalizedStrings.text(.aboutApp)
        case .teenMode: return LocalizedStrings.text(.teenMode)
        }
    }
    var content: String {
        switch self {
        case .accountSecurity:
            return LocalizedStrings.text(.accountSecurityDesc)
        case .feedback:
            return LocalizedStrings.text(.feedbackDesc)
        case .socialMedia:
            return LocalizedStrings.text(.socialMediaDesc)
        case .aboutApp:
            return LocalizedStrings.text(.aboutAppDesc)
        case .teenMode:
            return LocalizedStrings.text(.teenModeDesc)
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
                            .foregroundColor(Color.theme.secondaryText)
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
                            .foregroundColor(Color.theme.primaryText)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.text(.good)) { dismiss() }
                        .foregroundColor(Color.theme.accent)
                }
            }
        }
    }
}
