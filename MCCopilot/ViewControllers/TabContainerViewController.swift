//
//  TabContainerViewController.swift
//  MCCopilot
//
//  Created on 2025/11/10.
//

import UIKit

/// Tab容器视图控制器 - 根据配置动态创建Tab
class TabContainerViewController: UITabBarController {

    private var tabConfigs: [TabConfig] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // 配置TabBar外观
        setupTabBarAppearance()

        // 加载Tab配置
        loadTabConfigs()

        // 创建Tab
        createTabs()
    }

    private func setupTabBarAppearance() {
        // 使用iOS 15+的新API配置TabBar外观
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = .systemBackground

            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        } else {
            tabBar.backgroundColor = .systemBackground
            tabBar.isTranslucent = false
        }

        tabBar.tintColor = .systemBlue
    }

    private func loadTabConfigs() {
        // 从TabConfigManager加载配置
        tabConfigs = TabConfigManager.shared.loadTabConfigs()
        print("📋 加载了 \(tabConfigs.count) 个Tab配置")
    }

    private func createTabs() {
        var viewControllers: [UIViewController] = []

        for (index, config) in tabConfigs.enumerated() {
            let viewController = createViewController(for: config)

            // 设置TabBarItem
            viewController.tabBarItem = UITabBarItem(
                title: config.title,
                image: TabConfigManager.shared.getIcon(for: config.icon),
                tag: index
            )

            // 包装在NavigationController中（除了React Native和Flutter，它们有自己的导航）
            let finalViewController: UIViewController
            if config.type == .reactNative || config.type == .flutter {
                finalViewController = viewController
            } else {
                finalViewController = UINavigationController(rootViewController: viewController)
            }

            viewControllers.append(finalViewController)
        }

        self.viewControllers = viewControllers
        print("✅ 成功创建 \(viewControllers.count) 个Tab")
    }

    private func createViewController(for config: TabConfig) -> UIViewController {
        print("🎨 创建 \(config.type.rawValue) 类型的视图控制器: \(config.title)")

        switch config.type {
        case .native:
            return createNativeViewController(config: config)

        case .reactNative:
            return createReactNativeViewController(config: config)

        case .flutter:
            return createFlutterViewController(config: config)

        case .web:
            return createWebViewController(config: config)
        }
    }

    private func createNativeViewController(config: TabConfig) -> UIViewController {
        let viewController = NativeTabViewController()
        viewController.title = config.title
        return viewController
    }

    private func createReactNativeViewController(config: TabConfig) -> UIViewController {
        guard let moduleName = config.moduleName else {
            print("⚠️ React Native配置缺少moduleName")
            return createErrorViewController(message: "配置错误：缺少moduleName")
        }

        let viewController = ReactNativeViewController(moduleName: moduleName)
        viewController.title = config.title
        return viewController
    }

    private func createFlutterViewController(config: TabConfig) -> UIViewController {
        let engineIdentifier = "flutter_engine_\(config.id)"
        let entry = config.entrypoint ?? "main"

        let viewController = FlutterTabViewController(
            engineIdentifier: engineIdentifier,
            entrypoint: entry
        )

        viewController.title = config.title
        return viewController
    }

    private func createWebViewController(config: TabConfig) -> UIViewController {
        guard let urlString = config.url else {
            print("⚠️ Web配置缺少URL")
            return createErrorViewController(message: "配置错误：缺少URL")
        }

        let viewController = WebTabViewController(urlString: urlString)
        viewController.title = config.title
        return viewController
    }

    private func createErrorViewController(message: String) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground

        let errorLabel = UILabel()
        errorLabel.text = message
        errorLabel.textColor = .red
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.translatesAutoresizingMaskIntoConstraints = false

        viewController.view.addSubview(errorLabel)

        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(
                equalTo: viewController.view.leadingAnchor, constant: 40),
            errorLabel.trailingAnchor.constraint(
                equalTo: viewController.view.trailingAnchor, constant: -40),
        ])

        return viewController
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("📱 TabContainer即将显示，当前选中Tab: \(selectedIndex)")
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        print("📱 切换到Tab: \(item.title ?? "未知"), tag: \(item.tag)")
    }
}
