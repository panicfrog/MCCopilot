//
//  FlutterTabViewController.swift
//  MCCopilot
//
//  Created on 2025/11/10.
//

import Flutter
import UIKit

/// Flutter Tab视图控制器
class FlutterTabViewController: UIViewController {

    private var flutterViewController: FlutterViewController?
    private let engineIdentifier: String
    private let entrypoint: String?

    init(
        engineIdentifier: String,
        entrypoint: String? = nil
    ) {
        self.engineIdentifier = engineIdentifier
        self.entrypoint = entrypoint
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        setupFlutterView()
    }

    private func setupFlutterView() {
        // 从FlutterEngineManager获取FlutterViewController
        guard
            let flutterVC = FlutterEngineManager.shared.createViewController(
                identifier: engineIdentifier,
                entrypoint: entrypoint
            )
        else {
            showErrorView()
            return
        }

        flutterViewController = flutterVC

        // 添加为子控制器
        addChild(flutterVC)
        flutterVC.view.frame = view.bounds
        flutterVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(flutterVC.view)
        flutterVC.didMove(toParent: self)

        print("✅ Flutter视图已加载: \(engineIdentifier), 入口点: \(entrypoint ?? "main")")
    }

    private func showErrorView() {
        let errorLabel = UILabel()
        errorLabel.text = "Flutter加载失败\n请检查Flutter模块是否正确配置"
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
        print("📱 Flutter视图即将显示: \(engineIdentifier)")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("📱 Flutter视图已隐藏: \(engineIdentifier)")
    }

    deinit {
        // 注意：这里不释放engine，因为它可能被其他地方使用
        // 如果需要释放，应该在适当的时机调用FlutterEngineManager.shared.releaseEngine()
        print("🗑️ Flutter视图控制器已释放: \(engineIdentifier)")
    }
}
