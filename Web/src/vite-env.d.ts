/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly DEV: boolean
  readonly PROD: boolean
  readonly MODE: string
  readonly VITE_APP_TITLE: string
  // 更多环境变量...
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}