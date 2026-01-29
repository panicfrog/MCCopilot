# MCCopilot 混合应用

🚀 **iOS 混合应用项目**，集成了 React Native、Flutter、Web 和原生 iOS 组件。

---

## 📋 特性

- ✅ **React Native 0.77**：单 Bridge 多模块架构
- ✅ **Flutter 3.32.8**：多引擎共享 Dart VM（FlutterEngineGroup）
- ✅ **Web**：本地资源加载（WKURLSchemeHandler）
- ✅ **原生 iOS**：SwiftUI 风格的 UI
- ✅ **动态配置**：通过 JSON 配置 Tab

---

## 🏗️ 项目结构

```
MCCopilot/
├── MCCopilot/                 # 主工程
│   ├── Config/                # Tab 配置
│   ├── Managers/              # 技术栈管理器
│   ├── ViewControllers/       # 视图控制器
│   └── Native/                # 原生业务代码
├── ReactNative/               # React Native 代码
│   ├── src/                   # 源码
│   └── index.tsx              # 入口文件
├── Flutter/                   # Flutter 模块
│   └── lib/main.dart          # 多入口点
├── Web/                       # Web 资源
│   ├── index.html
│   ├── style.css
│   └── script.js
├── Podfile                    # CocoaPods 依赖
└── MCCopilot.xcworkspace      # Xcode 工作空间
```

---

## ⚙️ 环境要求

- **macOS** 14.0+
- **Xcode** 15.0+
- **Node.js** 18+
- **Flutter SDK** 3.32.8
- **CocoaPods** 1.11+

---

## 🚀 快速开始

### 1. 安装依赖

```bash
# 安装 Node.js 依赖
cd ReactNative
npm install
cd ..

# 安装 Flutter 依赖
cd Flutter
flutter pub get
cd ..

# 安装 CocoaPods 依赖
pod install
```

### 2. 编译 Flutter 框架

```bash
cd Flutter
flutter build ios-framework --no-profile
cd ..
pod install
```

### 3. 启动 Metro（React Native）

```bash
cd ReactNative
npm start
```

### 4. 运行项目

```bash
open MCCopilot.xcworkspace
```

在 Xcode 中按 `⌘ + R` 运行。

---

## 📱 Tab 配置

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

## 🔧 核心架构

### React Native

- **单 Bridge 架构**：所有 RN 模块共享一个 `RCTBridge`
- **TypeScript**：类型安全的开发体验
- **Hermes**：高性能 JS 引擎

### Flutter

- **FlutterEngineGroup**：多引擎共享 Dart VM
- **多入口点**：`main()`, `shoppingMain()`, `profileMain()`
- **低内存占用**：VM 共享降低内存消耗

### Web

- **本地资源加载**：通过 `WKURLSchemeHandler` 拦截 `local://` 协议
- **JavaScript 支持**：完整的 JS 运行环境
- **触摸优化**：禁用文本选择和滚动反弹

---

## 📚 文档

- [快速开始](./QUICKSTART.md) - 详细的入门指南
- [项目概览](./PROJECT_SUMMARY.md) - 架构和设计说明
- [Flutter 设置](./FLUTTER_SETUP.md) - Flutter 集成步骤
- [Flutter 多模块](./Flutter/FLUTTER_MODULES.md) - 多引擎架构说明

---

## 🐛 常见问题

### Metro 无法连接

确保 Metro 已启动：
```bash
cd ReactNative
npm start
```

### Flutter 模块加载失败

重新编译 Flutter 框架：
```bash
cd Flutter
flutter clean
flutter build ios-framework --no-profile
cd ..
pod install
```

### Xcode 编译错误

1. 检查 **User Script Sandboxing** 是否设置为 `No`
2. 清理 Xcode 缓存：`⌘ + Shift + K`
3. 重新安装 Pods：`pod deintegrate && pod install`

---

## 📄 许可证

MIT License

---

## 👥 贡献

欢迎提交 Issue 和 Pull Request！

---

**享受混合开发的乐趣！** 🎉
