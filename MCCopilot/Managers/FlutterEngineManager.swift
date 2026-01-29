//
//  FlutterEngineManager.swift
//  MCCopilot
//
//  Created on 2025/11/10.
//

import Flutter
import Foundation

/// Flutter引擎管理器 - 使用FlutterEngineGroup实现多引擎共享VM
class FlutterEngineManager {

    static let shared = FlutterEngineManager()

    private var engineGroup: FlutterEngineGroup?
    private var engines: [String: FlutterEngine] = [:]

    private init() {}

    /// 初始化FlutterEngineGroup
    func initializeEngineGroup() {
        if engineGroup != nil {
            print("⚠️ Flutter Engine Group已经初始化")
            return
        }

        print("🚀 正在初始化Flutter Engine Group...")

        engineGroup = FlutterEngineGroup(name: "MCCopilot.FlutterEngineGroup", project: nil)

        if engineGroup != nil {
            print("✅ Flutter Engine Group初始化成功")
        } else {
            print("❌ Flutter Engine Group初始化失败")
        }
    }

    /// 创建或获取Flutter引擎
    /// - Parameters:
    ///   - identifier: 引擎标识符
    ///   - entrypoint: 入口点函数名（例如：main, shoppingMain, profileMain）
    /// - Returns: FlutterEngine实例
    func getOrCreateEngine(
        identifier: String,
        entrypoint: String? = nil
    ) -> FlutterEngine? {
        if let existingEngine = engines[identifier] {
            print("♻️ 复用Flutter引擎: \(identifier)")
            return existingEngine
        }

        guard let engineGroup = engineGroup else {
            print("❌ Flutter Engine Group未初始化")
            return nil
        }

        let entry = entrypoint ?? "main"
        print("🔧 创建Flutter引擎: \(identifier), entrypoint: \(entry)")

        // 按照官方示例创建引擎
        let engine = engineGroup.makeEngine(withEntrypoint: entry, libraryURI: nil)
        engines[identifier] = engine

        print("✅ Flutter引擎创建成功: \(identifier)")
        return engine
    }

    /// 创建FlutterViewController
    /// - Parameters:
    ///   - identifier: 引擎标识符
    ///   - entrypoint: 入口点函数名
    /// - Returns: FlutterViewController实例
    func createViewController(
        identifier: String,
        entrypoint: String? = nil
    ) -> FlutterViewController? {
        guard
            let engine = getOrCreateEngine(
                identifier: identifier,
                entrypoint: entrypoint
            )
        else {
            return nil
        }

        let viewController = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        return viewController
    }

    /// 释放指定引擎
    /// - Parameter identifier: 引擎标识符
    func releaseEngine(identifier: String) {
        if let engine = engines[identifier] {
            engine.destroyContext()
            engines.removeValue(forKey: identifier)
            print("🗑️ Flutter引擎已释放: \(identifier)")
        }
    }

    /// 释放所有引擎
    func releaseAllEngines() {
        for (identifier, engine) in engines {
            engine.destroyContext()
            print("🗑️ Flutter引擎已释放: \(identifier)")
        }
        engines.removeAll()
    }

    /// 获取当前引擎数量
    func getEngineCount() -> Int {
        return engines.count
    }

    /// 清理资源
    func cleanup() {
        releaseAllEngines()
        engineGroup = nil
        print("🗑️ Flutter Engine Group已清理")
    }
}
