//
//  AppDelegate.swift
//  MCCopilot
//
//  Created by 叶永平 on 2025/11/10.
//

import Flutter
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        print("🚀 MCCopilot 启动中...")

        // 初始化React Native Manager
        initializeReactNative()

        // 初始化Flutter Engine Manager
        initializeFlutter()

        // 设置根视图控制器
        setupRootViewController()

        print("✅ MCCopilot 启动完成")

        return true
    }

    private func initializeReactNative() {
        print("🔧 初始化React Native...")
        ReactNativeManager.shared.initializeBridge()
    }

    private func initializeFlutter() {
        print("🔧 初始化Flutter Engine Group...")
        FlutterEngineManager.shared.initializeEngineGroup()
    }

    private func setupRootViewController() {
        // 创建Window
        window = UIWindow(frame: UIScreen.main.bounds)

        // 创建TabContainer作为根控制器
        let tabContainer = TabContainerViewController()
        window?.rootViewController = tabContainer

        // 显示窗口
        window?.makeKeyAndVisible()

        print("✅ 根视图控制器设置完成")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("🛑 应用即将终止，清理资源...")

        // 清理React Native
        ReactNativeManager.shared.cleanup()

        // 清理Flutter
        FlutterEngineManager.shared.cleanup()
    }
}
