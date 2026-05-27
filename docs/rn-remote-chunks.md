# React Native 远程分包方案

## 概述

项目使用 Re.Pack (Rspack) 实现动态分包，将 React Native 页面拆分为独立 chunk，通过 `mccopilot-server` 分发到客户端。支持版本管理、哈希校验和本地缓存。

## 架构流程

```
开发阶段:
  React.lazy(() => import('./src/SecondRNApp'))
       ↓
  rspack.config.mjs (splitChunks: 'async')
       ↓
  npm run bundle-ios
       ↓
  build/outputs/ios/remotes/SecondRNApp.chunk.bundle

发布阶段:
  scripts/build-manifest.mjs → manifest.json (含 SHA-256)
       ↓
  scripts/upload-chunks.sh → mccopilot-server (MinIO/S3)

客户端加载:
  chunkResolver.ts
    ├── __DEV__: Script.getDevServerURL() → Re.Pack dev server
    └── Release:
         1. 获取 manifest (JS 侧缓存)
         2. 检查本地缓存 (hash 匹配)
         3. 下载 chunk → SHA-256 校验 → 缓存到本地
         4. 加载 chunk
```

## 关键文件

| 文件 | 作用 |
|---|---|
| `ReactNative/rspack.config.mjs` | Re.Pack/Rspack 配置，定义分包规则 |
| `ReactNative/src/chunkResolver.ts` | 客户端 chunk 加载解析器（dev/release 双模式） |
| `ReactNative/src/config.ts` | API 服务器地址配置 |
| `scripts/build-manifest.mjs` | 从 chunk 文件生成 manifest.json（含 hash） |
| `scripts/upload-chunks.sh` | 一键构建 + 生成 manifest + 上传到服务器 |
| `scripts/manifest.json` | chunk 清单（hash、size、path） |
| `Rust/crates/mccopilot-server/` | Rust 后端服务（Axum + MinIO） |

## 如何新增一个远程 RN 页面

### 1. 创建页面组件

在 `ReactNative/src/` 下创建新组件，确保有 `export default`：

```tsx
// ReactNative/src/ThirdRNApp.tsx
const ThirdRNApp: React.FC = () => {
  return <View><Text>New Remote Page</Text></View>;
};
export default ThirdRNApp;
```

### 2. 在 index.tsx 中注册为 lazy chunk

```tsx
const ThirdRNApp = React.lazy(
  () => import(/* webpackChunkName: "ThirdRNApp" */ './src/ThirdRNApp'),
);

const ThirdRNAppWrapper: React.FC = () => (
  <Suspense fallback={<LoadingFallback />}>
    <ThirdRNApp />
  </Suspense>
);

AppRegistry.registerComponent('ThirdRNApp', () => ThirdRNAppWrapper);
```

`webpackChunkName` 决定 chunk 文件名，必须唯一。

### 3. 在 tab_config.json 中配置

```json
{
  "id": "tab5",
  "title": "新远程页面",
  "type": "react-native",
  "moduleName": "ThirdRNApp",
  "icon": "star.fill"
}
```

### 4. 构建并上传

```bash
bash scripts/upload-chunks.sh
```

此脚本会自动：构建 bundle → 生成 manifest → 上传 chunk 和 manifest。

### 5. Xcode Release 模式运行验证

## 操作命令

```bash
# 仅构建 bundle（生成 main.jsbundle + chunk 文件）
cd ReactNative && npm run bundle-ios

# 仅生成 manifest
node scripts/build-manifest.mjs

# 一键构建 + 上传（推荐）
bash scripts/upload-chunks.sh

# 仅启动 Rust 服务器
cd Rust && cargo run --bin mccopilot-server

# 上传时指定服务器地址
API_BASE_URL=http://your-server:3000 bash scripts/upload-chunks.sh
```

## 环境依赖

- **MinIO**: Docker 容器运行在 `localhost:9000`，S3 兼容存储
- **mccopilot-server**: Rust 后端，默认 `localhost:3000`
- 配置文件: `Rust/crates/mccopilot-server/.env`

## 注意事项

- `React.lazy` 的 `webpackChunkName` 注释必须与组件名一致，这是 Re.Pack 识别 chunk 的依据
- Release 模式下客户端会校验 chunk 的 SHA-256 hash，hash 不匹配会拒绝加载
- `chunkResolver.ts` 中 manifest 有 JS 侧内存缓存，重启 app 才会重新获取
- Dev 模式下不走服务器，直接从 Re.Pack dev server 加载 chunk
- `main.jsbundle`（主包）随 app 一起打包，chunk 文件需要上传到服务器
