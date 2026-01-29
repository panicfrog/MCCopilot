// 开发环境专用的调试组件
import { useEffect } from 'react'

declare global {
  interface Window {
    __DEV__?: boolean
  }
}

export function DevPanel() {
  const isDev = import.meta.env.DEV || window.__DEV__

  useEffect(() => {
    if (!isDev) return

    // 开发环境下的特殊功能
    console.log('🔧 DevPanel mounted')

    // 添加键盘快捷键
    const handleKeyPress = (e: KeyboardEvent) => {
      if (e.ctrlKey && e.shiftKey && e.key === 'D') {
        console.log('🐛 Debug mode toggled')
      }
    }

    window.addEventListener('keydown', handleKeyPress)
    return () => window.removeEventListener('keydown', handleKeyPress)
  }, [isDev])

  if (!isDev) return null

  return (
    <div style={{
      position: 'fixed',
      top: '10px',
      right: '10px',
      background: 'rgba(0, 0, 0, 0.8)',
      color: 'white',
      padding: '8px',
      borderRadius: '4px',
      fontSize: '12px',
      zIndex: 9999
    }}>
      <div>🔧 DEV MODE</div>
      <div style={{ fontSize: '10px', opacity: 0.7 }}>
        Ctrl+Shift+D: Debug
      </div>
    </div>
  )
}