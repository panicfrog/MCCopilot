# MCCopilot 混合应用

iOS 混合应用项目，集成 React Native 0.85、Flutter、Web、Rust 和原生 iOS 组件。

---

## 特性

- **React Native 0.85**：Fabric 新架构 + Re.Pack 远程分包
- **Flutter 3.32.8**：多引擎共享 Dart VM（FlutterEngineGroup）
- **Web**：Vite/React + 本地资源加载（WKURLSchemeHandler）
- **Rust**：FFI 绑定（Swift/Dart）+ WASM 插件 + Axum 后端服务
- **原生 iOS**：SwiftUI 风格的 UI
- **动态配置**：通过 JSON 配置 Tab
- **远程分包**：Re.Pack 异步 chunk + SHA-256 校验 + MinIO 分发

---

## 项目结构

```
MCCopilot/
├── MCCopilot/                 # iOS 原生应用（Swift）
│   ├── Config/                # Tab 配置（tab_config.json）
│   ├── Managers/              # 技术栈管理器
│   ├── ViewControllers/       # 视图控制器
│   └── Native/                # 原生业务代码
├── ReactNative/               # React Native 0.85（npm workspace monorepo）
│   ├── apps/mobile/           # App Shell（入口 + rspack 配置 + chunkResolver）
│   ├── packages/
│   │   ├── app-example/       # ExampleRNApp 模块
│   │   ├── app-second/        # SecondRNApp 模块
│   │   └── react-native-mccopilot  # NitroModules 原生模块（Rust FFI）
│   └── package.json           # workspace 根（scripts 转发到 apps/mobile）
├── Flutter/lib/               # Dart 多入口点
├── Web/src/                   # Vite/React Web 应用
├── Rust/crates/               # Rust 工作空间
│   ├── mccopilot-lib/         # 核心库（crypto、network）
│   ├── mccopilot/             # FFI 绑定（BoltFFI → Swift）
│   ├── mccopilot-dart/        # Dart 绑定
│   ├── mccopilot-plugin/      # WASM 插件运行时
│   └── mccopilot-server/      # Axum 后端（chunk 分发）
├── scripts/                   # 构建、manifest、上传脚本
├── docs/                      # 详细文档
├── Podfile                    # CocoaPods 依赖
└── MCCopilot.xcworkspace      # Xcode 工作空间
```

---

## 环境要求

- **macOS** 14.0+
- **Xcode** 16.0+
- **Node.js** 18+
- **Flutter SDK** 3.32.8
- **Rust** (edition 2024)
- **CocoaPods** 1.11+

---

## 快速开始

### 1. 安装依赖

```bash
cd ReactNative && npm install && cd ..
cd Flutter && flutter pub get && cd ..
cd Flutter && flutter build ios-framework --no-profile && cd ..
pod install
```

### 2. 构建 Web 资源（可选）

```bash
cd Web && npm run build:ios && npm run copy-to-ios && cd ..
```

### 3. 启动开发服务器（React Native）

```bash
cd ReactNative && npm start
```

### 4. 运行项目

用 Xcode 打开 `MCCopilot.xcworkspace`，按 `Cmd+R` 运行。

---

## Tab 配置

在 `MCCopilot/Config/tab_config.json` 中配置 Tab：

```json
{
  "tabs": [
    {
      "id": "tab1",
      "title": "首页",
      "type": "native",
      "icon": "house.fill"
    },
    {
      "id": "tab2",
      "title": "RN页面",
      "type": "react-native",
      "moduleName": "ExampleRNApp",
      "icon": "cpu.fill"
    },
    {
      "id": "tab3",
      "title": "Flutter 1",
      "type": "flutter",
      "entrypoint": "main",
      "icon": "bolt.fill"
    },
    {
      "id": "tab4",
      "title": "购物",
      "type": "flutter",
      "entrypoint": "shoppingMain",
      "icon": "cart.fill"
    },
    {
      "id": "tab5",
      "title": "我的",
      "type": "flutter",
      "entrypoint": "profileMain",
      "icon": "person.fill"
    },
    {
      "id": "tab6",
      "title": "Web",
      "type": "web",
      "url": "local://index.html",
      "icon": "globe"
    }
  ]
}
```

---

## 核心架构

### React Native 0.85

- **Monorepo 架构**：npm workspace 组织，`apps/mobile` 为 App Shell，`packages/` 下为各功能模块（`app-example`、`app-second`、`react-native-mccopilot`）
- **Fabric 新架构**：`RCTReactNativeFactory` + `RCTDefaultReactNativeFactoryDelegate`
- **多 Surface**：多个 RN 模块通过 `AppRegistry` 注册，各自在独立的 Fabric Surface 中渲染
- **Re.Pack 打包**：基于 Rspack（非 Metro），支持异步 chunk 拆分
- **远程分包**：`React.lazy` + Re.Pack 生成异步 chunk → `mccopilot-server`（Rust/Axum + MinIO）分发 → 客户端 `chunkResolver.ts` 处理下载 + SHA-256 校验 + 本地缓存
- **Hermes**：高性能 JS 引擎

### Flutter

- **FlutterEngineGroup**：多引擎共享 Dart VM
- **多入口点**：`main()`, `shoppingMain()`, `profileMain()`（需 `@pragma('vm:entry-point')`）
- **低内存占用**：VM 共享降低内存消耗

### Web

- **Vite + React**：构建输出到 `Web/dist/`，复制到 Xcode 项目
- **本地资源加载**：通过 `WKURLSchemeHandler` 拦截 `local://` 协议
- **触摸优化**：禁用文本选择和滚动反弹

### Rust

- **核心库**：`mccopilot-lib` 提供加密、网络、插件功能
- **FFI 绑定**：`mccopilot` 通过 BoltFFI 为 Swift/Android 提供调用接口
- **Dart 绑定**：`mccopilot-dart` 为 Flutter 提供调用接口
- **WASM 插件**：`mccopilot-plugin` 插件运行时
- **后端服务**：`mccopilot-server` 基于 Axum，负责 chunk 分发（MinIO/S3）

### React Native ↔ Rust 桥接

`ReactNative/packages/react-native-mccopilot` 是 NitroModules 原生模块，通过 JSI 访问 Rust 加密函数。桥接链路：

```
TypeScript → NitroModules (.nitro.ts) → 生成 Swift → Rust FFI
```

---

## 远程分包

```bash
# 一键构建 + 上传 chunk（需要 mccopilot-server 和 MinIO 运行中）
bash scripts/upload-chunks.sh

# 仅构建 bundle
cd ReactNative && npm run bundle-ios

# 仅生成 manifest
node scripts/build-manifest.mjs

# 启动后端服务
cd Rust && cargo run --bin mccopilot-server
```

详细文档见 [docs/rn-remote-chunks.md](docs/rn-remote-chunks.md)

---

## 常用命令

```bash
# React Native 类型检查 / Lint
cd ReactNative && npm run type-check
cd ReactNative && npm run lint

# Web Lint
cd Web && npm run lint

# Rust Lint
cd Rust && cargo clippy

# RN 生产包
cd ReactNative && npm run bundle-ios       # production
cd ReactNative && npm run bundle-ios-dev   # debug

# 完整清理
cd ReactNative && rm -rf node_modules package-lock.json && npm install && cd ..
cd Flutter && flutter clean && flutter pub get && flutter build ios-framework --no-profile && cd ..
rm -rf Pods Podfile.lock && pod install
```

---

## 文档

- [快速开始](./QUICKSTART.md) - 详细的入门指南
- [项目概览](./PROJECT_SUMMARY.md) - 架构和设计说明
- [Flutter 设置](./FLUTTER_SETUP.md) - Flutter 集成步骤
- [Flutter 多模块](./Flutter/FLUTTER_MODULES.md) - 多引擎架构说明
- [RN 远程分包](./docs/rn-remote-chunks.md) - 远程分包方案详解

---

## 常见问题

### Re.Pack 开发服务器无法连接

确保开发服务器已启动：
```bash
cd ReactNative && npm start
```

### Flutter 模块加载失败

重新编译 Flutter 框架：
```bash
cd Flutter && flutter clean && flutter build ios-framework --no-profile && cd .. && pod install
```

### Xcode 编译错误

1. 检查 **User Script Sandboxing** 是否设置为 `No`
2. 清理 Xcode 缓存：`Cmd+Shift+K`
3. 重新安装 Pods：`pod deintegrate && pod install`

---

## 许可证

MIT License
