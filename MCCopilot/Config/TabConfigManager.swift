//
//  TabConfigManager.swift
//  MCCopilot
//
//  Created on 2025/11/10.
//

import Foundation
import UIKit

/// Tab类型枚举
enum TabType: String, Codable {
    case native = "native"
    case reactNative = "react-native"
    case flutter = "flutter"
    case web = "web"
}

/// Tab配置模型
struct TabConfig: Codable {
    let id: String
    let title: String
    let type: TabType
    let moduleName: String?  // React Native模块名
    let entrypoint: String?  // Flutter入口点（例如：main, shoppingMain, profileMain）
    let url: String?  // Web URL
    let icon: String?  // SF Symbol图标名称
}

/// Tab配置容器
struct TabsConfiguration: Codable {
    let tabs: [TabConfig]
}

/// Tab配置管理器
class TabConfigManager {

    static let shared = TabConfigManager()

    private init() {}

    /// 获取Tab配置
    func loadTabConfigs() -> [TabConfig] {
        // 尝试从bundle中加载配置文件
        if let configs = loadConfigFromBundle() {
            return configs
        }

        // 如果加载失败，返回默认配置
        print("⚠️ 无法加载tab配置文件，使用默认配置")
        return defaultConfigs()
    }

    /// 从Bundle加载配置
    private func loadConfigFromBundle() -> [TabConfig]? {
        guard let path = Bundle.main.path(forResource: "tab_config", ofType: "json") else {
            print("⚠️ 找不到tab_config.json文件")
            return nil
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let decoder = JSONDecoder()
            let configuration = try decoder.decode(TabsConfiguration.self, from: data)
            print("✅ 成功加载\(configuration.tabs.count)个Tab配置")
            return configuration.tabs
        } catch {
            print("❌ 解析配置文件失败: \(error)")
            return nil
        }
    }

    /// 默认配置（作为fallback）
    private func defaultConfigs() -> [TabConfig] {
        return [
            TabConfig(
                id: "tab1",
                title: "首页",
                type: .native,
                moduleName: nil,
                entrypoint: nil,
                url: nil,
                icon: "house.fill"
            ),
            TabConfig(
                id: "tab2",
                title: "RN页面",
                type: .reactNative,
                moduleName: "ExampleRNApp",
                entrypoint: nil,
                url: nil,
                icon: "cpu.fill"
            ),
            TabConfig(
                id: "tab3",
                title: "Flutter",
                type: .flutter,
                moduleName: nil,
                entrypoint: "main",
                url: nil,
                icon: "bolt.fill"
            ),
            TabConfig(
                id: "tab4",
                title: "Web",
                type: .web,
                moduleName: nil,
                entrypoint: nil,
                url: "local://index.html",
                icon: "globe"
            ),
        ]
    }

    /// 获取图标
    func getIcon(for iconName: String?) -> UIImage? {
        guard let iconName = iconName else {
            return UIImage(systemName: "circle")
        }
        return UIImage(systemName: iconName)
    }
}
