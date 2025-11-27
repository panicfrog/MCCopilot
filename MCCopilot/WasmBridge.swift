//
//  WasmBridge.swift
//  MCCopilot
//
//  WASM integration using wasmi
//

import Foundation
import Wasmi

/// WASM运行时管理器
class WasmBridge {

    static let shared = WasmBridge()

    private var engine: OpaquePointer?
    private var store: OpaquePointer?

    private init() {}

    /// 初始化WASM运行时
    func initialize() -> Bool {
        print("🚀 Initializing WASM runtime with wasmi...")

        // 首先创建engine
        engine = wasm_engine_new()
        guard let engine = engine else {
            print("❌ Failed to create wasm engine")
            return false
        }

        // 然后使用engine创建store
        store = wasmi_store_new(engine, nil, nil)
      guard store != nil else {
            print("❌ Failed to create wasmi store")
            wasm_engine_delete(engine)
            self.engine = nil
            return false
        }

        print("✅ WASM runtime initialized successfully")
        return true
    }

    /// 清理资源
    func cleanup() {
        if let store = store {
            wasmi_store_delete(store)
            self.store = nil
            print("🧹 WASM store cleaned up")
        }

        if let engine = engine {
            wasm_engine_delete(engine)
            self.engine = nil
            print("🧹 WASM engine cleaned up")
        }
    }
}
