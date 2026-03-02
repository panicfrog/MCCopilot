#!/bin/bash
# 构建 Apple 平台的 XCFramework
# 用法: ./build-apple.sh [--release]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

RELEASE_FLAG=""
if [ "$1" == "--release" ]; then
    RELEASE_FLAG="--release"
fi

# 从 workspace Cargo.toml 提取版本号，保持 podspec 与 Rust crate 版本一致
RUST_VERSION=$(grep '^version' "$SCRIPT_DIR/../../Cargo.toml" | head -1 | sed 's/.*"\(.*\)".*/\1/')
echo "==> Rust workspace version: $RUST_VERSION"

echo "==> Building Apple XCFramework..."

# 清理旧的构建产物
echo "==> Cleaning..."
rm -rf dist/apple
rm -rf product/apple

# 创建 target 符号链接（workspace 环境）
ln -sf ../../target target

# 构建
echo "==> Running boltffi pack apple..."
boltffi pack apple $RELEASE_FLAG

# 清理符号链接
rm -f target

# 从 dist 复制最终产物到 product
echo "==> Copying final artifacts to product..."
mkdir -p product/apple

# 复制 XCFramework
cp -R dist/apple/MccopilotBridge.xcframework product/apple/

# 复制 Package.swift（保留 SwiftPM 兼容）
cp dist/apple/Package.swift product/apple/

# 复制 Sources 目录
cp -R dist/apple/Sources product/apple/

# 生成 CocoaPods podspec（版本号来自 Rust workspace）
echo "==> Generating MccopilotBridge.podspec (version: $RUST_VERSION)..."
cat > product/apple/MccopilotBridge.podspec << PODSPEC
Pod::Spec.new do |s|
  s.name         = 'MccopilotBridge'
  s.version      = '$RUST_VERSION'
  s.summary      = 'Rust-backed cryptographic bridge for MCCopilot'
  s.homepage     = 'https://github.com/example/MCCopilot'
  s.license      = { :type => 'MIT' }
  s.author       = 'MCCopilot'
  s.source       = { :git => '', :tag => s.version.to_s }
  s.ios.deployment_target = '16.0'
  s.swift_version = '5.9'

  s.source_files = 'Sources/**/*.swift'
  s.vendored_frameworks = 'MccopilotBridge.xcframework'
end
PODSPEC

# 清理 product 中可能产生的 .build 和 .swiftpm 目录
rm -rf product/apple/.build product/apple/.swiftpm

echo "==> Done! Output:"
ls -la product/apple/

echo ""
echo "==> To use via CocoaPods:"
echo "    pod 'MccopilotBridge', :path => './Rust/crates/mccopilot/product/apple'"
echo "    Then run: pod install"
