//
//  StoryboardVidoeGenView.swift
//  voyager
//
//  Created by Grapes Suo on 2025/6/15.
//

import SwiftUI
import Combine
import Kingfisher
import Foundation
import ActivityIndicatorView


struct StoryboardVidoeGenView: View {
    // Tab切换：0-ImageToVideo, 1-TextToVideo
    @State private var selectedTab: Int = 0
    // 上传的起始帧和结束帧
    @State private var startFrame: UIImage? = nil
    @State private var endFrame: UIImage? = nil
    // Prompt输入
    @State private var prompt: String = ""
    // 负向Prompt
    @State private var negativePrompt: String = ""
    // 模型选择
    @State private var selectedModel: VideoGenModel = .professional
    // 时长选择
    @State private var duration: VideoGenDuration = .five
    // 生成中
    @State private var isGenerating: Bool = false
    // 错误提示
    @State private var errorMessage: String? = nil
    // 生成结果
    @State private var generatedVideoURL: URL? = nil
    // 图片选择器
    @State private var showImagePicker: Bool = false
    @State private var pickingStart: Bool = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 顶部Tab切换
                HStack(spacing: 0) {
                    VideoGenTabButton(title: "Image To Video", selected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    VideoGenTabButton(title: "Text To Video", selected: selectedTab == 1) {
                        selectedTab = 1
                    }
                }
                .background(Color.theme.secondaryBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.theme.border, lineWidth: 1.5)
                )
                .padding(.horizontal, 24)
                .padding(.top, 12)

                // Frame上传区
                VStack(alignment: .leading, spacing: 12) {
                    Text("Frame")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.theme.primaryText)
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.theme.tertiaryBackground)
                            .frame(height: 220)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.theme.border, lineWidth: 1)
                            )
                        VStack(spacing: 12) {
                            HStack(spacing: 24) {
                                VStack(spacing: 4) {
                                    FrameUploadButton(image: $startFrame, label: "Start") {
                                        pickingStart = true
                                        showImagePicker = true
                                    }
                                    Text("Start")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.theme.secondaryText)
                                }
                                Image(systemName: "arrow.left.and.right")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(Color.theme.tertiaryText)
                                VStack(spacing: 4) {
                                    FrameUploadButton(image: $endFrame, label: "End") {
                                        pickingStart = false
                                        showImagePicker = true
                                    }
                                    Text("End")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.theme.secondaryText)
                                }
                            }
                            .padding(.top, 24)
                            // Hints
                            HStack(spacing: 8) {
                                ForEach(0..<5) { i in
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            VStack {
                                                Image(systemName: "photo")
                                                    .foregroundColor(Color.theme.accent)
                                                Text("2 pics")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(Color.theme.secondaryText)
                                            }
                                        )
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                .padding(.horizontal, 24)

                // Prompt输入
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Prompt")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.theme.primaryText)
                        Text("(Optional)")
                            .font(.system(size: 13))
                            .foregroundColor(Color.theme.tertiaryText)
                    }
                    TextField("Describe the shot. Look at guideline.", text: $prompt)
                        .padding(12)
                        .background(Color.theme.inputBackground)
                        .cornerRadius(8)
                        .foregroundColor(Color.theme.inputText)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.theme.border, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)

                // Setting
                VStack(alignment: .leading, spacing: 16) {
                    // 模型选择
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Model")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.theme.primaryText)
                        HStack(spacing: 16) {
                            ForEach(VideoGenModel.allCases, id: \.self) { model in
                                Button(action: { selectedModel = model }) {
                                    HStack(spacing: 4) {
                                        if model == .professional {
                                            Image(systemName: "diamond.fill")
                                                .foregroundColor(.purple)
                                                .font(.system(size: 13))
                                        }
                                        Text(model.displayName)
                                            .font(.system(size: 14, weight: .medium))
                                    }
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
                    // 时长选择
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.theme.primaryText)
                        HStack(spacing: 16) {
                            ForEach(VideoGenDuration.allCases, id: \.self) { d in
                                Button(action: { duration = d }) {
                                    HStack(spacing: 4) {
                                        if d == .ten {
                                            Image(systemName: "diamond.fill")
                                                .foregroundColor(.purple)
                                                .font(.system(size: 13))
                                        }
                                        Text(d.displayName)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(duration == d ? Color.theme.accent : Color.theme.primaryText)
                                    }
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 8)
                                    .background(duration == d ? Color.theme.accent.opacity(0.08) : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(duration == d ? Color.theme.accent : Color.theme.border, lineWidth: 1.5)
                                    )
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)

                // Negative Prompt
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Negative Prompt")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.theme.primaryText)
                        Spacer()
                        Image(systemName: "plus.circle")
                            .foregroundColor(Color.theme.accent)
                    }
                    TextField("Optional negative prompt...", text: $negativePrompt)
                        .padding(12)
                        .background(Color.theme.inputBackground)
                        .cornerRadius(8)
                        .foregroundColor(Color.theme.inputText)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.theme.border, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)

                // 错误提示
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal, 24)
                }

                // 生成按钮
                Button(action: generateVideo) {
                    HStack {
                        if isGenerating {
                            ActivityIndicatorView(isVisible: .constant(true), type: .growingArc(.cyan))
                                .frame(width: 32, height: 32)
                                .foregroundColor(.cyan)
                        }
                        Text(isGenerating ? "生成中..." : "Generate")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isGenerating ? Color.gray : Color.theme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isGenerating)
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
        }
        .background(Color.theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImagePicker) {
            ImagePickerSingle(image: pickingStart ? $startFrame : $endFrame)
        }
    }

    // 生成视频逻辑（模拟）
    private func generateVideo() {
        isGenerating = true
        errorMessage = nil
        // TODO: 调用后端API生成视频
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isGenerating = false
            // 这里可以设置生成结果
        }
    }
}

// MARK: - Tab按钮
private struct VideoGenTabButton: View {
    let title: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: selected ? .bold : .regular))
                .foregroundColor(selected ? Color.white : Color.theme.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selected ? Color.theme.accent : Color.clear)
                .cornerRadius(8)
        }
    }
}

// MARK: - Frame上传按钮
private struct FrameUploadButton: View {
    @Binding var image: UIImage?
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.theme.accent, lineWidth: 2)
                        )
                } else {
                    VStack {
                        Image(systemName: "plus")
                            .font(.system(size: 24))
                            .foregroundColor(Color.theme.accent)
                        Text(label)
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
        }
    }
}

// MARK: - 单张图片选择器
struct ImagePickerSingle: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePickerSingle
        init(_ parent: ImagePickerSingle) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - 枚举
enum VideoGenModel: String, CaseIterable {
    case standard
    case professional
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .professional: return "Professional"
        }
    }
}

enum VideoGenDuration: String, CaseIterable {
    case five
    case ten
    var displayName: String {
        switch self {
        case .five: return "5s"
        case .ten: return "10s"
        }
    }
}
