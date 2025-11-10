//
//  NativeTabViewController.swift
//  MCCopilot
//
//  Created on 2025/11/10.
//

import UIKit

/// 原生iOS Tab视图控制器
class NativeTabViewController: UIViewController {

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let infoCard = UIView()
    private let stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.systemBackground

        setupUI()
    }

    private func setupUI() {
        // 标题
        titleLabel.text = "原生 iOS 页面"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // 副标题
        subtitleLabel.text = "使用 Swift + UIKit 开发"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)

        // 信息卡片
        infoCard.backgroundColor = .systemBackground
        infoCard.layer.cornerRadius = 12
        infoCard.layer.shadowColor = UIColor.black.cgColor
        infoCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        infoCard.layer.shadowOpacity = 0.1
        infoCard.layer.shadowRadius = 8
        infoCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(infoCard)

        // 创建信息堆栈
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(stackView)

        // 添加信息项
        let cardTitle = createLabel(
            text: "欢迎使用混合架构", font: .systemFont(ofSize: 20, weight: .semibold))
        stackView.addArrangedSubview(cardTitle)

        let divider = UIView()
        divider.backgroundColor = .separator
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stackView.addArrangedSubview(divider)

        stackView.addArrangedSubview(createInfoItem(icon: "📱", text: "原生 iOS 开发"))
        stackView.addArrangedSubview(createInfoItem(icon: "⚛️", text: "React Native 支持"))
        stackView.addArrangedSubview(createInfoItem(icon: "🐦", text: "Flutter 支持"))
        stackView.addArrangedSubview(createInfoItem(icon: "🌐", text: "Web 支持"))
        stackView.addArrangedSubview(createInfoItem(icon: "⚙️", text: "配置驱动的 Tab 系统"))

        // 布局约束
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            infoCard.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            infoCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            stackView.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -20),
        ])
    }

    private func createLabel(text: String, font: UIFont) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textAlignment = .center
        return label
    }

    private func createInfoItem(icon: String, text: String) -> UIView {
        let container = UIView()

        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = UIFont.systemFont(ofSize: 20)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconLabel)

        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = UIFont.systemFont(ofSize: 16)
        textLabel.textColor = .secondaryLabel
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textLabel)

        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 30),

            textLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),
            textLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textLabel.topAnchor.constraint(equalTo: container.topAnchor),
            textLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }
}
