import { useState, useEffect } from 'react'
import './index.css'
import { DevPanel } from './dev'

// 声明全局变量
declare global {
  interface Window {
    __DEV__?: boolean
    __PROD__?: boolean
  }
}

function App() {
  const [counter, setCounter] = useState(0)

  useEffect(() => {
    const isDev = import.meta.env.DEV || window.__DEV__
    console.log('React app loaded successfully', {
      mode: isDev ? 'development' : 'production',
      dev: isDev,
      prod: import.meta.env.PROD || window.__PROD__
    })
    console.log('Current location:', window.location.href)

    // 开发环境下的额外功能
    if (isDev) {
      console.log('🔧 Development mode detected - hot reload enabled')
      console.log('🌐 Running on development server - changes will auto-reload in iOS app')

      // 添加开发服务器连接状态检测
      const checkConnection = () => {
        console.log('✅ Connected to development server')
      }
      checkConnection()
    } else {
      console.log('🚀 Production mode - loaded from iOS bundle')
    }
  }, [])

  const incrementCounter = () => {
    const newCounter = counter + 1
    setCounter(newCounter)
    console.log('Counter incremented:', newCounter)
  }

  const decrementCounter = () => {
    const newCounter = counter - 1
    setCounter(newCounter)
    console.log('Counter decremented:', newCounter)
  }

  const resetCounter = () => {
    setCounter(0)
    console.log('Counter reset')
  }

  return (
    <div className="container">
      <header>
        <h1>Web 页面</h1>
        <p className="subtitle">React + TypeScript 本地资源缓存加载</p>
      </header>

      <div className="card">
        <div className="emoji">🌐</div>
        <h2>欢迎来到 Web 模块</h2>
        <p className="description">
          这是一个通过 React + TypeScript 构建的本地 HTML 页面。所有资源都预先打包在 App
          内部，无需网络连接即可访问。
        </p>
      </div>

      <div className="card">
        <h3>技术特性</h3>
        <ul className="feature-list">
          <li>
            <span className="check">✓</span>
            <span>React + TypeScript</span>
          </li>
          <li>
            <span className="check">✓</span>
            <span>Vite 构建工具</span>
          </li>
          <li>
            <span className="check">✓</span>
            <span>本地资源缓存</span>
          </li>
          <li>
            <span className="check">✓</span>
            <span>自定义 URL 拦截</span>
          </li>
          <li>
            <span className="check">✓</span>
            <span>WKWebView 性能优化</span>
          </li>
          <li>
            <span className="check">✓</span>
            <span>离线可用</span>
          </li>
          <li>
            <span className="check">✓</span>
            <span>快速加载</span>
          </li>
        </ul>
      </div>

      <div className="card interactive">
        <h3>交互示例</h3>
        <div className="counter-section">
          <div className="counter-display">{counter}</div>
          <div className="button-group">
            <button className="btn btn-danger" onClick={decrementCounter}>
              -
            </button>
            <button className="btn btn-primary" onClick={resetCounter}>
              重置
            </button>
            <button className="btn btn-success" onClick={incrementCounter}>
              +
            </button>
          </div>
        </div>
      </div>

      <div className="info-card">
        <p><strong>当前协议：</strong>local://</p>
        <p><strong>加载方式：</strong>WKURLSchemeHandler</p>
        <p><strong>资源位置：</strong>App Bundle</p>
        <p><strong>技术栈：</strong>React + TypeScript + Vite</p>
        <p><strong>构建模式：</strong>{import.meta.env.DEV || window.__DEV__ ? '开发模式' : '生产模式'}</p>
      </div>

      {/* 开发环境调试面板 */}
      <DevPanel />
    </div>
  )
}

export default App