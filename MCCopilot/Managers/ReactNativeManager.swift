//
//  ReactNativeManager.swift
//  MCCopilot
//
//  Created on 2025/11/10.
//

import Foundation
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider

class ReactNativeDelegate: RCTDefaultReactNativeFactoryDelegate {
    override func sourceURL(for bridge: RCTBridge!) -> URL! {
        return bundleURL()
    }

    override func bundleURL() -> URL! {
        #if DEBUG
            return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
        #else
            return Bundle.main.url(forResource: "main", withExtension: "jsbundle")
        #endif
    }
}

class ReactNativeManager {

    static let shared = ReactNativeManager()

    private var reactNativeFactory: RCTReactNativeFactory?
    private var delegate: ReactNativeDelegate?

    private init() {}

    func initializeBridge() {
        if reactNativeFactory != nil {
            print("⚠️ React Native已经初始化")
            return
        }

        print("🚀 正在初始化React Native...")

        delegate = ReactNativeDelegate()
        delegate?.dependencyProvider = RCTAppDependencyProvider()

        reactNativeFactory = RCTReactNativeFactory(delegate: delegate!)

        // RN 0.85 需要调用 startReactNative 来初始化 JS 运行时
        // 传入 nil window，因为我们不需要它接管整个窗口
        reactNativeFactory?.startReactNative(withModuleName: "ExampleRNApp", in: nil)

        print("✅ React Native初始化成功")
    }

    func createReactNativeView(moduleName: String, initialProps: [String: Any]? = nil)
        -> UIView?
    {
        guard let factory = reactNativeFactory else {
            print("❌ React Native未初始化，无法创建视图")
            return nil
        }

        print("📱 创建React Native视图: \(moduleName)")

        let rootView = factory.rootViewFactory.view(
            withModuleName: moduleName,
            initialProperties: initialProps
        )

        rootView.backgroundColor = UIColor.white

        return rootView
    }

    func getBridge() -> RCTBridge? {
        return reactNativeFactory?.rootViewFactory.bridge
    }

    func reload() {
        #if DEBUG
            RCTTriggerReloadCommandListeners("Manual reload")
            print("🔄 React Native已重新加载")
        #else
            print("⚠️ 生产环境不支持重新加载")
        #endif
    }

    func cleanup() {
        reactNativeFactory?.rootViewFactory.bridge?.invalidate()
        reactNativeFactory = nil
        delegate = nil
        print("🗑️ React Native已清理")
    }
}
