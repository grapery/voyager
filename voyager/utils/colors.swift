//
//  colors.swift
//  voyager2
//
//  Created by grapestree on 2023/4/17.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    @Published var currentTheme: AppTheme = .light
    
    private init() {}
    
    func toggleTheme() {
        currentTheme = currentTheme == .dark ? .light : .dark
    }
}

// MARK: - Theme Enum
enum AppTheme {
    case light
    case dark
    
    var colors: ThemeColors {
        switch self {
        case .light:
            return ThemeColors(
                // MARK: - Background Colors (背景色)
                background: Color(hex: "FFFFFF"), // 主背景白色
                secondaryBackground: Color(hex: "FFFFFF"), // 卡片/弹窗白色
                tertiaryBackground: Color(hex: "A7D8DE"), // 天青色，三级背景
                cardBackground: Color(hex: "FFFFFF"),
                sheetBackground: Color(hex: "FFFFFF"),
                modalBackground: Color(hex: "FFFFFF"),
                navigationBackground: Color(hex: "FFFFFF"), // 导航栏白色
                tabBarBackground: Color(hex: "FFFFFF"), // TabBar白色
                searchBarBackground: Color(hex: "FFFFFF"), // 搜索栏白色
                listBackground: Color(hex: "FFFFFF"),
                groupBackground: Color(hex: "FFFFFF"),
                // MARK: - Text Colors (文字颜色)
                primaryText: Color(hex: "222222"), // 黑色
                secondaryText: Color(hex: "2C3552"), // 藏青色
                tertiaryText: Color(hex: "A7D8DE"), // 天青色
                placeholderText: Color(hex: "A7D8DE"), // 天青色
                linkText: Color(hex: "7ECFFF"), // 天蓝色
                captionText: Color(hex: "222222"), // 黑色（说明文字/时间）
                labelText: Color(hex: "2C3552"), // 藏青色
                titleText: Color(hex: "222222"), // 黑色
                subtitleText: Color(hex: "2C3552"), // 藏青色
                // MARK: - Content Colors (内容颜色)
                primary: Color(hex: "7ECFFF"), // 天蓝色
                secondary: Color(hex: "A7D8DE"), // 天青色
                accent: Color(hex: "7ECFFF"), // 天蓝色
                highlight: Color(hex: "FFB3A7"), // 浅红色
                selection: Color(hex: "7ECFFF"),
                // MARK: - Status Colors (状态颜色)
                success: Color(hex: "A7D8DE"), // 天青色
                warning: Color(hex: "FFB366"), // 柔和橙色
                error: Color(hex: "FFB3A7"), // 浅红色
                info: Color(hex: "7ECFFF"), // 天蓝色
                // MARK: - Interactive Colors (交互颜色)
                buttonBackground: Color(hex: "7ECFFF"), // 天蓝色
                buttonText: Color(hex: "FFFFFF"), // 按钮文字白色
                buttonSecondaryBackground: Color(hex: "A7D8DE"), // 天青色
                buttonSecondaryText: Color(hex: "2C3552"), // 藏青色
                buttonDisabledBackground: Color(hex: "F5E9DA"), // 锆石沙色
                buttonDisabledText: Color(hex: "A7D8DE"), // 天青色
                // MARK: - Input Colors (输入框颜色)
                inputBackground: Color(hex: "FFFFFF"),
                inputText: Color(hex: "222222"),
                inputBorder: Color(hex: "A7D8DE"),
                inputFocusBorder: Color(hex: "7ECFFF"),
                inputErrorBorder: Color(hex: "FFB3A7"),
                // MARK: - Divider & Border Colors (分割线和边框颜色)
                divider: Color(hex: "A7D8DE"),
                border: Color(hex: "A7D8DE"),
                cardBorder: Color(hex: "A7D8DE"),
                separator: Color(hex: "F5E9DA"),
                // MARK: - Icon Colors (图标颜色)
                iconColor: Color(hex: "7ECFFF"),
                iconSecondary: Color(hex: "A7D8DE"),
                iconTertiary: Color(hex: "2C3552"),
                iconDisabled: Color(hex: "F5E9DA"),
                // MARK: - Social Action Colors (社交操作颜色)
                likeIcon: Color(hex: "FFB3A7"), // 浅红色
                followIcon: Color(hex: "FFB3A7"), // 浅红色
                joinedIcon: Color(hex: "A7D8DE"),
                commentedIcon: Color(hex: "2C3552"),
                forkedIcon: Color(hex: "FFB366"),
                sharedIcon: Color(hex: "7ECFFF"),
                // MARK: - Special Colors (特殊颜色)
                settingsBackground: Color(hex: "FFFFFF"),
                appProfileBlue: Color(hex: "7ECFFF"),
                shadow: Color(hex: "A7D8DE").opacity(0.12),
                overlay: Color(hex: "2C3552").opacity(0.08),
                blur: Color(hex: "FFFFFF").opacity(0.7),
                // MARK: - Profile Colors (个人资料颜色)
                profileBackground: Color(hex: "FFFFFF"),
                profileCardBackground: Color(hex: "FFFFFF"),
                profileSectionBackground: Color(hex: "A7D8DE"),
                // MARK: - Story Colors (故事相关颜色)
                storyBackground: Color(hex: "FFFFFF"),
                storyCardBackground: Color(hex: "FFFFFF"),
                storyHighlight: Color(hex: "7ECFFF"),
                // MARK: - Chat Colors (聊天相关颜色)
                chatBackground: Color(hex: "FFFFFF"),
                chatBubbleBackground: Color(hex: "FFFFFF"),
                chatBubbleText: Color(hex: "222222"),
                chatInputBackground: Color(hex: "FFFFFF"),
                // MARK: - Notification Colors (通知相关颜色)
                notificationBackground: Color(hex: "FFFFFF"),
                notificationBadge: Color(hex: "FFB3A7"),
                notificationUnread: Color(hex: "7ECFFF"),
                // MARK: - Loading Colors (加载相关颜色)
                loadingBackground: Color(hex: "FFFFFF"),
                loadingIndicator: Color(hex: "7ECFFF"),
                skeletonBackground: Color(hex: "A7D8DE"),
                skeletonHighlight: Color(hex: "FFFFFF")
            )
        case .dark:
            return ThemeColors(
                // MARK: - Background Colors (背景色)
                background: Color(hex: "222222"), // 主背景黑色
                secondaryBackground: Color(hex: "232B3A"), // 深藏青
                tertiaryBackground: Color(hex: "2C3552"), // 藏青色
                cardBackground: Color(hex: "232B3A"),
                sheetBackground: Color(hex: "232B3A"),
                modalBackground: Color(hex: "232B3A"),
                navigationBackground: Color(hex: "232B3A"),
                tabBarBackground: Color(hex: "232B3A"),
                searchBarBackground: Color(hex: "222222"), // 搜索栏黑色
                listBackground: Color(hex: "232B3A"),
                groupBackground: Color(hex: "232B3A"),
                // MARK: - Text Colors (文字颜色)
                primaryText: Color(hex: "FFFFFF"), // 白色
                secondaryText: Color(hex: "A7D8DE"), // 天青色
                tertiaryText: Color(hex: "7ECFFF"), // 天蓝色
                placeholderText: Color(hex: "A7D8DE"),
                linkText: Color(hex: "7ECFFF"), // 天蓝色
                captionText: Color(hex: "FFFFFF"), // 白色（说明文字/时间）
                labelText: Color(hex: "A7D8DE"), // 天青色
                titleText: Color(hex: "FFFFFF"), // 白色
                subtitleText: Color(hex: "A7D8DE"), // 天青色
                // MARK: - Content Colors (内容颜色)
                primary: Color(hex: "7ECFFF"),
                secondary: Color(hex: "A7D8DE"),
                accent: Color(hex: "7ECFFF"),
                highlight: Color(hex: "FFB3A7"),
                selection: Color(hex: "7ECFFF"),
                // MARK: - Status Colors (状态颜色)
                success: Color(hex: "A7D8DE"),
                warning: Color(hex: "FFB366"),
                error: Color(hex: "FFB3A7"),
                info: Color(hex: "7ECFFF"),
                // MARK: - Interactive Colors (交互颜色)
                buttonBackground: Color(hex: "7ECFFF"),
                buttonText: Color(hex: "222222"), // 按钮文字黑色
                buttonSecondaryBackground: Color(hex: "232B3A"),
                buttonSecondaryText: Color(hex: "A7D8DE"),
                buttonDisabledBackground: Color(hex: "2C3552"),
                buttonDisabledText: Color(hex: "A7D8DE"),
                // MARK: - Input Colors (输入框颜色)
                inputBackground: Color(hex: "232B3A"),
                inputText: Color(hex: "FFFFFF"),
                inputBorder: Color(hex: "A7D8DE"),
                inputFocusBorder: Color(hex: "7ECFFF"),
                inputErrorBorder: Color(hex: "FFB3A7"),
                // MARK: - Divider & Border Colors (分割线和边框颜色)
                divider: Color(hex: "A7D8DE"),
                border: Color(hex: "A7D8DE"),
                cardBorder: Color(hex: "A7D8DE"),
                separator: Color(hex: "2C3552"),
                // MARK: - Icon Colors (图标颜色)
                iconColor: Color(hex: "7ECFFF"),
                iconSecondary: Color(hex: "A7D8DE"),
                iconTertiary: Color(hex: "F5E9DA"),
                iconDisabled: Color(hex: "232B3A"),
                // MARK: - Social Action Colors (社交操作颜色)
                likeIcon: Color(hex: "FFB3A7"),
                followIcon: Color(hex: "FFB3A7"),
                joinedIcon: Color(hex: "A7D8DE"),
                commentedIcon: Color(hex: "A7D8DE"),
                forkedIcon: Color(hex: "FFB366"),
                sharedIcon: Color(hex: "7ECFFF"),
                // MARK: - Special Colors (特殊颜色)
                settingsBackground: Color(hex: "232B3A"),
                appProfileBlue: Color(hex: "7ECFFF"),
                shadow: Color(hex: "A7D8DE").opacity(0.12),
                overlay: Color(hex: "232B3A").opacity(0.08),
                blur: Color(hex: "232B3A").opacity(0.7),
                // MARK: - Profile Colors (个人资料颜色)
                profileBackground: Color(hex: "232B3A"),
                profileCardBackground: Color(hex: "232B3A"),
                profileSectionBackground: Color(hex: "232B3A"),
                // MARK: - Story Colors (故事相关颜色)
                storyBackground: Color(hex: "232B3A"),
                storyCardBackground: Color(hex: "232B3A"),
                storyHighlight: Color(hex: "7ECFFF"),
                // MARK: - Chat Colors (聊天相关颜色)
                chatBackground: Color(hex: "232B3A"),
                chatBubbleBackground: Color(hex: "232B3A"),
                chatBubbleText: Color(hex: "FFFFFF"),
                chatInputBackground: Color(hex: "232B3A"),
                // MARK: - Notification Colors (通知相关颜色)
                notificationBackground: Color(hex: "232B3A"),
                notificationBadge: Color(hex: "FFB3A7"),
                notificationUnread: Color(hex: "7ECFFF"),
                // MARK: - Loading Colors (加载相关颜色)
                loadingBackground: Color(hex: "232B3A"),
                loadingIndicator: Color(hex: "7ECFFF"),
                skeletonBackground: Color(hex: "A7D8DE"),
                skeletonHighlight: Color(hex: "232B3A")
            )
        }
    }
}

// MARK: - Theme Colors Structure
struct ThemeColors {
    // MARK: - Background Colors (背景色)
    let background: Color
    let secondaryBackground: Color
    let tertiaryBackground: Color
    let cardBackground: Color
    let sheetBackground: Color
    let modalBackground: Color
    let navigationBackground: Color
    let tabBarBackground: Color
    let searchBarBackground: Color
    let listBackground: Color
    let groupBackground: Color
    
    // MARK: - Text Colors (文字颜色)
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let placeholderText: Color
    let linkText: Color
    let captionText: Color
    let labelText: Color
    let titleText: Color
    let subtitleText: Color
    
    // MARK: - Content Colors (内容颜色)
    let primary: Color
    let secondary: Color
    let accent: Color
    let highlight: Color
    let selection: Color
    
    // MARK: - Status Colors (状态颜色)
    let success: Color
    let warning: Color
    let error: Color
    let info: Color
    
    // MARK: - Interactive Colors (交互颜色)
    let buttonBackground: Color
    let buttonText: Color
    let buttonSecondaryBackground: Color
    let buttonSecondaryText: Color
    let buttonDisabledBackground: Color
    let buttonDisabledText: Color
    
    // MARK: - Input Colors (输入框颜色)
    let inputBackground: Color
    let inputText: Color
    let inputBorder: Color
    let inputFocusBorder: Color
    let inputErrorBorder: Color
    
    // MARK: - Divider & Border Colors (分割线和边框颜色)
    let divider: Color
    let border: Color
    let cardBorder: Color
    let separator: Color
    
    // MARK: - Icon Colors (图标颜色)
    let iconColor: Color
    let iconSecondary: Color
    let iconTertiary: Color
    let iconDisabled: Color
    
    // MARK: - Social Action Colors (社交操作颜色)
    let likeIcon: Color
    let followIcon: Color
    let joinedIcon: Color
    let commentedIcon: Color
    let forkedIcon: Color
    let sharedIcon: Color
    
    // MARK: - Special Colors (特殊颜色)
    let settingsBackground: Color
    let appProfileBlue: Color
    let shadow: Color
    let overlay: Color
    let blur: Color
    
    // MARK: - Profile Colors (个人资料颜色)
    let profileBackground: Color
    let profileCardBackground: Color
    let profileSectionBackground: Color
    
    // MARK: - Story Colors (故事相关颜色)
    let storyBackground: Color
    let storyCardBackground: Color
    let storyHighlight: Color
    
    // MARK: - Chat Colors (聊天相关颜色)
    let chatBackground: Color
    let chatBubbleBackground: Color
    let chatBubbleText: Color
    let chatInputBackground: Color
    
    // MARK: - Notification Colors (通知相关颜色)
    let notificationBackground: Color
    let notificationBadge: Color
    let notificationUnread: Color
    
    // MARK: - Loading Colors (加载相关颜色)
    let loadingBackground: Color
    let loadingIndicator: Color
    let skeletonBackground: Color
    let skeletonHighlight: Color
}

// MARK: - Color Extension
extension Color {
    static var theme: ThemeColors {
        ThemeManager.shared.currentTheme.colors
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Color {
    static let primaryBackgroud = Color(hex: "2C2C2E") //深灰色背景
    static let primaryGreenBackgroud = Color(hex: "A5D661") //绿色背景
    static let primaryGrayBackgroud = Color(hex: "F2F2F2") //灰色背景
    static let launch = LaunchTheme()
}

struct LaunchTheme {
    let accent = Color("LaunchAccentColor")
    let background = Color("LaunchBackgroundColor")
}

// MARK: - String Extensions
extension String {
    
    var trim: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var isBlank: Bool {
        return self.trim.isEmpty
    }
    
    var isAlphanumeric: Bool {
        if self.count < 8 {
            return true
        }
        return !isBlank && rangeOfCharacter(from: .alphanumerics) != nil
    }
    
    var isValidEmail: Bool {
        
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9-]+\\.[A-Za-z]{2,4}"
        let predicate = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return predicate.evaluate(with:self)
    }
    
    var isValidPhoneNo: Bool {
        
        let phoneCharacters = CharacterSet(charactersIn: "+0123456789").inverted
        let arrCharacters = self.components(separatedBy: phoneCharacters)
        return self == arrCharacters.joined(separator: "")
    }
    
    var isValidPassword: Bool {
        let passwordRegex = "^(?=.*[a-z])(?=.*[@$!%*#?&])[0-9a-zA-Z@$!%*#?&]{8,}"
        let predicate = NSPredicate(format:"SELF MATCHES %@", passwordRegex)
        return predicate.evaluate(with:self)
    }
    
    var isValidPhone: Bool {
        let phoneRegex = "^[0-9+]{0,1}+[0-9]{4,15}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phoneTest.evaluate(with: self)
    }
    
    var isValidURL: Bool {
        let urlRegEx = "((https|http)://)((\\w|-)+)(([.]|[/])((\\w|-)+))+"
        return NSPredicate(format: "SELF MATCHES %@", urlRegEx).evaluate(with: self)
    }
    
    var isValidBidValue: Bool {
        
        guard let doubleValue = Double(self) else { return false}
        if doubleValue < 0{
            return false
        }
        return true
    }
    
    var verifyURL: Bool {
        if let url  = URL(string: self) {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }
}
