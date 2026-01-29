# 快速开始指南

## 📋 环境准备

### 必需软件

1. **Xcode** 15.0+
2. **Node.js** 18+
3. **Flutter SDK** 3.32.8
4. **CocoaPods** 1.11+

### 验证环境

```bash
# 检查 Node.js
node --version  # >= 18

# 检查 Flutter
flutter --version  # 3.32.8

# 检查 CocoaPods
pod --version  # >= 1.11
```

---

## 🚀 第一次运行

### 步骤 1: 克隆项目

```bash
cd /path/to/your/projects
git clone <repository-url>
cd MCCopilot
```

### 步骤 2: 安装 React Native 依赖

```bash
cd ReactNative
npm install
cd ..
```

### 步骤 3: 安装 Flutter 依赖

```bash
cd Flutter
flutter pub get
cd ..
```

### 步骤 4: 编译 Flutter 框架

```bash
cd Flutter
flutter build ios-framework --no-profile
cd ..
```

⏱️ **预计时间**：2-3 分钟

### 步骤 5: 安装 CocoaPods 依赖

```bash
pod install
```

⏱️ **预计时间**：3-5 分钟

### 步骤 6: 配置 Xcode

打开项目：

```bash
open MCCopilot.xcworkspace
```

⚠️ **重要**：必须打开 `.xcworkspace`，不是 `.xcodeproj`

在 Xcode 中：
1. 选择 `MCCopilot` target
2. Build Settings → 搜索 `User Script Sandboxing`
3. 设置为 **`No`**

### 步骤 7: 启动 Metro（新终端）

```bash
cd ReactNative
npm start
```

### 步骤 8: 运行项目

在 Xcode 中按 `⌘ + R`

---

## ✅ 验证安装

运行成功后，你应该看到：

- ✅ **首页**：原生 iOS 页面
- ✅ **RN 页面**：React Native 组件
- ✅ **Flutter 1/购物/我的**：三个独立的 Flutter 模块
- ✅ **Web**：本地 Web 页面

---

## 📝 日常开发

### 修改 React Native 代码

1. 编辑 `ReactNative/src/` 中的文件
2. Metro 会自动重新加载
3. 在模拟器中按 `⌘ + R` 刷新

### 修改 Flutter 代码

1. 编辑 `Flutter/lib/main.dart`
2. 重新编译 Flutter 框架：

```bash
cd Flutter
flutter build ios-framework --no-profile
cd ..
pod install
```

3. 在 Xcode 中重新运行（`⌘ + R`）

### 修改 Web 代码

1. 编辑 `Web/` 中的 HTML/CSS/JS 文件
2. 在 Xcode 中重新运行（`⌘ + R`）

### 修改 iOS 原生代码

1. 编辑 `MCCopilot/` 中的 Swift 文件
2. 在 Xcode 中重新运行（`⌘ + R`）

---

## 🐛 常见问题

### 问题 1: Metro 无法连接

**症状**：React Native 页面显示连接错误

**解决**：
```bash
cd ReactNative
npm start
```

### 问题 2: `No such module 'Flutter'`

**症状**：Xcode 编译错误

**解决**：
```bash
cd Flutter
flutter build ios-framework --no-profile
cd ..
pod install
```

### 问题 3: Pod Install 失败

**症状**：`pod install` 报错

**解决**：
```bash
pod deintegrate
pod install
```

### 问题 4: Hermes 编译错误

**症状**：`Sandbox: rsync deny file-write-create`

**解决**：在 Xcode Build Settings 中将 `User Script Sandboxing` 设置为 `No`

### 问题 5: 模拟器无法启动

**症状**：Xcode 提示模拟器错误

**解决**：
```bash
# 重启模拟器服务
xcrun simctl shutdown all
xcrun simctl erase all
```

---

## 🔄 清理和重置

如果遇到问题，可以尝试完全清理：

```bash
# 清理 React Native
cd ReactNative
rm -rf node_modules package-lock.json
npm install
cd ..

# 清理 Flutter
cd Flutter
flutter clean
flutter pub get
flutter build ios-framework --no-profile
cd ..

# 清理 CocoaPods
rm -rf Pods Podfile.lock
pod install

# 清理 Xcode
# 在 Xcode 中：Product → Clean Build Folder (⌘ + Shift + K)
```

---

## 📚 下一步

- 查看 [项目概览](./PROJECT_SUMMARY.md) 了解架构
- 查看 [Flutter 多模块](./Flutter/FLUTTER_MODULES.md) 了解如何添加新模块
- 修改 `MCCopilot/Config/tab_config.json` 自定义 Tab 配置

---

**祝开发愉快！** 🎉
