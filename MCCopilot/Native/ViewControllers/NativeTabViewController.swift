//
//  NativeTabViewController.swift
//  MCCopilot
//
//  Created on 2025/11/10.
//

import UIKit
import SwiftUI


// MARK: - UIView Wrapper

/// 用于承载SwiftUI视图的UIView包装器
class NativeTabSwiftUIWrapperView: UIView {
    private var hostingController: UIHostingController<NativeTabSwiftUIView>?
    private var parentController: UIViewController?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configure(with parentController: UIViewController) {
        self.parentController = parentController
        setupSwiftUIView()
    }

    private func setupSwiftUIView() {
        guard let parentController = parentController else { return }

        let swiftUIView = NativeTabSwiftUIView()
        let hostingController = UIHostingController(rootView: swiftUIView)

        // 建立父子关系
        parentController.addChild(hostingController)

        addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        

        hostingController.didMove(toParent: parentController)

        self.hostingController = hostingController
    }
}

/// 原生iOS Tab视图控制器 - 使用SwiftUI包装
class NativeTabViewController: UIViewController {

    private var swiftUIWrapper: NativeTabSwiftUIWrapperView!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.systemBackground

        setupSwiftUIWrapper()
    }

    private func setupSwiftUIWrapper() {
        // 创建SwiftUI包装器
        swiftUIWrapper = NativeTabSwiftUIWrapperView()
        swiftUIWrapper.translatesAutoresizingMaskIntoConstraints = false

        // 添加到主视图
        view.addSubview(swiftUIWrapper)

        // 配置父子关系
        swiftUIWrapper.configure(with: self)

        // 设置约束
        NSLayoutConstraint.activate([
            swiftUIWrapper.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            swiftUIWrapper.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            swiftUIWrapper.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            swiftUIWrapper.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
