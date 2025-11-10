# MCCopilot 项目架构概览

## 🎯 项目简介

MCCopilot 是一个 **iOS 混合应用项目**，集成了四种技术栈：

1. **React Native 0.77** - TypeScript + Hermes
2. **Flutter 3.32.8** - 多引擎共享 Dart VM
3. **Web** - 本地资源加载
4. **Native iOS** - Swift

---

## 📁 项目结构

```
MCCopilot/
├── MCCopilot/                        # iOS 主工程
│   ├── Config/                       # 配置
│   │   ├── TabConfigManager.swift    # Tab 配置管理
│   │   └── tab_config.json           # Tab 配置文件
│   ├── Managers/                     # 技术栈管理器
│   │   ├── ReactNativeManager.swift  # RN Bridge 管理
│   │   ├── FlutterEngineManager.swift # Flutter 引擎管理
│   │   └── WebViewManager.swift      # WebView 管理
│   ├── ViewControllers/              # 视图控制器
│   │   ├── TabContainerViewController.swift  # Tab 容器
│   │   ├── ReactNativeViewController.swift
│   │   ├── FlutterTabViewController.swift
│   │   └── WebTabViewController.swift
│   ├── Native/                       # 原生业务代码
│   │   └── ViewControllers/
│   │       └── NativeTabViewController.swift
│   ├── AppDelegate.swift             # 应用入口
│   └── Info.plist
│
├── ReactNative/                      # React Native 模块
│   ├── src/                          # 源码目录
│   │   ├── ExampleRNApp.tsx
│   │   └── SecondRNApp.tsx
│   ├── index.tsx                     # RN 入口
│   ├── package.json
│   ├── tsconfig.json
│   └── metro.config.js
│
├── Flutter/                          # Flutter 模块
│   ├── lib/
│   │   └── main.dart                 # 多入口点文件
│   ├── pubspec.yaml
│   ├── .ios/                         # iOS 平台配置
│   └── FLUTTER_MODULES.md            # Flutter 架构文档
│
├── Web/                              # Web 资源
│   ├── index.html
│   ├── style.css
│   └── script.js
│
├── Podfile                           # CocoaPods 配置
├── MCCopilot.xcworkspace             # Xcode 工作空间
├── README.md                         # 项目说明
├── QUICKSTART.md                     # 快速开始
└── FLUTTER_SETUP.md                  # Flutter 配置
```

---

## 🏗️ 核心架构

### 1. Tab 管理架构

```
AppDelegate
    └── TabContainerViewController (UITabBarController)
            ├── NativeTabViewController
            ├── ReactNativeViewController (RCTRootView)
            ├── FlutterTabViewController (FlutterViewController)
            └── WebTabViewController (WKWebView)
```

### 2. React Native 架构

**单 Bridge 多模块**：

```
ReactNativeManager
    └── RCTBridge (单例)
            ├── RCTRootView: "ExampleRNApp"
            └── RCTRootView: "SecondRNApp"
```

**特点**：
- ✅ 单个 Bridge 实例（降低内存占用）
- ✅ 多个 RootView（每个 Tab 独立视图）
- ✅ 共享 JS Bundle
- ✅ Hermes 引擎

### 3. Flutter 架构

**多引擎共享 VM**：

```
FlutterEngineManager
    └── FlutterEngineGroup
            ├── Engine 1: main()         → 蓝色主题
            ├── Engine 2: shoppingMain() → 橙色购物模块
            └── Engine 3: profileMain()  → 紫色个人中心
```

**特点**：
- ✅ 共享 Dart VM（低内存）
- ✅ 多个独立引擎（独立状态）
- ✅ 单个 `lib/main.dart` 文件
- ✅ `@pragma('vm:entry-point')` 标记入口点

### 4. Web 架构

**本地资源加载**：

```
WebViewManager
    └── WKURLSchemeHandler
            └── 拦截 "local://" 协议
                    └── 返回 App Bundle 中的资源
```

**特点**：
- ✅ 离线可用
- ✅ 快速加载
- ✅ 触摸优化
- ✅ JavaScript 支持

---

## ⚙️ 配置系统

### Tab 配置（`tab_config.json`）

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
    }
  ]
}
```

**配置字段说明**：

| 字段 | 说明 | 示例 |
|------|------|------|
| `id` | 唯一标识符 | `"tab1"` |
| `title` | Tab 标题 | `"首页"` |
| `type` | 技术栈类型 | `native` / `react-native` / `flutter` / `web` |
| `moduleName` | RN 模块名（仅 RN） | `"ExampleRNApp"` |
| `entrypoint` | Flutter 入口点（仅 Flutter） | `"main"` / `"shoppingMain"` |
| `url` | Web URL（仅 Web） | `"local://index.html"` |
| `icon` | SF Symbol 图标 | `"house.fill"` |

---

## 🔄 数据流

### 启动流程

```
1. AppDelegate.application(_:didFinishLaunchingWithOptions:)
    ├── initializeReactNative()
    │   └── ReactNativeManager.initializeBridge()
    │       └── 创建 RCTBridge
    │
    ├── initializeFlutter()
    │   └── FlutterEngineManager.initializeEngineGroup()
    │       └── 创建 FlutterEngineGroup
    │
    └── setupRootViewController()
        └── TabContainerViewController
            └── 根据 tab_config.json 创建 Tab
```

### Tab 切换流程

```
用户点击 Tab
    └── TabContainerViewController.tabBar(_:didSelect:)
            └── 按需创建/显示对应的 ViewController
```

---

## 🔧 依赖管理

### CocoaPods（`Podfile`）

```ruby
# React Native 配置
use_react_native!(
  :path => "./ReactNative/node_modules/react-native",
  :hermes_enabled => true
)

# Flutter 配置
flutter_application_path = 'Flutter'
install_all_flutter_pods(flutter_application_path)
```

### Node.js（`ReactNative/package.json`）

```json
{
  "dependencies": {
    "react": "18.3.1",
    "react-native": "0.77.0"
  },
  "devDependencies": {
    "typescript": "^5.6.0"
  }
}
```

### Flutter（`Flutter/pubspec.yaml`）

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
```

---

## 📊 性能优化

### 内存优化

| 技术栈 | 优化方案 | 内存节省 |
|--------|---------|---------|
| React Native | 单 Bridge 多 RootView | ~40MB |
| Flutter | FlutterEngineGroup 共享 VM | ~90MB |
| Web | 本地资源 + 缓存 | ~20MB |

### 启动优化

1. **预初始化**：在 `AppDelegate` 中预创建 Bridge 和 EngineGroup
2. **按需加载**：Tab 切换时才创建具体的 ViewController
3. **资源预加载**：Flutter 框架和 RN Bundle 打包在 App 内

---

## 🧪 测试策略

### 单元测试

- **iOS Native**: XCTest
- **React Native**: Jest
- **Flutter**: Flutter Test
- **Web**: Jest + Testing Library

### 集成测试

- **iOS UI**: XCUITest
- **E2E**: Detox (React Native) + Flutter Driver

---

## 📚 技术栈版本

| 技术 | 版本 |
|------|------|
| iOS | 15.1+ |
| Xcode | 15.0+ |
| React Native | 0.77.0 |
| Flutter | 3.32.8 |
| Node.js | 18+ |
| TypeScript | 5.6.0 |
| CocoaPods | 1.11+ |

---

## 🔮 未来计划

1. **通讯机制**：实现跨技术栈的消息传递
2. **状态管理**：统一的全局状态管理
3. **热更新**：CodePush（RN）+ 动态下发（Flutter）
4. **性能监控**：集成 Firebase Performance
5. **CI/CD**：自动化构建和发布

---

## 📖 参考资料

### 官方文档

- [React Native Integration](https://reactnative.dev/docs/0.77/integration-with-existing-apps)
- [Flutter Add-to-App](https://docs.flutter.cn/add-to-app/ios/project-setup)
- [Flutter Multiple Engines](https://github.com/flutter/samples/tree/main/add_to_app/multiple_flutters)

### 项目文档

- [快速开始](./QUICKSTART.md)
- [Flutter 设置](./FLUTTER_SETUP.md)
- [Flutter 多模块](./Flutter/FLUTTER_MODULES.md)

---

**保持架构简洁，持续优化性能！** 🚀
