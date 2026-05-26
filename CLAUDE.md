# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MCCopilot is an iOS hybrid app integrating four technology stacks: Native iOS (Swift), React Native 0.77, Flutter 3.32.8, and Web (Vite/React). The app uses a JSON-driven tab system where each tab can be powered by any of these stacks.

## Common Commands

### Initial Setup (first time or after clean)
```bash
cd ReactNative && npm install && cd ..
cd Flutter && flutter pub get && cd ..
cd Flutter && flutter build ios-framework --no-profile && cd ..
pod install
```

### Development

**Start Metro bundler (React Native):**
```bash
cd ReactNative && npm start
```

**Build Flutter framework (after Flutter code changes):**
```bash
cd Flutter && flutter build ios-framework --no-profile && cd .. && pod install
```

**Build Web assets (after Web code changes):**
```bash
cd Web && npm run build:ios && npm run copy-to-ios && cd ..
```

**Run the app:** Open `MCCopilot.xcworkspace` in Xcode, press `Cmd+R`

### Linting & Type Checking
```bash
# React Native
cd ReactNative && npm run type-check
cd ReactNative && npm run lint

# Web
cd Web && npm run lint

# Rust
cd Rust && cargo clippy
```

### Bundling for Production
```bash
cd ReactNative && npm run bundle-ios       # production JS bundle
cd ReactNative && npm run bundle-ios-dev   # debug JS bundle
```

### Full Clean
```bash
cd ReactNative && rm -rf node_modules package-lock.json && npm install && cd ..
cd Flutter && flutter clean && flutter pub get && flutter build ios-framework --no-profile && cd ..
rm -rf Pods Podfile.lock && pod install
```

## Architecture

### Tab-Driven Hybrid Architecture

`AppDelegate` initializes all managers, then `TabContainerViewController` reads `MCCopilot/Config/tab_config.json` to dynamically create tabs. Each tab type maps to a specific ViewController:

| Tab type | ViewController | Manager |
|---|---|---|
| `native` | `NativeTabViewController` | — |
| `react-native` | `ReactNativeViewController` | `ReactNativeManager` (singleton RCTBridge) |
| `flutter` | `FlutterTabViewController` | `FlutterEngineManager` (FlutterEngineGroup) |
| `web` | `WebTabViewController` | `WebViewManager` (WKURLSchemeHandler for `local://`) |

### Key Patterns

- **React Native**: Single RCTBridge shared across all RN tabs via RCTRootViewFactory (New Architecture). Uses Hermes engine. Bundling via Callstack Repack (Webpack-based, not Metro).
- **Flutter**: FlutterEngineGroup creates multiple engines sharing one Dart VM. Each Flutter tab uses a different entry point (`main()`, `shoppingMain()`, `profileMain()`) in `Flutter/lib/main.dart`, annotated with `@pragma('vm:entry-point')`.
- **Web**: Vite-built React app. Build outputs to `Web/dist/`, then `copy-to-ios` copies assets into the Xcode project. Loaded via custom `local://` URL scheme.
- **Rust**: Workspace at `Rust/` with four crates. `mccopilot-lib` is the core library (crypto, network, plugins). `mccopilot` provides FFI bindings via BoltFFI for Swift/Android. `mccopilot-dart` provides Dart bindings. `mccopilot-plugin` is a WASM plugin runtime.

### React Native ↔ Rust Bridge

`ReactNative/packages/react-native-mccopilot` is a NitroModules-based native module that provides JSI access to Rust crypto functions. The flow is: TypeScript → NitroModules (`.nitro.ts` spec) → generated Swift → Rust FFI.

## Directory Layout (key paths)

- `MCCopilot/` — iOS native app (Swift): AppDelegate, Managers, ViewControllers, Config
- `ReactNative/` — RN source: `src/` for components, `packages/react-native-mccopilot` for native module
- `Flutter/lib/` — Dart code with multi-entry-point main.dart
- `Web/src/` — React + Vite web app
- `Rust/crates/` — `mccopilot-lib`, `mccopilot` (FFI), `mccopilot-dart`, `mccopilot-plugin`
- `MCCopilot/Config/tab_config.json` — Tab configuration

## Important Notes

- Always open `MCCopilot.xcworkspace`, not `.xcodeproj`
- Xcode Build Setting **User Script Sandboxing** must be `No` (required for Hermes + Repack)
- iOS deployment target: 16.0
- React Native New Architecture is enabled (`RCT_NEW_ARCH_ENABLED=1` in Podfile)
- Flutter changes require rebuilding the iOS framework (`flutter build ios-framework --no-profile`) followed by `pod install`
- Podfile includes Rust crate `MccopilotBridge` via CocoaPods at `Rust/crates/mccopilot/product/apple`
