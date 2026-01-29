#!/usr/bin/env node

import { readFileSync, writeFileSync } from 'fs'
import { fileURLToPath } from 'url'
import path from 'path'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const indexPath = path.join(__dirname, '..', 'index.html')

// 读取当前 index.html
let content = readFileSync(indexPath, 'utf8')

const isDevelopment = process.argv[2] === '--dev'

if (isDevelopment) {
  // 开发模式：使用源文件
  console.log('🔧 切换到开发模式')

  // 替换为开发模式的引用
  content = content.replace(
    /<script type="module"[^>]*src="\/assets\/[^"]*"[^>]*><\/script>/,
    '<script type="module" src="/src/main.tsx"></script>'
  )

  content = content.replace(
    /<link[^>]*rel="stylesheet"[^>]*href="\/assets\/[^"]*"[^>]*>/,
    ''
  )

  console.log('✅ 已切换到开发模式，将加载 /src/main.tsx')
} else {
  // 生产模式：使用打包文件
  console.log('🚀 切换到生产模式')

  // 运行构建
  const { spawn } = await import('child_process')

  await new Promise((resolve, reject) => {
    const build = spawn('npm', ['run', 'build'], {
      stdio: 'inherit',
      shell: true,
      cwd: path.join(__dirname, '..')
    })

    build.on('close', (code) => {
      if (code === 0) {
        console.log('✅ 构建完成，index.html 已更新为生产版本')
        resolve()
      } else {
        console.error('❌ 构建失败')
        reject(new Error('Build failed'))
      }
    })
  })
}

// 写回文件
writeFileSync(indexPath, content, 'utf8')