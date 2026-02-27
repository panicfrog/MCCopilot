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

# 复制 Package.swift
cp dist/apple/Package.swift product/apple/

# 复制 Sources 目录
cp -R dist/apple/Sources product/apple/

# 清理 product 中可能产生的 .build 和 .swiftpm 目录
rm -rf product/apple/.build product/apple/.swiftpm

echo "==> Done! Output:"
ls -la product/apple/

echo ""
echo "==> To use in Xcode:"
echo "    File → Add Package Dependencies → Add Local... → select product/apple"
