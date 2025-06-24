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
                background: Color(red: 0.949, green: 0.949, blue: 0.969), // #F2F2F7 - 主背景
                secondaryBackground: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF - 次要背景
                tertiaryBackground: Color(red: 0.898, green: 0.898, blue: 0.918), // #E5E5EA - 第三级背景
                cardBackground: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF - 卡片背景
                sheetBackground: Color(red: 0.949, green: 0.949, blue: 0.969), // #F2F2F7 - 底部弹窗背景
                modalBackground: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF - 模态框背景
                navigationBackground: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF - 导航栏背景
                tabBarBackground: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF - 标签栏背景
                searchBarBackground: Color(red: 0.898, green: 0.898, blue: 0.918), // #E5E5EA - 搜索栏背景
                listBackground: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF - 列表背景
                groupBackground: Color(red: 0.949, green: 0.949, blue: 0.969), // #F2F2F7 - 分组背景
                
                // MARK: - Text Colors (文字颜色)
                primaryText: Color(red: 0.0, green: 0.0, blue: 0.0), // #000000 - 主要文字
                secondaryText: Color(red: 0.235, green: 0.235, blue: 0.263), // #3C3C43 - 次要文字
                tertiaryText: Color(red: 0.471, green: 0.471, blue: 0.502), // #787880 - 第三级文字
                placeholderText: Color(red: 0.471, green: 0.471, blue: 0.502), // #787880 - 占位符文字
                linkText: Color(red: 0.0, green: 0.478, blue: 1.0), // #007AFF - 链接文字
                captionText: Color(red: 0.471, green: 0.471, blue: 0.502), // #787880 - 说明文字
                labelText: Color(red: 0.235, green: 0.235, blue: 0.263), // #3C3C43 - 标签文字
                titleText: Color(red: 0.0, green: 0.0, blue: 0.0), // #000000 - 标题文字
                subtitleText: Color(red: 0.235, green: 0.235, blue: 0.263), // #3C3C43 - 副标题文字
                
                // MARK: - Content Colors (内容颜色)
                primary: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661 - 主色调
                secondary: Color(red: 0.173, green: 0.173, blue: 0.180), // #2C2C2E - 次要色调
                accent: Color(red: 0.0, green: 0.478, blue: 1.0), // #007AFF - 强调色
                highlight: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661 - 高亮色
                selection: Color(red: 0.0, green: 0.478, blue: 1.0), // #007AFF - 选中色
                
                // MARK: - Status Colors (状态颜色)
                success: Color(red: 0.204, green: 0.780, blue: 0.349), // #34C759 - 成功
                warning: Color(red: 1.0, green: 0.584, blue: 0.0), // #FF9500 - 警告
                error: Color(red: 1.0, green: 0.231, blue: 0.188), // #FF3B30 - 错误
                info: Color(red: 0.0, green: 0.478, blue: 1.0), // #007AFF - 信息
                
                // MARK: - Interactive Colors (交互颜色)
                buttonBackground: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661 - 按钮背景
                buttonText: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF - 按钮文字
                buttonSecondaryBackground: Color(red: 0.898, green: 0.898, blue: 0.918), // #E5E5EA - 次要按钮背景
                buttonSecondaryText: Color(red: 0.0, green: 0.0, blue: 0.0), // #000000 - 次要按钮文字
                buttonDisabledBackground: Color(red: 0.898, green: 0.898, blue: 0.918), // #E5E5EA - 禁用按钮背景
                buttonDisabledText: Color(red: 0.471, green: 0.471, blue: 0.502), // #787880 - 禁用按钮文字
                
                // MARK: - Input Colors (输入框颜色)
                inputBackground: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF - 输入框背景
                inputText: Color(red: 0.0, green: 0.0, blue: 0.0), // #000000 - 输入框文字
                inputBorder: Color(red: 0.820, green: 0.820, blue: 0.839), // #D1D1D6 - 输入框边框
                inputFocusBorder: Color(red: 0.0, green: 0.478, blue: 1.0), // #007AFF - 输入框聚焦边框
                inputErrorBorder: Color(red: 1.0, green: 0.231, blue: 0.188), // #FF3B30 - 输入框错误边框
                
                // MARK: - Divider & Border Colors (分割线和边框颜色)
                divider: Color(red: 0.776, green: 0.776, blue: 0.784), // #C6C6C8 - 分割线
                border: Color(red: 0.820, green: 0.820, blue: 0.839), // #D1D1D6 - 边框
                cardBorder: Color(red: 0.898, green: 0.898, blue: 0.918), // #E5E5EA - 卡片边框
                separator: Color(red: 0.776, green: 0.776, blue: 0.784), // #C6C6C8 - 分隔符
                
                // MARK: - Icon Colors (图标颜色)
                iconColor: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661 - 主图标色
                iconSecondary: Color(red: 0.471, green: 0.471, blue: 0.502), // #787880 - 次要图标色
                iconTertiary: Color(red: 0.235, green: 0.235, blue: 0.263), // #3C3C43 - 第三级图标色
                iconDisabled: Color(red: 0.776, green: 0.776, blue: 0.784), // #C6C6C8 - 禁用图标色
                
                // MARK: - Social Action Colors (社交操作颜色)
                likeIcon: Color(red: 0.976, green: 0.231, blue: 0.188), // #FA3B30 - 点赞图标
                followIcon: Color(red: 0.0, green: 0.478, blue: 1.0), // #007AFF - 关注图标
                joinedIcon: Color(red: 0.204, green: 0.780, blue: 0.349), // #34C759 - 加入图标
                commentedIcon: Color(red: 0.471, green: 0.471, blue: 0.502), // #787880 - 评论图标
                forkedIcon: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661 - 分支图标
                sharedIcon: Color(red: 0.0, green: 0.478, blue: 1.0), // #007AFF - 分享图标
                
                // MARK: - Special Colors (特殊颜色)
                settingsBackground: Color(red: 0.949, green: 0.949, blue: 0.969), // #F2F2F7 - 设置背景
                appProfileBlue: Color(red: 0.0, green: 0.478, blue: 1.0), // #007AFF - 应用配置蓝色
                shadow: Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.1), // 阴影色
                overlay: Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.5), // 遮罩色
                blur: Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.8), // 模糊背景
                
                // MARK: - Profile Colors (个人资料颜色)
                profileBackground: Color(red: 0.949, green: 0.949, blue: 0.969), // #F2F2F7 - 个人资料背景
                profileCardBackground: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF - 个人资料卡片背景
                profileSectionBackground: Color(red: 0.898, green: 0.898, blue: 0.918), // #E5E5EA - 个人资料分区背景
                
                // MARK: - Story Colors (故事相关颜色)
                storyBackground: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF - 故事背景
                storyCardBackground: Color(red: 0.949, green: 0.949, blue: 0.969), // #F2F2F7 - 故事卡片背景
                storyHighlight: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661 - 故事高亮
                
                // MARK: - Chat Colors (聊天相关颜色)
                chatBackground: Color(red: 0.949, green: 0.949, blue: 0.969), // #F2F2F7 - 聊天背景
                chatBubbleBackground: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF - 聊天气泡背景
                chatBubbleText: Color(red: 0.0, green: 0.0, blue: 0.0), // #000000 - 聊天气泡文字
                chatInputBackground: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF - 聊天输入背景
                
                // MARK: - Notification Colors (通知相关颜色)
                notificationBackground: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF - 通知背景
                notificationBadge: Color(red: 1.0, green: 0.231, blue: 0.188), // #FF3B30 - 通知徽章
                notificationUnread: Color(red: 0.0, green: 0.478, blue: 1.0), // #007AFF - 未读通知
                
                // MARK: - Loading Colors (加载相关颜色)
                loadingBackground: Color(red: 0.949, green: 0.949, blue: 0.969), // #F2F2F7 - 加载背景
                loadingIndicator: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661 - 加载指示器
                skeletonBackground: Color(red: 0.898, green: 0.898, blue: 0.918), // #E5E5EA - 骨架屏背景
                skeletonHighlight: Color(red: 1.0, green: 1.0, blue: 1.0) // #FFFFFF - 骨架屏高亮
            )
            
        case .dark:
            return ThemeColors(
                // MARK: - Background Colors (背景色)
                background: Color(red: 0.063, green: 0.098, blue: 0.071), // #101912 - 主背景
                secondaryBackground: Color(red: 0.098, green: 0.133, blue: 0.102), // #19221A - 次要背景
                tertiaryBackground: Color(red: 0.137, green: 0.157, blue: 0.137), // #232823 - 第三级背景
                cardBackground: Color(red: 0.098, green: 0.133, blue: 0.102), // #19221A - 卡片背景
                sheetBackground: Color(red: 0.063, green: 0.098, blue: 0.071), // #101912 - 底部弹窗背景
                modalBackground: Color(red: 0.098, green: 0.133, blue: 0.102), // #19221A - 模态框背景
                navigationBackground: Color(red: 0.063, green: 0.098, blue: 0.071), // #101912 - 导航栏背景
                tabBarBackground: Color(red: 0.063, green: 0.098, blue: 0.071), // #101912 - 标签栏背景
                searchBarBackground: Color(red: 0.137, green: 0.157, blue: 0.137), // #232823 - 搜索栏背景
                listBackground: Color(red: 0.098, green: 0.133, blue: 0.102), // #19221A - 列表背景
                groupBackground: Color(red: 0.063, green: 0.098, blue: 0.071), // #101912 - 分组背景
                
                // MARK: - Text Colors (文字颜色)
                primaryText: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF - 主要文字
                secondaryText: Color(red: 0.749, green: 0.784, blue: 0.761), // #BFC8C2 - 次要文字
                tertiaryText: Color(red: 0.596, green: 0.596, blue: 0.624), // #98989F - 第三级文字
                placeholderText: Color(red: 0.596, green: 0.596, blue: 0.624), // #98989F - 占位符文字
                linkText: Color(red: 0.039, green: 0.518, blue: 1.0), // #0A84FF - 链接文字
                captionText: Color(red: 0.596, green: 0.596, blue: 0.624), // #98989F - 说明文字
                labelText: Color(red: 0.749, green: 0.784, blue: 0.761), // #BFC8C2 - 标签文字
                titleText: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF - 标题文字
                subtitleText: Color(red: 0.749, green: 0.784, blue: 0.761), // #BFC8C2 - 副标题文字
                
                // MARK: - Content Colors (内容颜色)
                primary: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661 - 主色调
                secondary: Color(red: 0.173, green: 0.173, blue: 0.180), // #2C2C2E - 次要色调
                accent: Color(red: 0.039, green: 0.518, blue: 1.0), // #0A84FF - 强调色
                highlight: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661 - 高亮色
                selection: Color(red: 0.039, green: 0.518, blue: 1.0), // #0A84FF - 选中色
                
                // MARK: - Status Colors (状态颜色)
                success: Color(red: 0.188, green: 0.820, blue: 0.345), // #30D158 - 成功
                warning: Color(red: 1.0, green: 0.624, blue: 0.039), // #FF9F0A - 警告
                error: Color(red: 1.0, green: 0.271, blue: 0.227), // #FF453A - 错误
                info: Color(red: 0.039, green: 0.518, blue: 1.0), // #0A84FF - 信息
                
                // MARK: - Interactive Colors (交互颜色)
                buttonBackground: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661 - 按钮背景
                buttonText: Color(red: 0.063, green: 0.098, blue: 0.071), // #101912 - 按钮文字
                buttonSecondaryBackground: Color(red: 0.137, green: 0.157, blue: 0.137), // #232823 - 次要按钮背景
                buttonSecondaryText: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF - 次要按钮文字
                buttonDisabledBackground: Color(red: 0.137, green: 0.157, blue: 0.137), // #232823 - 禁用按钮背景
                buttonDisabledText: Color(red: 0.596, green: 0.596, blue: 0.624), // #98989F - 禁用按钮文字
                
                // MARK: - Input Colors (输入框颜色)
                inputBackground: Color(red: 0.098, green: 0.133, blue: 0.102), // #19221A - 输入框背景
                inputText: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF - 输入框文字
                inputBorder: Color(red: 0.220, green: 0.220, blue: 0.227), // #38383A - 输入框边框
                inputFocusBorder: Color(red: 0.039, green: 0.518, blue: 1.0), // #0A84FF - 输入框聚焦边框
                inputErrorBorder: Color(red: 1.0, green: 0.271, blue: 0.227), // #FF453A - 输入框错误边框
                
                // MARK: - Divider & Border Colors (分割线和边框颜色)
                divider: Color(red: 0.137, green: 0.157, blue: 0.137), // #232823 - 分割线
                border: Color(red: 0.220, green: 0.220, blue: 0.227), // #38383A - 边框
                cardBorder: Color(red: 0.137, green: 0.157, blue: 0.137), // #232823 - 卡片边框
                separator: Color(red: 0.137, green: 0.157, blue: 0.137), // #232823 - 分隔符
                
                // MARK: - Icon Colors (图标颜色)
                iconColor: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661 - 主图标色
                iconSecondary: Color(red: 0.596, green: 0.596, blue: 0.624), // #98989F - 次要图标色
                iconTertiary: Color(red: 0.749, green: 0.784, blue: 0.761), // #BFC8C2 - 第三级图标色
                iconDisabled: Color(red: 0.137, green: 0.157, blue: 0.137), // #232823 - 禁用图标色
                
                // MARK: - Social Action Colors (社交操作颜色)
                likeIcon: Color(red: 0.976, green: 0.231, blue: 0.188), // #FA3B30 - 点赞图标
                followIcon: Color(red: 0.039, green: 0.518, blue: 1.0), // #0A84FF - 关注图标
                joinedIcon: Color(red: 0.188, green: 0.820, blue: 0.345), // #30D158 - 加入图标
                commentedIcon: Color(red: 0.596, green: 0.596, blue: 0.624), // #98989F - 评论图标
                forkedIcon: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661 - 分支图标
                sharedIcon: Color(red: 0.039, green: 0.518, blue: 1.0), // #0A84FF - 分享图标
                
                // MARK: - Special Colors (特殊颜色)
                settingsBackground: Color(red: 0.063, green: 0.098, blue: 0.071), // #101912 - 设置背景
                appProfileBlue: Color(red: 0.039, green: 0.518, blue: 1.0), // #0A84FF - 应用配置蓝色
                shadow: Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.3), // 阴影色
                overlay: Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.7), // 遮罩色
                blur: Color(red: 0.063, green: 0.098, blue: 0.071, opacity: 0.8), // 模糊背景
                
                // MARK: - Profile Colors (个人资料颜色)
                profileBackground: Color(red: 0.063, green: 0.098, blue: 0.071), // #101912 - 个人资料背景
                profileCardBackground: Color(red: 0.098, green: 0.133, blue: 0.102), // #19221A - 个人资料卡片背景
                profileSectionBackground: Color(red: 0.137, green: 0.157, blue: 0.137), // #232823 - 个人资料分区背景
                
                // MARK: - Story Colors (故事相关颜色)
                storyBackground: Color(red: 0.098, green: 0.133, blue: 0.102), // #19221A - 故事背景
                storyCardBackground: Color(red: 0.063, green: 0.098, blue: 0.071), // #101912 - 故事卡片背景
                storyHighlight: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661 - 故事高亮
                
                // MARK: - Chat Colors (聊天相关颜色)
                chatBackground: Color(red: 0.063, green: 0.098, blue: 0.071), // #101912 - 聊天背景
                chatBubbleBackground: Color(red: 0.098, green: 0.133, blue: 0.102), // #19221A - 聊天气泡背景
                chatBubbleText: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF - 聊天气泡文字
                chatInputBackground: Color(red: 0.098, green: 0.133, blue: 0.102), // #19221A - 聊天输入背景
                
                // MARK: - Notification Colors (通知相关颜色)
                notificationBackground: Color(red: 0.098, green: 0.133, blue: 0.102), // #19221A - 通知背景
                notificationBadge: Color(red: 1.0, green: 0.271, blue: 0.227), // #FF453A - 通知徽章
                notificationUnread: Color(red: 0.039, green: 0.518, blue: 1.0), // #0A84FF - 未读通知
                
                // MARK: - Loading Colors (加载相关颜色)
                loadingBackground: Color(red: 0.063, green: 0.098, blue: 0.071), // #101912 - 加载背景
                loadingIndicator: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661 - 加载指示器
                skeletonBackground: Color(red: 0.137, green: 0.157, blue: 0.137), // #232823 - 骨架屏背景
                skeletonHighlight: Color(red: 0.098, green: 0.133, blue: 0.102) // #19221A - 骨架屏高亮
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
