//
//  NewStoryRole.swift
//  voyager
//
//  Created by grapestree on 2024/10/20.
//

import SwiftUI
import Kingfisher

// 创建角色视图
struct NewStoryRole: View {
    let storyId: Int64
    let userId: Int64
    @ObservedObject var viewModel: StoryDetailViewModel
    
    @State private var roleName: String = ""
    @State private var roleDescription: String = ""
    @State private var selectedVoice: String = "默认"
    @State private var selectedLanguage: String = "中文"
    @State private var isPublic: Bool = true
    @State private var showAdvancedSettings: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button(action: { 
                    dismiss()  // 添加关闭操作
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                }
                
                Spacer()
                Text("创建角色")
                    .font(.headline)
                
                Spacer()
                Button(action: { /* 一键完善操作 */ }) {
                    Text("一键完善")
                        .foregroundColor(.pink)
                }
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 24) {
                    // AI Avatar Section
                    VStack {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Text("😊")
                                .font(.system(size: 40))
                            
                            Button(action: { /* 添加头像操作 */ }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            .offset(x: 35, y: 35)
                        }
                        
                        Text("AI 生成形象")
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                    .padding(.vertical)
                    
                    // Basic Info Section
                    VStack(alignment: .leading, spacing: 16) {
                        // Name Field
                        VStack(alignment: .leading) {
                            Text("名称")
                                .font(.headline)
                            TextField("输入名称", text: $roleName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Description Field
                        VStack(alignment: .leading) {
                            Text("设定描述")
                                .font(.headline)
                            TextEditor(text: $roleDescription)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    Group {
                                        if roleDescription.isEmpty {
                                            Text("示例：你是一位经验丰富的英语老师，拥有激发学生学习热情的教学方法。你善于运用幽默和实际应用案例，使对话充满趣味。")
                                                .foregroundColor(.gray)
                                                .padding(12)
                                        }
                                    }
                                )
                        }
                        
                        // Settings List
                        VStack(spacing: 0) {
                            // Voice Setting
                            SettingRow(icon: "waveform", 
                                     iconColor: .purple,
                                     title: "声音",
                                     value: selectedVoice) {
                                /* 选择声音操作 */
                            }
                            
                            Divider()
                            
                            
                            // Privacy Setting
                            SettingRow(icon: "person.2.fill",
                                     iconColor: .blue,
                                     title: "公开·所有人可对话",
                                     showArrow: true) {
                                /* 隐私设置操作 */
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.05), radius: 5)
                    }
                    .padding(.horizontal)
                    
                    // Advanced Settings Button
                    Button(action: { showAdvancedSettings.toggle() }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("更多高级设置")
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical)
                }
            }
            
            // Create Button
            Button(action: {
                createRole()  // 添加创建操作
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("创建故事角色")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(roleName.isEmpty ? Color.gray : Color.blue)
            .cornerRadius(10)
            .disabled(roleName.isEmpty || isLoading)
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // 添加创建角色方法
    private func createRole() {
        guard !roleName.isEmpty else { return }
        isLoading = true
        
        Task {
            do {
                await viewModel.createStoryRole(
                    storyId: storyId,
                    name: roleName,
                    description: roleDescription,
                    voice: selectedVoice,
                    language: selectedLanguage,
                    isPublic: isPublic
                )
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                print("Error creating role: \(error)")
                await MainActor.run {
                    isLoading = false
                    // 这里可以添加错误提示
                }
            }
        }
    }
}

// Setting Row Component
struct SettingRow: View {
    let icon: String
    var iconColor: Color
    let title: String
    var value: String = ""
    var showArrow: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 30)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !value.isEmpty {
                    Text(value)
                        .foregroundColor(.gray)
                }
                
                if showArrow {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
            }
            .padding()
        }
    }
}

