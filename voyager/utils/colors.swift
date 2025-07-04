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
                background: Color(hex: "F7F7F7"), // 主背景
                secondaryBackground: Color(hex: "FFFFFF"), // 卡片/弹窗
                tertiaryBackground: Color(hex: "F0F1F2"), // 三级背景/输入框
                cardBackground: Color(hex: "FFFFFF"),
                sheetBackground: Color(hex: "FFFFFF"),
                modalBackground: Color(hex: "FFFFFF"),
                navigationBackground: Color(hex: "FFFFFF"),
                tabBarBackground: Color(hex: "FFFFFF"),
                searchBarBackground: Color(hex: "F0F1F2"),
                listBackground: Color(hex: "F7F7F7"),
                groupBackground: Color(hex: "F7F7F7"),
                // MARK: - Text Colors (文字颜色)
                primaryText: Color(hex: "222222"), // 主文字/标题/返回按钮
                secondaryText: Color(hex: "888888"), // 次要文字
                tertiaryText: Color(hex: "BBBBBB"), // 辅助文字
                placeholderText: Color(hex: "BBBBBB"),
                linkText: Color(hex: "3C9EFF"), // 蓝色链接
                captionText: Color(hex: "BBBBBB"), // 说明/时间
                labelText: Color(hex: "888888"),
                titleText: Color(hex: "222222"),
                subtitleText: Color(hex: "888888"),
                // MARK: - Content Colors (内容颜色)
                primary: Color(hex: "2E5A8A"), // 藏青色
                secondary: Color(hex: "3C9EFF"), // 蓝色
                accent: Color(hex: "2E5A8A"), // 高亮藏青色
                highlight: Color(hex: "FFAC2D"), // 橙色
                selection: Color(hex: "2E5A8A"),
                // MARK: - Status Colors (状态颜色)
                success: Color(hex: "2E5A8A"), // 藏青色
                warning: Color(hex: "FFAC2D"),
                error: Color(hex: "FF5A5A"),
                info: Color(hex: "3C9EFF"),
                // MARK: - Interactive Colors (交互颜色)
                buttonBackground: Color(hex: "2E5A8A"), // 主按钮藏青色
                buttonText: Color(hex: "FFFFFF"), // 按钮文字白色
                buttonSecondaryBackground: Color(hex: "F0F1F2"),
                buttonSecondaryText: Color(hex: "222222"),
                buttonDisabledBackground: Color(hex: "EDEDED"),
                buttonDisabledText: Color(hex: "BBBBBB"),
                // MARK: - Input Colors (输入框颜色)
                inputBackground: Color(hex: "F0F1F2"),
                inputText: Color(hex: "222222"),
                inputBorder: Color(hex: "EDEDED"),
                inputFocusBorder: Color(hex: "2E5A8A"), // 藏青色
                inputErrorBorder: Color(hex: "FF5A5A"),
                // MARK: - Divider & Border Colors (分割线和边框颜色)
                divider: Color(hex: "EDEDED"),
                border: Color(hex: "EDEDED"),
                cardBorder: Color(hex: "EDEDED"),
                separator: Color(hex: "EDEDED"),
                // MARK: - Icon Colors (图标颜色)
                iconColor: Color(hex: "2E5A8A"), // 藏青色
                iconSecondary: Color(hex: "888888"),
                iconTertiary: Color(hex: "BBBBBB"),
                iconDisabled: Color(hex: "EDEDED"),
                // MARK: - Social Action Colors (社交操作颜色)
                likeIcon: Color(hex: "FF5A5A"), // 点赞/红色
                followIcon: Color(hex: "FF5A5A"), // 关注/红色
                joinedIcon: Color(hex: "2E5A8A"), // 藏青色
                commentedIcon: Color(hex: "888888"),
                forkedIcon: Color(hex: "FFAC2D"),
                sharedIcon: Color(hex: "3C9EFF"),
                // MARK: - Special Colors (特殊颜色)
                settingsBackground: Color(hex: "F7F7F7"),
                appProfileBlue: Color(hex: "3C9EFF"),
                shadow: Color(hex: "BBBBBB").opacity(0.12),
                overlay: Color(hex: "222222").opacity(0.08),
                blur: Color(hex: "FFFFFF").opacity(0.7),
                // MARK: - Profile Colors (个人资料颜色)
                profileBackground: Color(hex: "F7F7F7"),
                profileCardBackground: Color(hex: "FFFFFF"),
                profileSectionBackground: Color(hex: "F0F1F2"),
                // MARK: - Story Colors (故事相关颜色)
                storyBackground: Color(hex: "FFFFFF"),
                storyCardBackground: Color(hex: "FFFFFF"),
                storyHighlight: Color(hex: "FFAC2D"),
                // MARK: - Chat Colors (聊天相关颜色)
                chatBackground: Color(hex: "F7F7F7"),
                chatBubbleBackground: Color(hex: "FFFFFF"),
                chatBubbleText: Color(hex: "222222"),
                chatInputBackground: Color(hex: "F0F1F2"),
                // MARK: - Notification Colors (通知相关颜色)
                notificationBackground: Color(hex: "FFFFFF"),
                notificationBadge: Color(hex: "FF5A5A"),
                notificationUnread: Color(hex: "2E5A8A"), // 藏青色
                // MARK: - Loading Colors (加载相关颜色)
                loadingBackground: Color(hex: "F7F7F7"),
                loadingIndicator: Color(hex: "2E5A8A"), // 藏青色
                skeletonBackground: Color(hex: "EDEDED"),
                skeletonHighlight: Color(hex: "FFFFFF")
            )
        case .dark:
            return ThemeColors(
                // MARK: - Background Colors (背景色)
                background: Color(hex: "232A34"), // 柔和深灰蓝
                secondaryBackground: Color(hex: "262E38"), // 卡片/弹窗
                tertiaryBackground: Color(hex: "2A3240"), // 三级背景/输入框
                cardBackground: Color(hex: "262E38"),
                sheetBackground: Color(hex: "262E38"),
                modalBackground: Color(hex: "262E38"),
                navigationBackground: Color(hex: "232A34"),
                tabBarBackground: Color(hex: "232A34"),
                searchBarBackground: Color(hex: "262E38"),
                listBackground: Color(hex: "232A34"),
                groupBackground: Color(hex: "232A34"),
                // MARK: - Text Colors (文字颜色)
                primaryText: Color(hex: "F3F6F9"), // 柔和白
                secondaryText: Color(hex: "A6B2C2"), // 淡蓝灰
                tertiaryText: Color(hex: "7A869A"), // 更淡灰蓝
                placeholderText: Color(hex: "A6B2C2"),
                linkText: Color(hex: "5CAEFF"), // 柔和蓝
                captionText: Color(hex: "A6B2C2"),
                labelText: Color(hex: "A6B2C2"),
                titleText: Color(hex: "F3F6F9"),
                subtitleText: Color(hex: "A6B2C2"),
                // MARK: - Content Colors (内容颜色)
                primary: Color(hex: "4A7BA7"), // 柔和藏青色
                secondary: Color(hex: "5CAEFF"), // 柔和蓝
                accent: Color(hex: "4A7BA7"), // 高亮藏青色
                highlight: Color(hex: "FFB84D"), // 柔和橙
                selection: Color(hex: "4A7BA7"),
                // MARK: - Status Colors (状态颜色)
                success: Color(hex: "4A7BA7"), // 柔和藏青色
                warning: Color(hex: "FFB84D"),
                error: Color(hex: "FF7A7A"), // 柔和红
                info: Color(hex: "5CAEFF"),
                // MARK: - Interactive Colors (交互颜色)
                buttonBackground: Color(hex: "4A7BA7"), // 柔和藏青色
                buttonText: Color(hex: "F3F6F9"), // 柔和白
                buttonSecondaryBackground: Color(hex: "2A3240"),
                buttonSecondaryText: Color(hex: "F3F6F9"),
                buttonDisabledBackground: Color(hex: "2C3440"), // 柔和禁用
                buttonDisabledText: Color(hex: "A6B2C2"),
                // MARK: - Input Colors (输入框颜色)
                inputBackground: Color(hex: "2A3240"),
                inputText: Color(hex: "F3F6F9"),
                inputBorder: Color(hex: "2A3240"),
                inputFocusBorder: Color(hex: "4A7BA7"), // 柔和藏青色
                inputErrorBorder: Color(hex: "FF7A7A"),
                // MARK: - Divider & Border Colors (分割线和边框颜色)
                divider: Color(hex: "2A3240"),
                border: Color(hex: "2A3240"),
                cardBorder: Color(hex: "2A3240"),
                separator: Color(hex: "2A3240"),
                // MARK: - Icon Colors (图标颜色)
                iconColor: Color(hex: "4A7BA7"), // 柔和藏青色
                iconSecondary: Color(hex: "A6B2C2"), // 淡蓝灰
                iconTertiary: Color(hex: "7A869A"), // 更淡灰蓝
                iconDisabled: Color(hex: "2C3440"),
                // MARK: - Social Action Colors (社交操作颜色)
                likeIcon: Color(hex: "FF7A7A"), // 柔和红
                followIcon: Color(hex: "FF7A7A"),
                joinedIcon: Color(hex: "4A7BA7"), // 柔和藏青色
                commentedIcon: Color(hex: "A6B2C2"),
                forkedIcon: Color(hex: "FFB84D"),
                sharedIcon: Color(hex: "5CAEFF"),
                // MARK: - Special Colors (特殊颜色)
                settingsBackground: Color(hex: "232A34"),
                appProfileBlue: Color(hex: "5CAEFF"),
                shadow: Color(hex: "7A869A").opacity(0.10), // 柔和阴影
                overlay: Color(hex: "232A34").opacity(0.08),
                blur: Color(hex: "232A34").opacity(0.7),
                // MARK: - Profile Colors (个人资料颜色)
                profileBackground: Color(hex: "232A34"),
                profileCardBackground: Color(hex: "262E38"),
                profileSectionBackground: Color(hex: "2A3240"),
                // MARK: - Story Colors (故事相关颜色)
                storyBackground: Color(hex: "232A34"),
                storyCardBackground: Color(hex: "262E38"),
                storyHighlight: Color(hex: "FFB84D"),
                // MARK: - Chat Colors (聊天相关颜色)
                chatBackground: Color(hex: "232A34"),
                chatBubbleBackground: Color(hex: "2A3240"),
                chatBubbleText: Color(hex: "F3F6F9"),
                chatInputBackground: Color(hex: "2A3240"),
                // MARK: - Notification Colors (通知相关颜色)
                notificationBackground: Color(hex: "232A34"),
                notificationBadge: Color(hex: "FF7A7A"),
                notificationUnread: Color(hex: "4A7BA7"), // 柔和藏青色
                // MARK: - Loading Colors (加载相关颜色)
                loadingBackground: Color(hex: "232A34"),
                loadingIndicator: Color(hex: "4A7BA7"), // 柔和藏青色
                skeletonBackground: Color(hex: "2A3240"),
                skeletonHighlight: Color(hex: "232A34")
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
