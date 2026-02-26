//! RSA 加密/解密和签名实现

use crate::error::{MCCopilotError, Result};
use rand::rngs::OsRng;
use rsa::{
    pkcs1v15,
    pkcs8::{DecodePrivateKey, DecodePublicKey, EncodePrivateKey, EncodePublicKey, LineEnding},
    RsaPrivateKey, RsaPublicKey,
    signature::{RandomizedSigner, Verifier, SignatureEncoding},
};
use sha2::Sha256;
use base64::{Engine, engine::general_purpose::STANDARD};

/// RSA 密钥长度
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RsaKeySize {
    /// 2048 位
    Rsa2048,
    /// 3072 位
    Rsa3072,
    /// 4096 位
    Rsa4096,
}

impl RsaKeySize {
    pub fn bits(&self) -> usize {
        match self {
            RsaKeySize::Rsa2048 => 2048,
            RsaKeySize::Rsa3072 => 3072,
            RsaKeySize::Rsa4096 => 4096,
        }
    }
}

/// RSA 密钥对
pub struct RsaKeyPair {
    /// 私钥（PKCS#8 PEM 格式）
    pub private_key_pem: String,
    /// 公钥（PKCS#8 PEM 格式）
    pub public_key_pem: String,
}

/// RSA 加密
///
/// # 参数
/// - `public_key_pem`: PEM 格式的公钥
/// - `plaintext`: 要加密的数据
///
/// # 返回
/// Base64 编码的密文
pub fn rsa_encrypt(public_key_pem: &str, plaintext: &[u8]) -> Result<String> {
    let public_key = RsaPublicKey::from_public_key_pem(public_key_pem)
        .map_err(|e| MCCopilotError::Crypto(format!("Failed to parse public key: {}", e)))?;

    let mut rng = OsRng;
    let ciphertext = public_key
        .encrypt(&mut rng, pkcs1v15::Pkcs1v15Encrypt, plaintext)
        .map_err(|e| MCCopilotError::Crypto(format!("Encryption failed: {}", e)))?;

    Ok(STANDARD.encode(ciphertext))
}

/// RSA 解密
///
/// # 参数
/// - `private_key_pem`: PEM 格式的私钥
/// - `ciphertext_base64`: Base64 编码的密文
///
/// # 返回
/// 解密后的明文
pub fn rsa_decrypt(private_key_pem: &str, ciphertext_base64: &str) -> Result<Vec<u8>> {
    let private_key = RsaPrivateKey::from_pkcs8_pem(private_key_pem)
        .map_err(|e| MCCopilotError::Crypto(format!("Failed to parse private key: {}", e)))?;

    let ciphertext = STANDARD.decode(ciphertext_base64)?;

    let plaintext = private_key
        .decrypt(pkcs1v15::Pkcs1v15Encrypt, &ciphertext)
        .map_err(|e| MCCopilotError::Crypto(format!("Decryption failed: {}", e)))?;

    Ok(plaintext)
}

/// RSA 签名
///
/// # 参数
/// - `private_key_pem`: PEM 格式的私钥
/// - `data`: 要签名的数据
///
/// # 返回
/// Base64 编码的签名
pub fn rsa_sign(private_key_pem: &str, data: &[u8]) -> Result<String> {
    let private_key = RsaPrivateKey::from_pkcs8_pem(private_key_pem)
        .map_err(|e| MCCopilotError::Crypto(format!("Failed to parse private key: {}", e)))?;

    let mut rng = OsRng;
    let signing_key = pkcs1v15::SigningKey::<Sha256>::new_unprefixed(private_key);
    let signature = signing_key.sign_with_rng(&mut rng, data);

    Ok(STANDARD.encode(signature.to_bytes()))
}

/// RSA 验签
///
/// # 参数
/// - `public_key_pem`: PEM 格式的公钥
/// - `data`: 原始数据
/// - `signature_base64`: Base64 编码的签名
///
/// # 返回
/// 验证是否通过
pub fn rsa_verify(public_key_pem: &str, data: &[u8], signature_base64: &str) -> Result<bool> {
    let public_key = RsaPublicKey::from_public_key_pem(public_key_pem)
        .map_err(|e| MCCopilotError::Crypto(format!("Failed to parse public key: {}", e)))?;

    let signature_bytes = STANDARD.decode(signature_base64)?;

    // 将签名转换为正确的类型
    let signature = pkcs1v15::Signature::try_from(signature_bytes.as_slice())
        .map_err(|e| MCCopilotError::Crypto(format!("Invalid signature format: {}", e)))?;

    let verifying_key = pkcs1v15::VerifyingKey::<Sha256>::new_unprefixed(public_key);
    verifying_key
        .verify(data, &signature)
        .map_err(|e| MCCopilotError::Crypto(format!("Verification failed: {}", e)))?;

    Ok(true)
}

/// 生成 RSA 密钥对
///
/// # 参数
/// - `key_size`: 密钥长度
///
/// # 返回
/// RSA 密钥对
pub fn generate_rsa_key_pair(key_size: RsaKeySize) -> Result<RsaKeyPair> {
    let mut rng = OsRng;
    let private_key = RsaPrivateKey::new(&mut rng, key_size.bits())
        .map_err(|e| MCCopilotError::Crypto(format!("Failed to generate RSA key: {}", e)))?;

    let public_key = private_key.to_public_key();

    let private_key_pem = private_key
        .to_pkcs8_pem(LineEnding::LF)
        .map_err(|e| MCCopilotError::Crypto(format!("Failed to encode private key: {}", e)))?
        .to_string();

    let public_key_pem = public_key
        .to_public_key_pem(LineEnding::LF)
        .map_err(|e| MCCopilotError::Crypto(format!("Failed to encode public key: {}", e)))?;

    Ok(RsaKeyPair {
        private_key_pem,
        public_key_pem,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rsa_key_generation() {
        let key_pair = generate_rsa_key_pair(RsaKeySize::Rsa2048).unwrap();
        assert!(key_pair.private_key_pem.contains("BEGIN PRIVATE KEY"));
        assert!(key_pair.public_key_pem.contains("BEGIN PUBLIC KEY"));
    }

    #[test]
    fn test_rsa_encrypt_decrypt() {
        let key_pair = generate_rsa_key_pair(RsaKeySize::Rsa2048).unwrap();
        let plaintext = b"hello, rsa!";

        let ciphertext = rsa_encrypt(&key_pair.public_key_pem, plaintext).unwrap();
        let decrypted = rsa_decrypt(&key_pair.private_key_pem, &ciphertext).unwrap();

        assert_eq!(plaintext.to_vec(), decrypted);
    }

    #[test]
    fn test_rsa_sign_verify() {
        let key_pair = generate_rsa_key_pair(RsaKeySize::Rsa2048).unwrap();
        let data = b"message to sign";

        let signature = rsa_sign(&key_pair.private_key_pem, data).unwrap();
        let verified = rsa_verify(&key_pair.public_key_pem, data, &signature).unwrap();

        assert!(verified);

        // 验证错误的签名
        let wrong_data = b"wrong message";
        let result = rsa_verify(&key_pair.public_key_pem, wrong_data, &signature);
        assert!(result.is_err() || !result.unwrap());
    }

    #[test]
    fn test_rsa_key_sizes() {
        for key_size in [RsaKeySize::Rsa2048, RsaKeySize::Rsa3072, RsaKeySize::Rsa4096] {
            let key_pair = generate_rsa_key_pair(key_size).unwrap();
            assert!(key_pair.private_key_pem.contains("BEGIN PRIVATE KEY"));
            assert!(key_pair.public_key_pem.contains("BEGIN PUBLIC KEY"));
        }
    }
}
