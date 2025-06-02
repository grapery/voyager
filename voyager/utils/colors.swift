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
    @Published var currentTheme: AppTheme = .dark
    
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
                background: Color(hex: "F2F2F7"),
                secondaryBackground: Color(hex: "FFFFFF"),
                tertiaryBackground: Color(hex: "E5E5EA"),
                
                // Text Colors
                primaryText: Color(hex: "000000"),
                secondaryText: Color(hex: "3C3C43"),
                tertiaryText: Color(hex: "787880"),
                
                // Content Colors
                primary: Color(hex: "A5D661"),     // Brand Green
                secondary: Color(hex: "2C2C2E"),   // Dark Gray
                accent: Color(hex: "007AFF"),      // Blue
                
                // Status Colors
                success: Color(hex: "34C759"),
                warning: Color(hex: "FF9500"),
                error: Color(hex: "FF3B30"),
                
                // Interactive Colors
                buttonBackground: Color(hex: "A5D661"),
                buttonText: Color(hex: "FFFFFF"),
                inputBackground: Color(hex: "FFFFFF"),
                inputText: Color(hex: "000000"),
                
                // Divider & Border
                divider: Color(hex: "C6C6C8"),
                border: Color(hex: "D1D1D6")
            )
            
        case .dark:
            return ThemeColors(
                // Background Colors
                background: Color(red: 0.07, green: 0.11, blue: 0.09), // Dark Gray Background
                secondaryBackground: Color(red: 0.07, green: 0.11, blue: 0.09), // Dark Gray Secondary Background
                tertiaryBackground: Color(red: 0.07, green: 0.11, blue: 0.09),
                
                // Text Colors
                primaryText: Color(hex: "FFFFFF"),
                secondaryText: Color(hex: "BFC8C2"),
                tertiaryText: Color(hex: "98989F"),
                
                // Content Colors
                primary: Color(hex: "A5D661"),
                secondary: Color(hex: "2C2C2E"),
                accent: Color(hex: "0A84FF"),
                
                // Status Colors
                success: Color(hex: "30D158"),
                warning: Color(hex: "FF9F0A"),
                error: Color(hex: "FF453A"),
                
                // Interactive Colors
                buttonBackground: Color(hex: "A5D661"),
                buttonText: Color(hex: "101912"),
                inputBackground: Color(hex: "19221A"),
                inputText: Color(hex: "FFFFFF"),
                
                // Divider & Border
                divider: Color(hex: "232823"),
                border: Color(hex: "38383A")
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
