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
        currentTheme = currentTheme == .dark ? .dark : .light
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
                // Background Colors
                background: Color(red: 0.949, green: 0.949, blue: 0.969), // #F2F2F7
                secondaryBackground: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF
                tertiaryBackground: Color(red: 0.898, green: 0.898, blue: 0.918), // #E5E5EA
                
                // Text Colors
                primaryText: Color(red: 0.0, green: 0.0, blue: 0.0), // #000000
                secondaryText: Color(red: 0.235, green: 0.235, blue: 0.263), // #3C3C43
                tertiaryText: Color(red: 0.471, green: 0.471, blue: 0.502), // #787880
                
                // Content Colors
                primary: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661
                secondary: Color(red: 0.173, green: 0.173, blue: 0.180), // #2C2C2E
                accent: Color(red: 0.0, green: 0.478, blue: 1.0), // #007AFF
                
                // Status Colors
                success: Color(red: 0.204, green: 0.780, blue: 0.349), // #34C759
                warning: Color(red: 1.0, green: 0.584, blue: 0.0), // #FF9500
                error: Color(red: 1.0, green: 0.231, blue: 0.188), // #FF3B30
                
                // Interactive Colors
                buttonBackground: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661
                buttonText: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF
                inputBackground: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF
                inputText: Color(red: 0.0, green: 0.0, blue: 0.0), // #000000
                
                // Divider & Border
                divider: Color(red: 0.776, green: 0.776, blue: 0.784), // #C6C6C8
                border: Color(red: 0.820, green: 0.820, blue: 0.839), // #D1D1D6
                
                // icon and settings
                iconColor: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661
                settingsBackground: Color(red: 0.949, green: 0.949, blue: 0.969), // #F2F2F7
                likeIcon: Color(red: 0.976, green: 0.231, blue: 0.188), // #FA3B30 (更亮的红色)
                followIcon: Color(red: 0.0, green: 0.478, blue: 1.0), // #007AFF
                joinedIcon: Color(red: 0.204, green: 0.780, blue: 0.349), // #34C759
                commentedIcon: Color(red: 0.471, green: 0.471, blue: 0.502), // #787880
                forkedIcon: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661
                appProfileBlue: Color(red: 0.0, green: 0.478, blue: 1.0) // #007AFF
            )
            
        case .dark:
            return ThemeColors(
                // Background Colors
                background: Color(red: 0.07, green: 0.11, blue: 0.09), // Dark Gray Background
                secondaryBackground: Color(red: 0.07, green: 0.11, blue: 0.09), // Dark Gray Secondary Background
                tertiaryBackground: Color(red: 0.07, green: 0.11, blue: 0.09),
                
                // Text Colors
                primaryText: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF
                secondaryText: Color(red: 0.749, green: 0.784, blue: 0.761), // #BFC8C2
                tertiaryText: Color(red: 0.596, green: 0.596, blue: 0.624), // #98989F
                
                // Content Colors
                primary: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661
                secondary: Color(red: 0.173, green: 0.173, blue: 0.180), // #2C2C2E
                accent: Color(red: 0.039, green: 0.518, blue: 1.0), // #0A84FF
                
                // Status Colors
                success: Color(red: 0.188, green: 0.820, blue: 0.345), // #30D158
                warning: Color(red: 1.0, green: 0.624, blue: 0.039), // #FF9F0A
                error: Color(red: 1.0, green: 0.271, blue: 0.227), // #FF453A
                
                // Interactive Colors
                buttonBackground: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661
                buttonText: Color(red: 0.063, green: 0.098, blue: 0.071), // #101912
                inputBackground: Color(red: 0.098, green: 0.133, blue: 0.102), // #19221A
                inputText: Color(red: 1.0, green: 1.0, blue: 1.0), // #FFFFFF
                
                // Divider & Border
                divider: Color(red: 0.137, green: 0.157, blue: 0.137), // #232823
                border: Color(red: 0.220, green: 0.220, blue: 0.227), // #38383A
                
                // icon and settings
                iconColor: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661
                settingsBackground: Color(red: 0.063, green: 0.098, blue: 0.071), // #101912
                likeIcon: Color(red: 0.976, green: 0.231, blue: 0.188), // #FA3B30
                followIcon: Color(red: 0.039, green: 0.518, blue: 1.0), // #0A84FF
                joinedIcon: Color(red: 0.188, green: 0.820, blue: 0.345), // #30D158
                commentedIcon: Color(red: 0.596, green: 0.596, blue: 0.624), // #98989F
                forkedIcon: Color(red: 0.647, green: 0.839, blue: 0.380), // #A5D661
                
                //
                appProfileBlue: Color(red: 0.0, green: 0.478, blue: 1.0) // #007AFF
            )
        }
    }
}

// MARK: - Theme Colors Structure
struct ThemeColors {
    // Background Colors
    let background: Color
    let secondaryBackground: Color
    let tertiaryBackground: Color
    
    // Text Colors
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    
    // Content Colors
    let primary: Color
    let secondary: Color
    let accent: Color
    
    // Status Colors
    let success: Color
    let warning: Color
    let error: Color
    
    // Interactive Colors
    let buttonBackground: Color
    let buttonText: Color
    let inputBackground: Color
    let inputText: Color
    
    // Divider & Border
    let divider: Color
    let border: Color
    
    // icon and settings
    let iconColor: Color
    let settingsBackground: Color
    let likeIcon: Color
    let followIcon: Color
    let joinedIcon: Color // Primary color for joined icon
    let commentedIcon: Color // Primary color for commented icon
    let forkedIcon: Color // Primary color for forked icon
    
    // appProfileBlue
    let appProfileBlue: Color
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
