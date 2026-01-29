# Flutter 多引擎架构

## 📚 概述

本项目使用 **Flutter 多引擎架构**，通过 `FlutterEngineGroup` 实现多个独立的 Flutter 实例，共享同一个 Dart VM。

参考：[Flutter 官方 multiple_flutters 示例](https://github.com/flutter/samples/tree/main/add_to_app/multiple_flutters)

---

## 🎯 架构设计

### 核心概念

```
FlutterEngineGroup (共享 Dart VM)
    ├─ Engine 1: main()          → 蓝色主题
    ├─ Engine 2: shoppingMain()  → 橙色购物模块
    └─ Engine 3: profileMain()   → 紫色个人中心
```

### 特点

- ✅ **单个 Dart 文件**：所有入口点在 `lib/main.dart` 中
- ✅ **多个入口函数**：`main()`, `shoppingMain()`, `profileMain()`
- ✅ **共享 VM**：所有引擎共享 Dart VM，降低内存占用
- ✅ **独立状态**：每个引擎有独立的状态管理和导航栈

---

## 📁 项目结构

```
Flutter/
  ├── lib/
  │   └── main.dart          # 所有入口点都在这里
  ├── pubspec.yaml
  └── FLUTTER_MODULES.md     # 本文档
```

---

## 💻 代码实现

### Flutter 端 (`lib/main.dart`)

```dart
import 'package:flutter/material.dart';

// 默认入口点
void main() => runApp(const MyApp(
      title: 'Flutter Example',
      color: Colors.blue,
      icon: Icons.flutter_dash,
      route: '/example',
    ));

// 购物模块入口点
@pragma('vm:entry-point')  // ⚠️ 必须添加此注解
void shoppingMain() => runApp(const MyApp(
      title: '购物模块',
      color: Colors.orange,
      icon: Icons.shopping_cart,
      route: '/shopping',
    ));

// 个人中心入口点
@pragma('vm:entry-point')
void profileMain() => runApp(const MyApp(
      title: '个人中心',
      color: Colors.purple,
      icon: Icons.person,
      route: '/profile',
    ));

// 主应用 - 通过参数区分不同模块
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.title,
    required this.color,
    required this.icon,
    required this.route,
  });

  final String title;
  final MaterialColor color;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(colorSchemeSeed: color, useMaterial3: true),
      home: MyHomePage(title: title, color: color, icon: icon, route: route),
    );
  }
}
```

**关键点**：

1. 所有入口点在同一个文件
2. 非默认入口点需要 `@pragma('vm:entry-point')` 注解
3. 通过参数区分不同模块

### iOS 端 (`FlutterEngineManager.swift`)

```swift
// 创建引擎
let engine = engineGroup.makeEngine(withEntrypoint: entrypoint, libraryURI: nil)
```

**关键点**：

- `entrypoint`: 入口点函数名（`main`, `shoppingMain`, `profileMain`）
- `libraryURI`: 为 `nil`（因为都在 `lib/main.dart`）

---

## ⚙️ 配置

### `tab_config.json`

```json
{
  "tabs": [
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
    }
  ]
}
```

---

## 🚀 如何添加新模块

### 步骤 1: 在 `lib/main.dart` 添加入口点

```dart
@pragma('vm:entry-point')
void myNewModule() => runApp(const MyApp(
      title: '新模块',
      color: Colors.green,
      icon: Icons.star,
      route: '/new',
    ));
```

### 步骤 2: 更新 `tab_config.json`

```json
{
  "id": "tab_new",
  "title": "新模块",
  "type": "flutter",
  "entrypoint": "myNewModule",
  "icon": "star.fill"
}
```

### 步骤 3: 重新编译

```bash
cd Flutter
flutter build ios-framework --no-profile
cd ..
pod install
```

---

## 🔧 编译与运行

### 编译 Flutter 框架

```bash
cd Flutter
flutter build ios-framework --no-profile
```

这会生成：

- `Flutter/build/ios/framework/Debug/`
- `Flutter/build/ios/framework/Release/`

### 更新 CocoaPods

```bash
cd ..
pod install
```

### 在 Xcode 运行

```bash
open MCCopilot.xcworkspace
⌘ + R
```

---

## 📊 性能优势

### 内存占用对比

| 方案               | Dart VM 数量 | 内存占用 |
| ------------------ | ------------ | -------- |
| 独立引擎           | 3 个         | ~150MB   |
| FlutterEngineGroup | 1 个（共享） | ~60MB    |

### 优势

1. **低内存占用**：共享 Dart VM
2. **快速启动**：VM 已预热
3. **独立状态**：每个引擎互不干扰
4. **易于维护**：所有代码在一个文件

---

## 🐛 故障排查

### 问题 1: 所有 Tab 显示相同内容

**原因**：入口点函数可能被 tree-shaking 移除

**解决**：确保添加 `@pragma('vm:entry-point')` 注解

### 问题 2: 引擎创建失败

**检查**：

```swift
// 查看控制台日志
print("   🚪 entrypoint: \(entry)")
let engine = engineGroup.makeEngine(withEntrypoint: entry, libraryURI: nil)
```

### 问题 3: 页面空白

**原因**：Flutter 框架未正确编译

**解决**：

```bash
cd Flutter
flutter clean
flutter build ios-framework --no-profile
```

---

## 📚 参考资料

- [Flutter 官方示例](https://github.com/flutter/samples/tree/main/add_to_app/multiple_flutters)
- [Flutter Add-to-App 文档](https://docs.flutter.cn/add-to-app/multiple-flutters/)
- [FlutterEngineGroup API](https://api.flutter.dev/objcdoc/Classes/FlutterEngineGroup.html)

---

## ✅ 最佳实践

1. **入口点命名**：使用有意义的名称（如 `shoppingMain`, `profileMain`）
2. **参数传递**：通过构造函数参数区分模块
3. **共享代码**：将通用组件放在同一个文件中
4. **注解使用**：所有非默认入口点都需要 `@pragma('vm:entry-point')`
5. **状态管理**：每个模块可以有独立的状态管理策略

---

## 🎉 总结

这个架构实现了：

- ✅ 真正的多模块（每个模块独立的引擎）
- ✅ 共享 Dart VM（低内存占用）
- ✅ 符合官方最佳实践
- ✅ 易于维护和扩展
