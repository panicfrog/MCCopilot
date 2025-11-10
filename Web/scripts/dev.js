#!/usr/bin/env node

import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import path from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Colors for output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  blue: '\x1b[34m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

log('🚀 启动 React Web 开发服务器', 'yellow');
log('📱 iOS 应用将自动连接到此开发服务器', 'cyan');
log('🔧 支持热重载 - 修改代码将立即在手机上显示', 'cyan');
log('🌐 服务器地址: http://localhost:3000', 'blue');
log('', 'reset');

// 启动 Vite 开发服务器
const viteProcess = spawn('npm', ['run', 'dev'], {
  stdio: 'inherit',
  shell: true,
  cwd: path.join(__dirname, '..')
});

viteProcess.on('close', (code) => {
  if (code !== 0) {
    log(`❌ 开发服务器退出，代码: ${code}`, 'red');
    process.exit(code);
  }
});

// 处理退出信号
process.on('SIGINT', () => {
  log('\n🛑 正在关闭开发服务器...', 'yellow');
  viteProcess.kill('SIGINT');
});

process.on('SIGTERM', () => {
  log('\n🛑 正在关闭开发服务器...', 'yellow');
  viteProcess.kill('SIGTERM');
});