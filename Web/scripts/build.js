#!/usr/bin/env node

import { execSync } from 'child_process';
import { existsSync, rmSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.join(__dirname, '..');

// ANSI color codes for better output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  blue: '\x1b[34m',
  yellow: '\x1b[33m',
  red: '\x1b[31m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function execCommand(command, description) {
  try {
    log(`🔄 ${description}...`, 'blue');
    execSync(command, { cwd: projectRoot, stdio: 'inherit' });
    log(`✅ ${description} 完成`, 'green');
  } catch (error) {
    log(`❌ ${description} 失败: ${error.message}`, 'red');
    process.exit(1);
  }
}

// Check if we're in development or production mode
const mode = process.argv.includes('--dev') ? 'development' : 'production';

// Check for Xcode build environment
const isXcodeBuild = process.env.CONFIGURATION !== undefined;
const xcodeMode = process.env.CONFIGURATION === 'Debug' ? 'development' : 'production';
const finalMode = isXcodeBuild ? xcodeMode : mode;

log(`🚀 开始构建 React Web 模块 (${finalMode} 模式)`, 'yellow');
if (isXcodeBuild) {
  log(`📱 Xcode 构建环境: ${process.env.CONFIGURATION}`, 'blue');
}

// Clean previous build
const distPath = path.join(projectRoot, 'dist');
if (existsSync(distPath)) {
  rmSync(distPath, { recursive: true, force: true });
  log('🧹 清理上一次构建产物', 'blue');
}

// Build the React app
const buildCommand = finalMode === 'development'
  ? 'npm run build'
  : 'npm run build -- --mode production';

execCommand(buildCommand, '构建 React 应用');

// Copy to iOS project - the iOS Web directory is the same as the current Web directory
// iOS Bundle will look for Web directory in the main bundle
let iosWebPath = projectRoot;
log(`🔍 iOS Web 资源将复制到: ${iosWebPath}`, 'blue');

// Clean iOS Web directory (except backup and other project files)
const iosIndexPath = path.join(iosWebPath, 'index.html');
const iosAssetsPath = path.join(iosWebPath, 'assets');

if (existsSync(iosIndexPath)) {
  rmSync(iosIndexPath);
}
if (existsSync(iosAssetsPath)) {
  rmSync(iosAssetsPath, { recursive: true, force: true });
}

// Copy built files to current directory (which will be the Web directory in iOS bundle)
execCommand('cp dist/index.html ./', '复制 index.html 到 Web 目录');
execCommand('cp -r dist/assets ./', '复制 assets 目录到 Web 目录');

// Verify the build
const builtIndexPath = path.join(iosWebPath, 'index.html');
if (existsSync(builtIndexPath)) {
  log('🎉 构建成功！Web 模块已更新到 iOS 项目', 'green');
  log(`📱 iOS Web 路径: ${iosWebPath}`, 'blue');

  if (finalMode === 'development') {
    log('💡 提示: 开发模式构建完成，包含源码映射便于调试', 'yellow');
  } else {
    log('🚀 提示: 生产模式构建完成，代码已优化压缩', 'yellow');
  }
} else {
  log('❌ 构建验证失败，请检查构建产物', 'red');
  process.exit(1);
}