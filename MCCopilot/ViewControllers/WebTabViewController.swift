//
//  WebTabViewController.swift
//  MCCopilot
//
//  Created on 2025/11/10.
//

import UIKit
import WebKit

/// Web Tab视图控制器
class WebTabViewController: UIViewController, WKScriptMessageHandler {

    private var webView: WKWebView?
    private let urlString: String
    private var progressView: UIProgressView?
    private var observation: NSKeyValueObservation?

    init(urlString: String) {
        self.urlString = urlString
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        setupWebView()
        setupProgressView()
        loadURL()
    }

    private func setupWebView() {
        // 从WebViewManager创建WebView
        let webView = WebViewManager.shared.createWebView(frame: view.bounds)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // 添加 console.log 拦截
        webView.configuration.userContentController.add(self, name: "logging")

        // 注入 JavaScript 来转发 console.log
        let consoleLogScript = """
            (function() {
                var oldLog = console.log;
                console.log = function(message) {
                    oldLog.apply(console, arguments);
                    window.webkit.messageHandlers.logging.postMessage(String(message));
                };
            })();
            """
        let script = WKUserScript(
            source: consoleLogScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(script)

        view.addSubview(webView)
        self.webView = webView

        // 监听加载进度
        observation = webView.observe(\.estimatedProgress, options: [.new]) {
            [weak self] webView, _ in
            self?.progressView?.progress = Float(webView.estimatedProgress)
        }
    }

    // MARK: - WKScriptMessageHandler
    func userContentController(
        _ userContentController: WKUserContentController, didReceive message: WKScriptMessage
    ) {
        if message.name == "logging" {
            print("🌐 [WebView Console]: \(message.body)")
        }
    }

    private func setupProgressView() {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2),
        ])

        self.progressView = progressView
    }

    
    private func loadURL() {
        guard let webView = webView else { return }

        // 判断是local://还是远程URL
        if urlString.hasPrefix("local://") {
            // 获取实际加载的URL用于日志显示
            let actualURL = WebViewManager.shared.getActualURL(for: urlString)
            print("📱 开始加载: \(actualURL) (原始请求: \(urlString))")

            // 开发模式下清除缓存以确保最新样式
            if actualURL.contains("localhost:3000") {
                print("🧹 开发模式：清除WebView缓存")
                WebViewManager.shared.clearCache {
                    print("✅ 缓存清除完成，开始加载页面")
                    WebViewManager.shared.loadLocalURL(webView, urlString: self.urlString)
                }
            } else {
                WebViewManager.shared.loadLocalURL(webView, urlString: urlString)
            }
        } else {
            print("📱 开始加载: \(urlString)")
            WebViewManager.shared.loadRemoteURL(webView, urlString: urlString)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let displayURL = urlString.hasPrefix("local://") ? WebViewManager.shared.getActualURL(for: urlString) : urlString
        print("📱 Web视图即将显示: \(displayURL) (原始: \(urlString))")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("📱 Web视图已隐藏: \(urlString)")
    }

    deinit {
        observation?.invalidate()
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "logging")
        print("🗑️ Web视图控制器已释放: \(urlString)")
    }
}

// MARK: - WKNavigationDelegate
extension WebTabViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressView?.isHidden = false
        progressView?.progress = 0
        print("🔄 开始加载页面")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressView?.isHidden = true
        print("✅ 页面加载完成")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        progressView?.isHidden = true
        print("❌ 页面加载失败: \(error.localizedDescription)")
        showErrorAlert(error: error)
    }

    func webView(
        _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        progressView?.isHidden = true
        print("❌ 页面加载失败: \(error.localizedDescription)")
        showErrorAlert(error: error)
    }

    private func showErrorAlert(error: Error) {
        let alert = UIAlertController(
            title: "加载失败",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        alert.addAction(
            UIAlertAction(title: "重试", style: .default) { [weak self] _ in
                self?.loadURL()
            })
        present(alert, animated: true)
    }
}

// MARK: - WKUIDelegate
extension WebTabViewController: WKUIDelegate {

    func webView(
        _ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        // 处理target="_blank"的链接
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
