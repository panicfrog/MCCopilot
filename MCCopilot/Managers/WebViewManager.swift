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

    /// 创建配置了自定义URL拦截的WKWebView
    /// - Parameter frame: 视图框架
    /// - Returns: 配置好的WKWebView
    func createWebView(frame: CGRect) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        // 注册自定义URL scheme handler
        configuration.setURLSchemeHandler(schemeHandler, forURLScheme: "local")

        // 配置WebView偏好设置（iOS 14+ 使用 defaultWebpagePreferences）
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences

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

        print("✅ WebView创建成功，已注册local://协议拦截器")

        return webView
    }

    /// 加载本地URL
    /// - Parameters:
    ///   - webView: WKWebView实例
    ///   - urlString: URL字符串（如：local://index.html）
    func loadLocalURL(_ webView: WKWebView, urlString: String) {
        guard let url = URL(string: urlString) else {
            print("❌ 无效的URL: \(urlString)")
            return
        }

        let request = URLRequest(url: url)
        webView.load(request)
        print("📱 开始加载: \(urlString)")
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
