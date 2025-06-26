//
//  localization.swift
//  voyager
//
//  Created by grapestree on 2024/12/19.
//

import Foundation
import SwiftUI

// MARK: - 支持的语言类型
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case zh = "zh"
    case en = "en"
    case ja = "ja"
    
    var id: String { rawValue }
    
    /// 语言显示名称
    var displayName: String {
        switch self {
        case .zh: return "中文"
        case .en: return "English"
        case .ja: return "日本語"
        }
    }
    
    /// 语言本地化名称
    var localizedName: String {
        switch self {
        case .zh: return "简体中文"
        case .en: return "English"
        case .ja: return "日本語"
        }
    }
}

// MARK: - 语言管理器
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: AppLanguage = .zh {
        didSet {
            // 保存语言设置到本地存储
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selectedLanguage")
        }
    }
    
    private init() {
        // 从本地存储读取语言设置
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            currentLanguage = language
        } else {
            // 默认使用系统语言或中文
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "zh"
            currentLanguage = AppLanguage(rawValue: systemLanguage) ?? .zh
        }
    }
    
    /// 设置语言
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }
    
    /// 获取当前语言
    func getCurrentLanguage() -> AppLanguage {
        return currentLanguage
    }
}

// MARK: - 本地化字符串键值枚举
enum LocalizedKey: String, CaseIterable {
    // MARK: - 通用
    case ok = "ok"
    case cancel = "cancel"
    case confirm = "confirm"
    case delete = "delete"
    case edit = "edit"
    case save = "save"
    case loading = "loading"
    case error = "error"
    case success = "success"
    case warning = "warning"
    
    // MARK: - 导航
    case back = "back"
    case next = "next"
    case previous = "previous"
    case close = "close"
    
    // MARK: - 小组相关
    case createGroup = "createGroup"
    case groupName = "groupName"
    case groupDescription = "groupDescription"
    case privacy = "privacy"
    case groupAvatar = "groupAvatar"
    case backgroundImage = "backgroundImage"
    case create = "create"
    case enterGroupName = "enterGroupName"
    case enterGroupDescription = "enterGroupDescription"
    case publicGroup = "publicGroup"
    case privateGroup = "privateGroup"
    case selectAvatar = "selectAvatar"
    case selectBackground = "selectBackground"
    case groupCreatedSuccess = "groupCreatedSuccess"
    case groupCreatedFailed = "groupCreatedFailed"
    case uploadImageFailed = "uploadImageFailed"
    case pleaseEnterGroupName = "pleaseEnterGroupName"
    
    // MARK: - 用户资料相关
    case profile = "profile"
    case basicInfo = "basicInfo"
    case industryExperience = "industryExperience"
    case educationExperience = "educationExperience"
    case name = "name"
    case address = "address"
    case bio = "bio"
    case avatar = "avatar"
    case backgroundPhoto = "backgroundPhoto"
    case addExperience = "addExperience"
    case removeExperience = "removeExperience"
    case showInProfile = "showInProfile"
    case hideFromProfile = "hideFromProfile"
    case company = "company"
    case position = "position"
    case duration = "duration"
    case description = "description"
    case school = "school"
    case major = "major"
    case degree = "degree"
    case graduationYear = "graduationYear"
    
    // MARK: - 故事相关
    case story = "story"
    case storyTitle = "storyTitle"
    case storyDescription = "storyDescription"
    case storyBackground = "storyBackground"
    case characters = "characters"
    case participants = "participants"
    case likes = "likes"
    case followers = "followers"
    case members = "members"
    case createdOn = "createdOn"
    case aiGenerated = "aiGenerated"
    case storyStyle = "storyStyle"
    case sceneCount = "sceneCount"
    case viewAllCharacters = "viewAllCharacters"
    case viewAllParticipants = "viewAllParticipants"
    
    // MARK: - 设置相关
    case settings = "settings"
    case language = "language"
    case theme = "theme"
    case notifications = "notifications"
    case privacySettings = "privacySettings"
    case about = "about"
    case logout = "logout"
    case accountSecurity = "accountSecurity"
    case feedback = "feedback"
    case socialMedia = "socialMedia"
    case aboutApp = "aboutApp"
    case teenMode = "teenMode"
    case confirmLogout = "confirmLogout"
    case logoutMessage = "logoutMessage"
    case accountSecurityDesc = "accountSecurityDesc"
    case feedbackDesc = "feedbackDesc"
    case socialMediaDesc = "socialMediaDesc"
    case aboutAppDesc = "aboutAppDesc"
    case teenModeDesc = "teenModeDesc"
    case appVersion = "appVersion"
    case good = "good"
    
    // MARK: - 认证相关
    case login = "login"
    case register = "register"
    case email = "email"
    case password = "password"
    case confirmPassword = "confirmPassword"
    case forgotPassword = "forgotPassword"
    case signIn = "signIn"
    case signUp = "signUp"
    case enterEmail = "enterEmail"
    case enterPassword = "enterPassword"
    case enterConfirmPassword = "enterConfirmPassword"
}

// MARK: - 本地化字符串管理器
struct LocalizedStrings {
    
    /// 获取本地化字符串
    static func text(_ key: LocalizedKey) -> String {
        let lang = LanguageManager.shared.currentLanguage
        return stringMap[key]?[lang] ?? stringMap[key]?[.zh] ?? key.rawValue
    }
    
    /// 获取带参数的本地化字符串
    static func text(_ key: LocalizedKey, _ arguments: CVarArg...) -> String {
        let format = text(key)
        return String(format: format, arguments: arguments)
    }
    
    /// 多语言字符串映射表
    private static let stringMap: [LocalizedKey: [AppLanguage: String]] = [
        // MARK: - 通用
        .ok: [.zh: "确定", .en: "OK", .ja: "OK"],
        .cancel: [.zh: "取消", .en: "Cancel", .ja: "キャンセル"],
        .confirm: [.zh: "确认", .en: "Confirm", .ja: "確認"],
        .delete: [.zh: "删除", .en: "Delete", .ja: "削除"],
        .edit: [.zh: "编辑", .en: "Edit", .ja: "編集"],
        .save: [.zh: "保存", .en: "Save", .ja: "保存"],
        .loading: [.zh: "加载中...", .en: "Loading...", .ja: "読み込み中..."],
        .error: [.zh: "错误", .en: "Error", .ja: "エラー"],
        .success: [.zh: "成功", .en: "Success", .ja: "成功"],
        .warning: [.zh: "警告", .en: "Warning", .ja: "警告"],
        
        // MARK: - 导航
        .back: [.zh: "返回", .en: "Back", .ja: "戻る"],
        .next: [.zh: "下一步", .en: "Next", .ja: "次へ"],
        .previous: [.zh: "上一步", .en: "Previous", .ja: "前へ"],
        .close: [.zh: "关闭", .en: "Close", .ja: "閉じる"],
        
        // MARK: - 小组相关
        .createGroup: [.zh: "创建小组", .en: "Create Group", .ja: "グループ作成"],
        .groupName: [.zh: "小组名称", .en: "Group Name", .ja: "グループ名"],
        .groupDescription: [.zh: "小组简介", .en: "Group Description", .ja: "グループ説明"],
        .privacy: [.zh: "隐私设置", .en: "Privacy", .ja: "プライバシー"],
        .groupAvatar: [.zh: "小组头像", .en: "Group Avatar", .ja: "グループアバター"],
        .backgroundImage: [.zh: "背景图片", .en: "Background Image", .ja: "背景画像"],
        .create: [.zh: "创建", .en: "Create", .ja: "作成"],
        .enterGroupName: [.zh: "请输入小组名称", .en: "Enter group name", .ja: "グループ名を入力してください"],
        .enterGroupDescription: [.zh: "请输入小组简介", .en: "Enter group description", .ja: "グループ説明を入力してください"],
        .publicGroup: [.zh: "公开", .en: "Public", .ja: "公開"],
        .privateGroup: [.zh: "私密", .en: "Private", .ja: "非公開"],
        .selectAvatar: [.zh: "选择头像", .en: "Select Avatar", .ja: "アバターを選択"],
        .selectBackground: [.zh: "选择背景", .en: "Select Background", .ja: "背景を選択"],
        .groupCreatedSuccess: [.zh: "小组创建成功", .en: "Group created successfully", .ja: "グループが正常に作成されました"],
        .groupCreatedFailed: [.zh: "小组创建失败", .en: "Failed to create group", .ja: "グループの作成に失敗しました"],
        .uploadImageFailed: [.zh: "图片上传失败", .en: "Failed to upload image", .ja: "画像のアップロードに失敗しました"],
        .pleaseEnterGroupName: [.zh: "请输入小组名称", .en: "Please enter group name", .ja: "グループ名を入力してください"],
        
        // MARK: - 用户资料相关
        .profile: [.zh: "个人资料", .en: "Profile", .ja: "プロフィール"],
        .basicInfo: [.zh: "基本资料", .en: "Basic Info", .ja: "基本情報"],
        .industryExperience: [.zh: "行业经历", .en: "Industry Experience", .ja: "業界経験"],
        .educationExperience: [.zh: "教育经历", .en: "Education Experience", .ja: "学歴"],
        .name: [.zh: "姓名", .en: "Name", .ja: "名前"],
        .address: [.zh: "地址", .en: "Address", .ja: "住所"],
        .bio: [.zh: "简介", .en: "Bio", .ja: "自己紹介"],
        .avatar: [.zh: "头像", .en: "Avatar", .ja: "アバター"],
        .backgroundPhoto: [.zh: "背景照片", .en: "Background Photo", .ja: "背景写真"],
        .addExperience: [.zh: "添加经历", .en: "Add Experience", .ja: "経験を追加"],
        .removeExperience: [.zh: "删除经历", .en: "Remove Experience", .ja: "経験を削除"],
        .showInProfile: [.zh: "在资料中显示", .en: "Show in Profile", .ja: "プロフィールに表示"],
        .hideFromProfile: [.zh: "在资料中隐藏", .en: "Hide from Profile", .ja: "プロフィールから非表示"],
        .company: [.zh: "公司", .en: "Company", .ja: "会社"],
        .position: [.zh: "职位", .en: "Position", .ja: "役職"],
        .duration: [.zh: "时长", .en: "Duration", .ja: "期間"],
        .description: [.zh: "描述", .en: "Description", .ja: "説明"],
        .school: [.zh: "学校", .en: "School", .ja: "学校"],
        .major: [.zh: "专业", .en: "Major", .ja: "専攻"],
        .degree: [.zh: "学位", .en: "Degree", .ja: "学位"],
        .graduationYear: [.zh: "毕业年份", .en: "Graduation Year", .ja: "卒業年"],
        
        // MARK: - 故事相关
        .story: [.zh: "故事", .en: "Story", .ja: "ストーリー"],
        .storyTitle: [.zh: "故事标题", .en: "Story Title", .ja: "ストーリータイトル"],
        .storyDescription: [.zh: "故事描述", .en: "Story Description", .ja: "ストーリー説明"],
        .storyBackground: [.zh: "故事背景", .en: "Story Background", .ja: "ストーリー背景"],
        .characters: [.zh: "角色", .en: "Characters", .ja: "キャラクター"],
        .participants: [.zh: "参与者", .en: "Participants", .ja: "参加者"],
        .likes: [.zh: "点赞", .en: "Likes", .ja: "いいね"],
        .followers: [.zh: "关注者", .en: "Followers", .ja: "フォロワー"],
        .members: [.zh: "成员", .en: "Members", .ja: "メンバー"],
        .createdOn: [.zh: "创建于", .en: "Created on", .ja: "作成日"],
        .aiGenerated: [.zh: "AI生成", .en: "AI Generated", .ja: "AI生成"],
        .storyStyle: [.zh: "故事风格", .en: "Story Style", .ja: "ストーリースタイル"],
        .sceneCount: [.zh: "场景数量", .en: "Scene Count", .ja: "シーン数"],
        .viewAllCharacters: [.zh: "查看所有角色", .en: "View All Characters", .ja: "すべてのキャラクターを表示"],
        .viewAllParticipants: [.zh: "查看所有参与者", .en: "View All Participants", .ja: "すべての参加者を表示"],
        
        // MARK: - 设置相关
        .settings: [.zh: "设置", .en: "Settings", .ja: "設定"],
        .language: [.zh: "语言", .en: "Language", .ja: "言語"],
        .theme: [.zh: "主题", .en: "Theme", .ja: "テーマ"],
        .notifications: [.zh: "通知", .en: "Notifications", .ja: "通知"],
        .privacySettings: [.zh: "隐私设置", .en: "Privacy Settings", .ja: "プライバシー設定"],
        .about: [.zh: "关于", .en: "About", .ja: "について"],
        .logout: [.zh: "退出登录", .en: "Logout", .ja: "ログアウト"],
        .accountSecurity: [.zh: "账号与安全", .en: "Account & Security", .ja: "アカウントとセキュリティ"],
        .feedback: [.zh: "投诉与反馈", .en: "Feedback & Support", .ja: "フィードバックとサポート"],
        .socialMedia: [.zh: "社交媒体", .en: "Social Media", .ja: "ソーシャルメディア"],
        .aboutApp: [.zh: "关于应用", .en: "About App", .ja: "アプリについて"],
        .teenMode: [.zh: "青少年模式", .en: "Teen Mode", .ja: "ティーンモード"],
        .confirmLogout: [.zh: "确认退出登录？", .en: "Confirm logout?", .ja: "ログアウトを確認しますか？"],
        .logoutMessage: [.zh: "退出登录后将无法访问您的账户", .en: "You will not be able to access your account after logging out", .ja: "ログアウト後にアカウントへのアクセスができなくなります"],
        .accountSecurityDesc: [.zh: "在这里，您可以管理您的账号信息、修改密码、设置安全选项，保障您的账户安全。", .en: "Here you can manage your account information, change passwords, and set security options to protect your account.", .ja: "ここでアカウント情報の管理、パスワードの変更、セキュリティオプションの設定を行い、アカウントの安全を確保できます。"],
        .feedbackDesc: [.zh: "如有任何问题或建议，欢迎通过此页面向我们反馈，我们会尽快处理您的意见。", .en: "If you have any questions or suggestions, please feel free to provide feedback through this page. We will process your comments as soon as possible.", .ja: "ご質問やご提案がございましたら、このページからフィードバックをお送りください。できるだけ早くご意見を処理いたします。"],
        .socialMediaDesc: [.zh: "您可以在这里绑定或管理您的社交媒体账号，方便与好友互动和分享内容。", .en: "You can bind or manage your social media accounts here to easily interact with friends and share content.", .ja: "ここでソーシャルメディアアカウントを連携または管理して、友達との交流やコンテンツの共有を簡単に行えます。"],
        .aboutAppDesc: [.zh: "Voyager 2.0.0-2429\n\n感谢您使用本应用！如需了解更多信息、隐私政策或用户协议，请访问我们的官方网站。", .en: "Voyager 2.0.0-2429\n\nThank you for using our app! For more information, privacy policy, or user agreement, please visit our official website.", .ja: "Voyager 2.0.0-2429\n\nアプリをご利用いただき、ありがとうございます！詳細情報、プライバシーポリシー、またはユーザー契約については、公式ウェブサイトをご覧ください。"],
        .teenModeDesc: [.zh: "青少年模式可为未成年人提供更健康的使用环境，限制部分功能和内容，守护青少年成长。", .en: "Teen mode provides a healthier environment for minors by limiting certain features and content, protecting youth development.", .ja: "ティーンモードは未成年者により健康的な使用環境を提供し、一部の機能とコンテンツを制限して青少年の成長を守ります。"],
        .appVersion: [.zh: "2.0.0-2429", .en: "2.0.0-2429", .ja: "2.0.0-2429"],
        .good: [.zh: "好的", .en: "OK", .ja: "OK"],
        
        // MARK: - 认证相关
        .login: [.zh: "登录", .en: "Login", .ja: "ログイン"],
        .register: [.zh: "注册", .en: "Register", .ja: "登録"],
        .email: [.zh: "邮箱", .en: "Email", .ja: "メール"],
        .password: [.zh: "密码", .en: "Password", .ja: "パスワード"],
        .confirmPassword: [.zh: "确认密码", .en: "Confirm Password", .ja: "パスワード確認"],
        .forgotPassword: [.zh: "忘记密码", .en: "Forgot Password", .ja: "パスワードを忘れた"],
        .signIn: [.zh: "登录", .en: "Sign In", .ja: "サインイン"],
        .signUp: [.zh: "注册", .en: "Sign Up", .ja: "サインアップ"],
        .enterEmail: [.zh: "请输入邮箱", .en: "Enter email", .ja: "メールアドレスを入力してください"],
        .enterPassword: [.zh: "请输入密码", .en: "Enter password", .ja: "パスワードを入力してください"],
        .enterConfirmPassword: [.zh: "请确认密码", .en: "Confirm password", .ja: "パスワードを確認してください"]
    ]
}

// MARK: - 便捷访问扩展
extension String {
    /// 本地化字符串便捷访问
    static func localized(_ key: LocalizedKey) -> String {
        return LocalizedStrings.text(key)
    }
    
    /// 带参数的本地化字符串便捷访问
    static func localized(_ key: LocalizedKey, _ arguments: CVarArg...) -> String {
        return LocalizedStrings.text(key, arguments)
    }
}