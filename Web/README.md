# MCCopilot Web Module

这是一个使用 React + TypeScript + Vite 构建的现代化 Web 模块，集成在 MCCopilot iOS 应用中。

## 项目结构

```
Web/
├── src/                    # React 源代码
│   ├── App.tsx            # 主应用组件
│   ├── main.tsx           # 应用入口
│   └── index.css          # 全局样式
├── scripts/               # 构建脚本
│   ├── build.js           # Node.js 构建脚本
│   └── build-web.sh       # Xcode 集成脚本
├── public/                # 静态资源
├── dist/                  # 构建输出目录
├── package.json           # 项目配置
├── vite.config.ts         # Vite 配置
└── tsconfig.json          # TypeScript 配置
```

## 🚀 开发环境设置

### 1. 安装依赖

```bash
cd Web
npm install
```

### 2. 启动开发服务器（iOS 集成模式）

```bash
npm run dev:ios
```

这将启动开发服务器，iOS Debug 构建的应用会自动连接到此服务器：

- ✅ **热重载**: 修改代码后，手机上的界面会立即更新
- ✅ **实时调试**: 直接在手机/模拟器上查看效果
- ✅ **开发工具**: 支持浏览器开发者工具调试
- 🌐 **服务器地址**: `http://localhost:3000`

### 3. 开发流程

1. **启动开发服务器**:
   ```bash
   npm run dev:ios
   ```

2. **在 Xcode 中运行 Debug 版本的 iOS 应用**

3. **导航到 Web 标签页** - 应用会自动连接到开发服务器

4. **修改代码** - 保存后手机界面会自动刷新

### 4. 构建生产版本

```bash
npm run build:ios
```

这将构建生产版本并自动复制到 iOS 项目中，用于 Release 构建。

## 🔧 开发模式切换

由于 Vite 构建会修改 `index.html`，我们提供了自动切换脚本来管理开发/生产模式：

### 切换到开发模式
```bash
npm run switch-dev
```
- 自动将 `index.html` 改为引用 `/src/main.tsx`（源文件）
- 准备好进行开发调试

### 切换到生产模式
```bash
npm run switch-prod
```
- 自动运行 `npm run build` 构建
- 自动更新 `index.html` 为打包版本
- 准备好集成到 iOS 应用

### 推荐开发流程
```bash
# 1. 开始开发
npm run switch-dev
npm run dev:ios

# 2. 开发过程中... 修改代码，手机会自动刷新

# 3. 开发完成，准备发布
npm run switch-prod
npm run copy-to-ios
```

## 可用脚本

### 开发相关
- `npm run dev` - 启动开发服务器
- `npm run dev:ios` - 启动 iOS 集成的开发服务器
- `npm run switch-dev` - 切换到开发模式
- `npm run switch-prod` - 切换到生产模式并构建

### 构建相关
- `npm run build` - 构建到 dist 目录
- `npm run build:ios` - 构建并集成到 iOS 项目
- `npm run build:ios:dev` - 开发模式构建并集成
- `npm run copy-to-ios` - 复制构建文件到 iOS 项目

### 其他
- `npm run preview` - 预览构建结果
- `npm run lint` - 运行 ESLint 检查

## iOS 集成

### 自动集成（推荐）

Web 模块已配置为在 Xcode 构建时自动构建：

1. 确保在 Xcode 项目的 "Build Phases" 中添加了 "Run Script" 阶段
2. 脚本路径：`Web/scripts/build-web.sh`
3. 构建时会在 `Debug` 模式下使用开发构建，`Release` 模式下使用生产构建

### 手动集成

如果需要手动构建：

```bash
# 生产构建
npm run build:ios

# 开发构建
npm run build:ios:dev
```

## 技术栈

- **React 18** - 用户界面库
- **TypeScript** - 类型安全的 JavaScript
- **Vite** - 快速的构建工具
- **ESLint** - 代码质量检查

## iOS WebView 集成

Web 模块通过以下方式与 iOS 应用集成：

1. **URL 拦截**: 使用 `local://` 协议加载本地资源
2. **资源路径**: 构建后的文件存放在 `MCCopilot/Web/` 目录
3. **WebView 配置**: 通过 `WebViewManager` 和 `LocalResourceURLSchemeHandler` 处理资源加载

## 开发工作流

### 开发新功能

1. 在 `Web/src/` 目录下开发 React 组件
2. 运行 `npm run dev` 启动开发服务器
3. 在浏览器中预览和调试
4. 使用 `npm run build:ios` 构建并测试 iOS 集成

### 调试 iOS 中的 Web 模块

1. 在 iOS 模拟器中打开应用
2. 导航到 Web 标签页
3. 使用 Safari Web Inspector 调试（Safari -> 开发 -> 模拟器 -> Web 页面）

## 部署说明

- **开发模式**: 包含源码映射，便于调试
- **生产模式**: 代码压缩优化，文件名包含哈希值
- **混合部署**: 核心功能嵌入应用，支持动态更新

## 故障排除

### 🔥 开发环境问题

#### 按钮颜色不正确
- **症状**: 按钮显示为灰色或默认颜色
- **原因**: `index.html` 引用了打包后的文件而非源文件
- **解决**: 运行 `npm run switch-dev` 切换到开发模式

#### 热重载不工作
- **症状**: 修改代码后页面不自动刷新
- **原因**: iOS WebView 对 WebSocket 连接有限制
- **解决**: 双击屏幕手动刷新，或重新启动应用

#### 页面重复刷新
- **症状**: 控制台看到重复的日志输出
- **原因**: 调试代码重复执行
- **解决**: 重新启动应用，或检查 `window.styleCheckDone` 标志

### 构建失败

1. 检查 Node.js 版本（建议 18+）
2. 清理 node_modules: `rm -rf node_modules && npm install`
3. 清理构建缓存: `rm -rf dist`

### iOS 集成问题

1. 检查 `MCCopilot/Web/index.html` 是否存在
2. 检查 `MCCopilot/Web/assets/` 目录是否存在
3. 查看 Xcode 构建日志中的错误信息

### 开发服务器问题

1. 确保端口 3000 未被占用
2. 检查防火墙设置
3. 重启开发服务器

### 📱 调试技巧

#### 查看实时日志
- Xcode 控制台会显示 WebView 的 `console.log` 输出
- 搜索 `🌐 [WebView Console]:` 找到前端日志

#### 验证开发模式
- 看到日志：`🔧 开发模式：启用调试功能和热重载`
- 看到日志：`✅ Connected to development server`
- 页面标题显示：`🚀 Web 页面 (热重载测试)`