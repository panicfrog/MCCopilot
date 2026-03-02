//
//  ReactNativeViewController.swift
//  MCCopilot
//
//  Created on 2025/11/10.
//

import React
import UIKit

/// React Native Tab视图控制器
class ReactNativeViewController: UIViewController {

    private var rootView: UIView?
    private let moduleName: String
    private let initialProps: [String: Any]?

    init(moduleName: String, initialProps: [String: Any]? = nil) {
        self.moduleName = moduleName
        self.initialProps = initialProps
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        setupReactNativeView()
    }

    private func setupReactNativeView() {
        // 从ReactNativeManager获取RCTRootView
        guard
            let rnView = ReactNativeManager.shared.createReactNativeView(
                moduleName: moduleName,
                initialProps: initialProps
            )
        else {
            showErrorView()
            return
        }

        rootView = rnView
        rnView.frame = view.bounds
        rnView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(rnView)

        print("✅ React Native视图已加载: \(moduleName)")
    }

    private func showErrorView() {
        let errorLabel = UILabel()
        errorLabel.text = "React Native加载失败\n请检查Bundle是否正确配置"
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorLabel.textColor = .red
        errorLabel.font = UIFont.systemFont(ofSize: 16)
        errorLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(errorLabel)

        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("📱 React Native视图即将显示: \(moduleName)")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("📱 React Native视图已隐藏: \(moduleName)")
    }

    deinit {
        print("🗑️ React Native视图控制器已释放: \(moduleName)")
    }
}
