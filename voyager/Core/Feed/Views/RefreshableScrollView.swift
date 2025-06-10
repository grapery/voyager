struct RefreshableScrollView<Content: View>: View {
    @Binding var isRefreshing: Bool
    let onRefresh: () async -> Void
    let content: Content
    @State private var lastRefreshTime: Date?
    @State private var isTriggered = false
    private let minimumRefreshInterval: TimeInterval = 1.0
    private let triggerThreshold: CGFloat = 50
    
    init(
        isRefreshing: Binding<Bool>,
        onRefresh: @escaping () async -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self._isRefreshing = isRefreshing
        self.onRefresh = onRefresh
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            GeometryReader { geometry in
                let offset = geometry.frame(in: .global).minY
                print("ScrollView offset: \(offset)")
                
                if offset > triggerThreshold {
                    Spacer()
                        .onAppear {
                            print("Refresh trigger appeared")
                            guard !isRefreshing && !isTriggered else {
                                print("Skipping refresh - already refreshing or triggered")
                                return
                            }
                            
                            // 检查刷新间隔
                            if let lastRefresh = lastRefreshTime {
                                let timeSinceLastRefresh = Date().timeIntervalSince(lastRefresh)
                                if timeSinceLastRefresh < minimumRefreshInterval {
                                    print("Skipping refresh - too soon since last refresh")
                                    return
                                }
                            }
                            
                            print("Starting refresh")
                            isRefreshing = true
                            isTriggered = true
                            lastRefreshTime = Date()
                            
                            Task {
                                print("Refresh task started")
                                await onRefresh()
                                print("Refresh task completed")
                                isRefreshing = false
                                isTriggered = false
                                print("Refresh state reset")
                            }
                        }
                } else {
                    // 当滚动回顶部时重置触发状态
                    if isTriggered {
                        isTriggered = false
                        print("Reset trigger state")
                    }
                }
            }
            .frame(height: 0)
            
            content
        }
    }
} 