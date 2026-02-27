//
//  NativeTabSwiftUI.swift
//  MCCopilot
//
//  Created on 2025/11/13.
//

import SwiftUI
import MccopilotBridge

// MARK: - SwiftUI Views

/// SwiftUI版本的NativeTabView内容
struct NativeTabSwiftUIView: View {
    @State private var cryptoTestResult: String = "点击测试加密功能"

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // 标题区域
                VStack(spacing: 8) {
                    Text("原生 iOS 页面 sss")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("使用 Swift + SwiftUI 开发")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                // 信息卡片
                InfoCardView()
                    .padding(.horizontal, 20)

                // 加密测试区域
                CryptoTestView(testResult: $cryptoTestResult)
                    .padding(.horizontal, 20)

                Spacer()
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

/// 加密测试视图
struct CryptoTestView: View {
    @Binding var testResult: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🔐 加密功能测试")
                .font(.system(size: 20, weight: .semibold))

            Button(action: testCrypto) {
                Text("测试 AES-GCM 加密")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }

            Button(action: testHash) {
                Text("测试 SHA-256 哈希")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(8)
            }

            Button(action: testArgon2) {
                Text("测试 Argon2 密码哈希")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .cornerRadius(8)
            }

            Text(testResult)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func testCrypto() {
        // 生成随机 Nonce (12 字节)
        let nonceResult = cryptoAesGcmGenerateNonce()
        guard nonceResult.success else {
            testResult = "生成 Nonce 失败: \(nonceResult.error ?? "未知错误")"
            return
        }
        let nonce = nonceResult.data

        // 生成随机 Key - 使用 HKDF 从固定种子派生 32 字节密钥
        let salt = ByteArray(data: "salt".data(using: .utf8)!)
        let ikm = ByteArray(data: "input_key_material_for_aes256".data(using: .utf8)!)
        let keyResult = cryptoHkdfDerive(salt: salt, ikm: ikm, info: nil, outputLength: 32)
        guard keyResult.success else {
            testResult = "生成 Key 失败: \(keyResult.error ?? "未知错误")"
            return
        }
        let aesKey = keyResult.data

        // 加密
        let plaintext = ByteArray(data: "Hello, MCCopilot!".data(using: .utf8)!)
        let encryptResult = cryptoAesGcmEncrypt(
            key: ByteArray(data: aesKey),
            nonce: ByteArray(data: nonce),
            plaintext: plaintext,
            aad: nil
        )

        guard encryptResult.success else {
            testResult = "加密失败: \(encryptResult.error ?? "未知错误")"
            return
        }
        let ciphertext = encryptResult.data

        // 解密
        let decryptResult = cryptoAesGcmDecrypt(
            key: ByteArray(data: aesKey),
            nonce: ByteArray(data: nonce),
            ciphertext: ByteArray(data: ciphertext),
            aad: nil
        )

        guard decryptResult.success else {
            testResult = "解密失败: \(decryptResult.error ?? "未知错误")"
            return
        }

        let decryptedString = String(data: decryptResult.data, encoding: .utf8) ?? "无法解码"
        testResult = "AES-GCM 测试成功!\n原文: Hello, MCCopilot!\n解密: \(decryptedString)\n密文长度: \(ciphertext.count) bytes"
    }

    private func testHash() {
        let data = ByteArray(data: "Hello, World!".data(using: .utf8)!)
        let result = cryptoHash(algorithm: .sha256, data: data)

        if result.success {
            testResult = "SHA-256 哈希:\n\(result.data)"
        } else {
            testResult = "哈希失败: \(result.error ?? "未知错误")"
        }
    }

    private func testArgon2() {
        let password = "my_secure_password_123"
        let hashResult = cryptoArgon2Hash(password: password, params: nil)

        guard hashResult.success else {
            testResult = "Argon2 哈希失败: \(hashResult.error ?? "未知错误")"
            return
        }

        let hash = hashResult.data

        // 验证密码
        let verifyResult = cryptoArgon2Verify(password: password, hash: hash)

        if verifyResult.success && verifyResult.data == "true" {
            testResult = "Argon2 测试成功!\n哈希值:\n\(hash)\n验证通过: ✓"
        } else {
            testResult = "Argon2 验证失败"
        }
    }
}

/// 信息卡片视图
struct InfoCardView: View {
    private let infoItems = [
        InfoItem(icon: "📱", text: "原生 iOS 开发"),
        InfoItem(icon: "⚛️", text: "React Native 支持"),
        InfoItem(icon: "🐦", text: "Flutter 支持"),
        InfoItem(icon: "🌐", text: "Web 支持"),
        InfoItem(icon: "⚙️", text: "配置驱动的 Tab 系统")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 卡片标题
            Text("欢迎使用混合架构")
                .font(.system(size: 20, weight: .semibold))
                .padding(.horizontal, 20)
                .padding(.top, 20)

            // 分割线
            Rectangle()
                .fill(Color(UIColor.separator))
                .frame(height: 1)
                .padding(.horizontal, 20)

            // 信息项列表
            VStack(alignment: .leading, spacing: 12) {
                ForEach(infoItems, id: \.text) { item in
                    InfoItemView(item: item)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

/// 信息项数据模型
struct InfoItem {
    let icon: String
    let text: String
}

/// 信息项视图
struct InfoItemView: View {
    let item: InfoItem

    var body: some View {
        HStack(spacing: 12) {
            Text(item.icon)
                .font(.system(size: 20))
                .frame(width: 30, alignment: .leading)

            Text(item.text)
                .font(.system(size: 16))
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 13.0, *)
struct NativeTabSwiftUIPreview: PreviewProvider {
    static var previews: some View {
        Group {
            NativeTabSwiftUIView()
                .previewDisplayName("Light Mode")
                .preferredColorScheme(.light)

            NativeTabSwiftUIView()
                .previewDisplayName("Dark Mode")
                .preferredColorScheme(.dark)
        }
    }
}

@available(iOS 13.0, *)
struct InfoCardViewPreview: PreviewProvider {
    static var previews: some View {
        InfoCardView()
            .previewDisplayName("Info Card")
            .padding()
            .background(Color.gray.opacity(0.1))
    }
}
#endif
