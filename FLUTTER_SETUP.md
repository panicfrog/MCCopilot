# Flutter 集成设置

## 🚀 快速开始

本项目使用 Flutter 官方推荐的 **CocoaPods 集成方式**。

---

## 📋 前置要求

1. Flutter SDK (3.32.8)
2. Xcode (15.0+)
3. CocoaPods (1.11+)

---

## ⚙️ 配置步骤

### 1. Flutter 框架编译

```bash
cd Flutter
flutter build ios-framework --no-profile
```

这会生成：
- `Flutter/build/ios/framework/Debug/` (调试版本)
- `Flutter/build/ios/framework/Release/` (发布版本)

### 2. CocoaPods 安装

```bash
cd ..
pod install
```

### 3. Xcode 设置

#### 3.1 打开项目

```bash
open MCCopilot.xcworkspace
```

⚠️ **注意**：必须打开 `.xcworkspace` 文件，而不是 `.xcodeproj`

#### 3.2 禁用 User Script Sandboxing

1. 选择 `MCCopilot` target
2. Build Settings
3. 搜索 `User Script Sandboxing`
4. 设置为 **`No`**

这是 React Native + Hermes 集成所必需的。

---

## 🔄 更新 Flutter 代码

每次修改 Flutter 代码后：

```bash
cd Flutter
flutter build ios-framework --no-profile
cd ..
pod install
```

---

## 🏗️ Podfile 配置

我们的 `Podfile` 自动集成了 Flutter：

```ruby
# Flutter 配置
flutter_application_path = 'Flutter'
load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')

target 'MCCopilot' do
  # Flutter pods
  install_all_flutter_pods(flutter_application_path)
  
  post_install do |installer|
    flutter_post_install(installer) if defined?(flutter_post_install)
  end
end
```

---

## 🐛 常见问题

### 问题 1: `No such module 'Flutter'`

**解决**：
```bash
cd Flutter
flutter build ios-framework --no-profile
cd ..
pod install
```

### 问题 2: `User Script Sandboxing` 错误

**解决**：在 Xcode Build Settings 中将 `User Script Sandboxing` 设置为 `No`

### 问题 3: CocoaPods 版本问题

**解决**：
```bash
sudo gem install cocoapods
pod --version  # 确保 >= 1.11
```

---

## 📚 更多信息

- 多引擎架构：查看 `Flutter/FLUTTER_MODULES.md`
- 项目概览：查看 `PROJECT_SUMMARY.md`
- 快速开始：查看 `QUICKSTART.md`
