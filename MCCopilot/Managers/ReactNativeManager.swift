//
//  ReactNativeManager.swift
//  MCCopilot
//
//  Created on 2025/11/10.
//

import Foundation
import React
import React_RCTAppDelegate

/// React Native管理器 - 使用 RCTRootViewFactory 支持 New Architecture (TurboModules)
class ReactNativeManager {

    static let shared = ReactNativeManager()

    private var rootViewFactory: RCTRootViewFactory?

    private init() {}

    /// 初始化React Native
    func initializeBridge() {
        if rootViewFactory != nil {
            print("⚠️ React Native已经初始化")
            return
        }

        print("🚀 正在初始化React Native...")

        #if DEBUG
            guard let bundleURL = RCTBundleURLProvider.sharedSettings().jsBundleURL(
                forBundleRoot: "index"
            ) else {
                print("❌ 无法获取React Native bundle URL")
                return
            }
        #else
            guard
                let bundleURL = Bundle.main.url(forResource: "main", withExtension: "jsbundle")
            else {
                print("❌ 找不到React Native bundle文件")
                return
            }
        #endif

        let configuration = RCTRootViewFactoryConfiguration(
            bundleURL: bundleURL,
            newArchEnabled: true
        )

        rootViewFactory = RCTRootViewFactory(configuration: configuration)

        print("✅ React Native初始化成功")
    }

    /// 创建React Native视图
    func createReactNativeView(moduleName: String, initialProps: [String: Any]? = nil)
        -> UIView?
    {
        guard let factory = rootViewFactory else {
            print("❌ React Native未初始化，无法创建视图")
            return nil
        }

        print("📱 创建React Native视图: \(moduleName)")

        let rootView = factory.view(
            withModuleName: moduleName,
            initialProperties: initialProps
        )

        rootView.backgroundColor = UIColor.white

        return rootView
    }

    /// 获取Bridge实例（用于高级用途）
    func getBridge() -> RCTBridge? {
        return rootViewFactory?.bridge
    }

    /// 重新加载React Native（用于开发）
    func reload() {
        #if DEBUG
            RCTTriggerReloadCommandListeners("Manual reload")
            print("🔄 React Native已重新加载")
        #else
            print("⚠️ 生产环境不支持重新加载")
        #endif
    }

    /// 清理资源
    func cleanup() {
        rootViewFactory?.bridge?.invalidate()
        rootViewFactory = nil
        print("🗑️ React Native已清理")
    }
}
