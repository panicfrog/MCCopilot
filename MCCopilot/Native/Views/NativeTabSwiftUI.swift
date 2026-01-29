//
//  NativeTabSwiftUI.swift
//  MCCopilot
//
//  Created on 2025/11/13.
//

import SwiftUI

// MARK: - SwiftUI Views

/// SwiftUI版本的NativeTabView内容
struct NativeTabSwiftUIView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // 标题区域
                VStack(spacing: 8) {
                    Text("原生 iOS 页面 sss")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("使用 Swift + SwiftUI 开发")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                // 信息卡片
                InfoCardView()
                    .padding(.horizontal, 20)

                Spacer()
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

/// 信息卡片视图
struct InfoCardView: View {
    private let infoItems = [
        InfoItem(icon: "📱", text: "原生 iOS 开发"),
        InfoItem(icon: "⚛️", text: "React Native 支持"),
        InfoItem(icon: "🐦", text: "Flutter 支持"),
        InfoItem(icon: "🌐", text: "Web 支持"),
        InfoItem(icon: "⚙️", text: "配置驱动的 Tab 系统")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 卡片标题
            Text("欢迎使用混合架构")
                .font(.system(size: 20, weight: .semibold))
                .padding(.horizontal, 20)
                .padding(.top, 20)

            // 分割线
            Rectangle()
                .fill(Color(UIColor.separator))
                .frame(height: 1)
                .padding(.horizontal, 20)

            // 信息项列表
            VStack(alignment: .leading, spacing: 12) {
                ForEach(infoItems, id: \.text) { item in
                    InfoItemView(item: item)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

/// 信息项数据模型
struct InfoItem {
    let icon: String
    let text: String
}

/// 信息项视图
struct InfoItemView: View {
    let item: InfoItem

    var body: some View {
        HStack(spacing: 12) {
            Text(item.icon)
                .font(.system(size: 20))
                .frame(width: 30, alignment: .leading)

            Text(item.text)
                .font(.system(size: 16))
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 13.0, *)
struct NativeTabSwiftUIPreview: PreviewProvider {
    static var previews: some View {
        Group {
            NativeTabSwiftUIView()
                .previewDisplayName("Light Mode")
                .preferredColorScheme(.light)

            NativeTabSwiftUIView()
                .previewDisplayName("Dark Mode")
                .preferredColorScheme(.dark)
        }
    }
}

@available(iOS 13.0, *)
struct InfoCardViewPreview: PreviewProvider {
    static var previews: some View {
        InfoCardView()
            .previewDisplayName("Info Card")
            .padding()
            .background(Color.gray.opacity(0.1))
    }
}
#endif