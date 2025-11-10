//
//  ReactNativeManager.swift
//  MCCopilot
//
//  Created on 2025/11/10.
//

import Foundation
import React

/// React Native管理器 - 管理单个Bridge实例
class ReactNativeManager {

    static let shared = ReactNativeManager()

    private var bridge: RCTBridge?

    private init() {}

    /// 初始化React Native Bridge
    func initializeBridge() {
        if bridge != nil {
            print("⚠️ React Native Bridge已经初始化")
            return
        }

        print("🚀 正在初始化React Native Bridge...")

        #if DEBUG
            // 开发模式：从Metro服务器加载
            let jsCodeLocation = RCTBundleURLProvider.sharedSettings().jsBundleURL(
                forBundleRoot: "index"
            )
        #else
            // 生产模式：从本地bundle加载
            guard
                let jsCodeLocation = Bundle.main.url(forResource: "main", withExtension: "jsbundle")
            else {
                print("❌ 找不到React Native bundle文件")
                return
            }
        #endif

        bridge = RCTBridge(bundleURL: jsCodeLocation, moduleProvider: nil, launchOptions: nil)

        if bridge != nil {
            print("✅ React Native Bridge初始化成功")
        } else {
            print("❌ React Native Bridge初始化失败")
        }
    }

    /// 创建React Native视图
    /// - Parameters:
    ///   - moduleName: 注册的模块名称
    ///   - initialProps: 初始属性
    /// - Returns: RCTRootView实例
    func createReactNativeView(moduleName: String, initialProps: [String: Any]? = nil)
        -> RCTRootView?
    {
        guard let bridge = bridge else {
            print("❌ React Native Bridge未初始化，无法创建视图")
            return nil
        }

        print("📱 创建React Native视图: \(moduleName)")

        let rootView = RCTRootView(
            bridge: bridge,
            moduleName: moduleName,
            initialProperties: initialProps
        )

        rootView.backgroundColor = UIColor.white

        return rootView
    }

    /// 获取Bridge实例（用于高级用途）
    func getBridge() -> RCTBridge? {
        return bridge
    }

    /// 重新加载React Native（用于开发）
    func reload() {
        #if DEBUG
            bridge?.reload()
            print("🔄 React Native已重新加载")
        #else
            print("⚠️ 生产环境不支持重新加载")
        #endif
    }

    /// 清理资源
    func cleanup() {
        bridge?.invalidate()
        bridge = nil
        print("🗑️ React Native Bridge已清理")
    }
}
