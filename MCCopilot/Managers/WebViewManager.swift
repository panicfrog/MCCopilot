//
//  WebViewManager.swift
//  MCCopilot
//
//  Created on 2025/11/10.
//

import Foundation
import WebKit

/// 本地资源URL拦截处理器
class LocalResourceURLSchemeHandler: NSObject, WKURLSchemeHandler {

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(
                NSError(domain: "WebViewManager", code: -1, userInfo: nil))
            return
        }

        print("📥 拦截URL: \(url.absoluteString)")

        // 解析local://协议的URL
        // 注意：url.path 可能为空，url.host 包含实际的文件名
        var fileName = ""
        if let host = url.host, !host.isEmpty {
            // 如果 host 存在，使用 host（如 local://style.css 中的 style.css）
            fileName = host
        } else {
            // 否则使用 path（如 local:///index.html 中的 /index.html）
            let path = url.path.isEmpty ? "/index.html" : url.path
            fileName = (path as NSString).lastPathComponent
        }

        let fileExtension = (fileName as NSString).pathExtension
        let resourceName = (fileName as NSString).deletingPathExtension

        print(
            "   📄 解析: url.host=\(url.host ?? "nil"), url.path=\(url.path), fileName=\(fileName), resourceName=\(resourceName), ext=\(fileExtension)"
        )

        // 从Web目录加载资源
        guard
            let resourcePath = Bundle.main.path(
                forResource: resourceName, ofType: fileExtension, inDirectory: "Web")
        else {
            print("❌ 找不到资源文件: \(fileName) (resourceName: \(resourceName), ext: \(fileExtension))")
            print("   Bundle路径: \(Bundle.main.bundlePath)")
            urlSchemeTask.didFailWithError(
                NSError(
                    domain: "WebViewManager", code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Resource not found"]))
            return
        }

        print("   ✅ 找到资源: \(resourcePath)")

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: resourcePath))
            let mimeType = getMimeType(for: fileExtension)

            let response = URLResponse(
                url: url,
                mimeType: mimeType,
                expectedContentLength: data.count,
                textEncodingName: "utf-8"
            )

            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()

            print("✅ 成功加载资源: \(fileName) (\(mimeType))")
        } catch {
            print("❌ 加载资源失败: \(error)")
            urlSchemeTask.didFailWithError(error)
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // 取消任务
        print("🛑 取消URL任务")
    }

    /// 根据文件扩展名获取MIME类型
    private func getMimeType(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "html", "htm":
            return "text/html"
        case "css":
            return "text/css"
        case "js":
            return "application/javascript"
        case "json":
            return "application/json"
        case "png":
            return "image/png"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "gif":
            return "image/gif"
        case "svg":
            return "image/svg+xml"
        case "ico":
            return "image/x-icon"
        case "txt":
            return "text/plain"
        case "pdf":
            return "application/pdf"
        default:
            return "application/octet-stream"
        }
    }
}

/// WebView管理器
class WebViewManager {

    static let shared = WebViewManager()

    private let schemeHandler = LocalResourceURLSchemeHandler()

    private init() {}

    /// 检测当前是否为开发模式
    private var isDevelopmentMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    /// 创建配置了自定义URL拦截的WKWebView
    /// - Parameter frame: 视图框架
    /// - Returns: 配置好的WKWebView
    func createWebView(frame: CGRect) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        // 根据构建模式配置WebView
        if isDevelopmentMode {
            print("🔧 开发模式：启用调试功能和热重载")
            // 开发模式下允许混合内容和调试
            let preferences = WKWebpagePreferences()
            preferences.allowsContentJavaScript = true

            // 允许在开发模式下加载不安全的内容
            if #available(iOS 14.0, *) {
                configuration.limitsNavigationsToAppBoundDomains = false
            }

            // 开发模式下允许混合内容以支持WebSocket连接
            if #available(iOS 10.0, *) {
                configuration.mediaTypesRequiringUserActionForPlayback = []
            }

            configuration.defaultWebpagePreferences = preferences
        } else {
            print("🚀 生产模式：使用标准配置")
            // 生产模式的标准配置
            let preferences = WKWebpagePreferences()
            preferences.allowsContentJavaScript = true
            configuration.defaultWebpagePreferences = preferences
        }

        // 注册自定义URL scheme handler（生产模式需要）
        configuration.setURLSchemeHandler(schemeHandler, forURLScheme: "local")

        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

        // 启用内联媒体播放
        configuration.allowsInlineMediaPlayback = true

        // 配置数据存储
        let dataStore = WKWebsiteDataStore.default()
        configuration.websiteDataStore = dataStore

        let webView = WKWebView(frame: frame, configuration: configuration)
        webView.backgroundColor = .white

        // 允许返回手势
        webView.allowsBackForwardNavigationGestures = true

        // 禁用滚动反弹效果，避免与点击冲突
        webView.scrollView.bounces = false
        // 禁用滚动条
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false

        // 禁用缩放功能 - 移动端关键设置
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0

        // 禁用双击缩放
        if #available(iOS 10.0, *) {
            configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        }

        // 防止用户选择和缩放
        webView.scrollView.delaysContentTouches = false
        webView.scrollView.canCancelContentTouches = false

        // 开发模式下的额外配置
        if isDevelopmentMode {
            // 启用调试
            if #available(iOS 16.4, *) {
                webView.isInspectable = true
            }
        }

        print("✅ WebView创建成功，模式：\(isDevelopmentMode ? "开发" : "生产")")

        return webView
    }

    /// 获取实际要加载的URL（用于日志显示）
    /// - Parameter urlString: 原始URL字符串
    /// - Returns: 实际加载的URL
    func getActualURL(for urlString: String) -> String {
        if isDevelopmentMode && urlString == "local://index.html" {
            return "http://localhost:3000"
        } else {
            return urlString
        }
    }

    /// 加载Web URL（自动选择开发或生产模式）
    /// - Parameters:
    ///   - webView: WKWebView实例
    ///   - urlString: URL字符串（如：local://index.html）
    func loadLocalURL(_ webView: WKWebView, urlString: String) {
        let finalURL: String

        if isDevelopmentMode && urlString == "local://index.html" {
            // 开发模式：访问本地开发服务器
            finalURL = "http://localhost:3000"
            print("🔧 开发模式：加载开发服务器")
        } else {
            // 生产模式：使用Bundle中的资源
            finalURL = urlString
            print("🚀 生产模式：加载Bundle资源")
        }

        guard let url = URL(string: finalURL) else {
            print("❌ 无效的URL: \(finalURL)")
            return
        }

        let request = URLRequest(url: url)
        webView.load(request)
        print("📱 开始加载: \(finalURL)")
    }

    /// 加载远程URL
    /// - Parameters:
    ///   - webView: WKWebView实例
    ///   - urlString: URL字符串
    func loadRemoteURL(_ webView: WKWebView, urlString: String) {
        guard let url = URL(string: urlString) else {
            print("❌ 无效的URL: \(urlString)")
            return
        }

        let request = URLRequest(url: url)
        webView.load(request)
        print("🌐 开始加载远程URL: \(urlString)")
    }

    /// 清除WebView缓存
    func clearCache(completion: (() -> Void)? = nil) {
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let dateFrom = Date(timeIntervalSince1970: 0)

        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: dateFrom) {
            print("🗑️ WebView缓存已清除")
            completion?()
        }
    }
}
