import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { resolve } from 'path'

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => {
  const isDevelopment = mode === 'development'

  return {
    plugins: [react()],
    root: '.',
    publicDir: 'public',
    build: {
      outDir: 'dist',
      assetsDir: 'assets',
      sourcemap: isDevelopment,
      minify: isDevelopment ? false : 'terser',
      rollupOptions: {
        input: resolve(__dirname, 'index.html'),
        output: {
          // 开发模式下使用固定文件名，避免缓存问题
          entryFileNames: isDevelopment ? 'assets/index.js' : 'assets/[name].[hash].js',
          chunkFileNames: isDevelopment ? 'assets/[name].js' : 'assets/[name].[hash].js',
          assetFileNames: isDevelopment ? 'assets/index.css' : 'assets/[name].[hash].[ext]'
        }
      }
    },
    server: {
      port: 3000,
      host: '0.0.0.0', // 允许局域网访问
      cors: true,
      strictPort: true,
      hmr: {
        port: 3000,
        host: 'localhost'
      }
    },
    define: {
      __DEV__: isDevelopment,
      __PROD__: !isDevelopment
    }
  }
})