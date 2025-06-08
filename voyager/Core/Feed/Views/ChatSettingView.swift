import SwiftUI
import PhotosUI

struct ChatSettingView: View {
    // 你可以根据实际需要传递 user/role 等参数
    @Environment(\.presentationMode) var presentationMode
    @State private var chatTitle: String = ""
    @State private var isMute: Bool = false
    @State private var note: String = ""
    @ObservedObject var viewModel: MessageContextViewModel
    // 背景图片相关
    @State private var backgroundImage: UIImage? = nil
    @State private var backgroundImageUrl: String = ""
    @State private var photoItem: PhotosPickerItem? = nil
    // 语气过滤提示词
    @State private var filterPrompt: String = ""
    @State private var filterPromptEnabled: Bool = false
    // 聊天统计
    enum StatRange: String, CaseIterable, Identifiable {
        case day = "1天", threeDays = "3天", week = "1周", month = "1月", quarter = "1季度", year = "1年"
        var id: String { self.rawValue }
    }
    @State private var selectedRange: StatRange = .day
    @State private var stats: [Int] = [5, 8, 3, 10, 6, 12, 7] // mock 数据
    // 参与角色 mock
    var participants: [StoryRole] {
        if let role = viewModel.role {
            return [role] // 你可以替换为实际的参与角色数组
        }
        return []
    }
    // 用户-角色唯一ID
    var userRoleKey: String {
        "bgimg_\(viewModel.userId)_\(viewModel.role?.role.roleID ?? 0)"
    }
    var body: some View {
        NavigationView {
            Form {
                // 角色信息
                Section(header: Text("角色信息")) {
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 40, height: 40)
                        Text(viewModel.role?.role.characterName ?? "角色名称")
                            .font(.headline)
                    }
                }
                // 背景图片
                Section(header: Text("聊天背景")) {
                    if let image = backgroundImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .clipped()
                            .cornerRadius(8)
                    }
                    PhotosPicker(
                        selection: $photoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Text("选择背景图片")
                    }
                }
                // 语气过滤提示词
                Section(header: Text("语气过滤提示词")) {
                    Toggle("启用过滤", isOn: $filterPromptEnabled)
                    TextField("请输入默认提示词", text: $filterPrompt)
                        .disabled(!filterPromptEnabled)
                }
                // 聊天设置
                Section(header: Text("聊天设置")) {
                    TextField("聊天标题", text: $chatTitle)
                    Toggle("消息免打扰", isOn: $isMute)
                    TextField("备注", text: $note)
                }
                // 参与角色
                Section(header: Text("参与角色")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(participants, id: \.role.roleID) { role in
                                VStack {
                                    AvatarView(userId: viewModel.userId, roleId: role.role.roleID)
                                        .frame(width: 48, height: 48)
                                    Text(role.role.characterName)
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                // 聊天统计
                Section(header: Text("聊天统计")) {
                    Picker("时间区间", selection: $selectedRange) {
                        ForEach(StatRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    BarChartView(data: stats, range: selectedRange)
                        .frame(height: 120)
                }
            }
            .navigationBarTitle("聊天设置", displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
            })
            .onAppear {
                // 加载本地保存的背景图片URL
                if let url = UserDefaults.standard.string(forKey: userRoleKey), let image = UIImage(named: url) {
                    self.backgroundImage = image
                    self.backgroundImageUrl = url
                }
            }
        }
    }
}

// 简单BarChartView实现
struct BarChartView: View {
    let data: [Int]
    let range: ChatSettingView.StatRange
    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 5) {
                ForEach(data.indices, id: \.self) { idx in
                    let value = data[idx]
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.orange)
                        .frame(width: (geo.size.width / CGFloat(data.count)) - 8, height: CGFloat(value) / CGFloat((data.max() ?? 1)) * (geo.size.height - 20))
                    Text("\(value)")
                        .font(.caption2)
                        .frame(height: 16)
                }
            }
        }
    }
}
