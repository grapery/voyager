//
//  RoleImageGenView.swift
//  voyager
//
//  Created by Grapes Suo on 2025/6/15.
//

import SwiftUI
import Combine
import Kingfisher
import Foundation
import ActivityIndicatorView

struct RoleImageGenView: View {
    // 视图模型
    @ObservedObject var viewModel: StoryRoleModel
    // 输入的提示词
    @State private var prompt: String = ""
    // 上传的参考图片（本地路径或URL字符串）
    @State private var referenceImage: UIImage?
    // 选择的模型
    @State private var selectedModel: ModelType = .professional
    // 选择的比例
    @State private var aspectRatio: AspectRatio = .threeFour
    // 是否正在生成
    @State private var isGenerating: Bool = false
    // 生成结果图片
    @State private var generatedImage: UIImage?
    // 错误提示
    @State private var errorMessage: String? = nil
    // 图片选择器
    @State private var showImagePicker: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    // 标题
                    Text("角色形象生成")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.theme.primaryText)
                        .padding(.top, 12)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // Prompt 输入卡片
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil.and.outline")
                                .foregroundColor(Color.theme.accent)
                            Text("描述角色形象（Prompt）")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.theme.primaryText)
                        }
                        ZStack(alignment: .leading) {
                            if prompt.isEmpty {
                                Text("请输入角色形象描述...")
                                    .foregroundColor(Color.theme.tertiaryText)
                                    .padding(.leading, 8)
                                    .font(.system(size: 14))
                            }
                            TextField("提示词", text: $prompt)
                                .padding(12)
                                .background(Color.theme.inputBackground)
                                .cornerRadius(10)
                                .foregroundColor(Color.theme.inputText)
                                .font(.system(size: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.theme.border, lineWidth: 1)
                                )
                        }
                    }
                    .padding()
                    .background(Color.theme.secondaryBackground)
                    .cornerRadius(8)
                    .shadow(color: Color.theme.divider.opacity(0.08), radius: 4, x: 0, y: 2)

                    // 参考图片上传卡片
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .foregroundColor(Color.theme.accent)
                            Text("上传参考图片（可选）")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.theme.primaryText)
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                if let img = referenceImage {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 64, height: 64)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.theme.border, lineWidth: 1)
                                            )
                                        Button(action: { referenceImage = nil }) {
                                            Image(systemName: "plus")
                                                .foregroundColor(.white)
                                                .background(Circle().fill(Color.theme.error))
                                                .frame(width: 24, height: 24)
                                        }
                                        .offset(x: 8, y: -8)
                                    }
                                }
                                Button(action: { showImagePicker = true }) {
                                    VStack {
                                        Image(systemName: "plus")
                                            .font(.system(size: 24))
                                            .foregroundColor(Color.theme.accent)
                                        Text("上传")
                                            .font(.caption)
                                            .foregroundColor(Color.theme.accent)
                                    }
                                    .frame(width: 64, height: 64)
                                    .background(Color.theme.tertiaryBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.theme.accent, style: StrokeStyle(lineWidth: 1, dash: [4]))
                                    )
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color.theme.secondaryBackground)
                    .cornerRadius(8)
                    .shadow(color: Color.theme.divider.opacity(0.08), radius: 4, x: 0, y: 2)

                    // 风格选择（横向可滑动，线框包裹）
                    VStack(alignment: .leading, spacing: 8) {
                        Text("风格选择")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.theme.secondaryText)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(ModelType.allCases, id: \.self) { model in
                                    Button(action: { selectedModel = model }) {
                                        Text(model.displayName)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(selectedModel == model ? Color.white : Color.theme.primaryText)
                                            .padding(.horizontal, 18)
                                            .padding(.vertical, 8)
                                            .background(selectedModel == model ? Color.theme.accent : Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.theme.accent, lineWidth: 1.5)
                                            )
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    .padding()

                    // 图片比例选择（参考第二张图，线框+数字+比例图）
                    VStack(alignment: .leading, spacing: 8) {
                        Text("图片比例")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.theme.secondaryText)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(AspectRatio.allCases, id: \.self) { ratio in
                                    Button(action: { aspectRatio = ratio }) {
                                        VStack(spacing: 4) {
                                            // 线框比例图
                                            GeometryReader { geo in
                                                let w: CGFloat = 36
                                                let h: CGFloat = 48
                                                let (rw, rh) = ratioSize(ratio: ratio, maxW: w, maxH: h)
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 7)
                                                        .stroke(aspectRatio == ratio ? Color.theme.accent : Color.theme.border, lineWidth: aspectRatio == ratio ? 2 : 1)
                                                        .frame(width: w, height: h)
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .stroke(aspectRatio == ratio ? Color.theme.accent : Color.theme.tertiaryText, lineWidth: 1.2)
                                                        .frame(width: rw, height: rh)
                                                }
                                            }
                                            .frame(width: 40, height: 52)
                                            Text(ratio.displayName)
                                                .font(.system(size: 13, weight: aspectRatio == ratio ? .bold : .regular))
                                                .foregroundColor(aspectRatio == ratio ? Color.theme.accent : Color.theme.primaryText)
                                        }
                                        .padding(.horizontal, 2)
                                    }
                                }
                            }
                        }
                    }
                    .padding()


                    // 错误提示
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }

                    // 生成结果展示
                    if let img = referenceImage {
                        VStack{
                            HStack{
                                Text("生成结果")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color.theme.primaryText)
                            }
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(radius: 4)
                        }
                    }
                }
                .background(Color.theme.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.theme.border, lineWidth: 2)
                )
                .background(Color.theme.background)
                //.padding()
                //.padding(.bottom, 40)
                VStack{
                    // 生成按钮
                    Button(action: generateImages) {
                        HStack {
                            ActivityIndicatorView(isVisible: .constant(isGenerating), type: .growingArc(.cyan))
                                .frame(width: 64, height: 64)
                                .foregroundColor(.cyan)
                            Text(isGenerating ? "生成中..." : "生成")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isGenerating ? Color.gray : Color.theme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isGenerating || prompt.isEmpty)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showImagePicker) {
                SingleImagePicker(image: $referenceImage)
            }
        }
    }

    /// 计算比例图的宽高
    private func ratioSize(ratio: AspectRatio, maxW: CGFloat, maxH: CGFloat) -> (CGFloat, CGFloat) {
        // 解析比例
        let parts = ratio.displayName.split(separator: ":").compactMap { Double($0) }
        guard parts.count == 2 else { return (maxW-8, maxH-8) }
        let w = parts[0], h = parts[1]
        let scale = min((maxW-8)/CGFloat(w), (maxH-8)/CGFloat(h))
        return (CGFloat(w)*scale, CGFloat(h)*scale)
    }

    // 生成图片的逻辑
    private func generateImages() {
        guard !prompt.isEmpty else {
            errorMessage = "请输入描述信息"
            return
        }
        isGenerating = true
        errorMessage = nil
        // 这里调用 viewModel 的生成方法（如需补充请在 viewModel 中实现）
        Task {
            let result = await viewModel.generateRoleImages(prompt: prompt, referenceImage: referenceImage, model: selectedModel, count: 1, aspectRatio: aspectRatio)
            await MainActor.run {
                isGenerating = false
                switch result {
                case .success(let images):
                    generatedImage = images[0]
                case .failure(let err):
                    errorMessage = err.localizedDescription
                }
            }
        }
    }
}

// MARK: - 辅助类型

// 模型类型
enum ModelType: String, CaseIterable {
    case standard
    case professional
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .professional: return "Professional"
        }
    }
}

// 图片比例
enum AspectRatio: String, CaseIterable {
    case sixteenNine = "16:9"
    case threeTwo = "3:2"
    case fourThree = "4:3"
    case oneOne = "1:1"
    case twoThree = "2:3"
    case threeFour = "3:4"
    case nineSixteen = "9:16"
    var displayName: String { rawValue }
}


// MARK: - StoryRoleModel 生成图片方法补充
extension StoryRoleModel {
    /// 角色形象生成
    /// - Parameters:
    ///   - prompt: 描述
    ///   - referenceImages: 参考图片
    ///   - model: 模型
    ///   - count: 数量
    ///   - aspectRatio: 比例
    /// - Returns: 生成的图片数组或错误
    @MainActor
    func generateRoleImages(prompt: String, referenceImage: UIImage?, model: ModelType, count: Int, aspectRatio: AspectRatio) async -> Result<[UIImage], Error> {
        // 这里应调用后端API生成图片，当前为模拟
        // 实际项目中请替换为真实API调用
        await Task.sleep(1_000_000_000) // 模拟耗时
        // 随机返回几张纯色图片
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemPink, .systemTeal]
        let images = (0..<count).map { i in
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 240, height: 320))
            return renderer.image { ctx in
                colors[i % colors.count].setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 240, height: 320))
                let text = "AI\n角色\n\(i+1)"
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 32),
                    .foregroundColor: UIColor.white
                ]
                let string = NSAttributedString(string: text, attributes: attrs)
                string.draw(in: CGRect(x: 40, y: 100, width: 160, height: 120))
            }
        }
        return .success(images)
    }
}
