//! 哈希算法实现

use crate::error::{MCCopilotError, Result};
use sha2::{Digest, Sha256, Sha384, Sha512};
use hkdf::Hkdf;
use pbkdf2::pbkdf2_hmac;
use std::num::NonZeroU32;

/// 哈希算法类型
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HashAlgorithm {
    /// SHA-256
    Sha256,
    /// SHA-384
    Sha384,
    /// SHA-512
    Sha512,
}

/// 计算哈希值
///
/// # 参数
/// - `algorithm`: 哈希算法类型
/// - `data`: 要哈希的数据
///
/// # 返回
/// 哈希值的十六进制字符串
pub fn hash(algorithm: HashAlgorithm, data: &[u8]) -> Result<String> {
    match algorithm {
        HashAlgorithm::Sha256 => {
            let mut hasher = Sha256::new();
            hasher.update(data);
            Ok(hex::encode(hasher.finalize()))
        }
        HashAlgorithm::Sha384 => {
            let mut hasher = Sha384::new();
            hasher.update(data);
            Ok(hex::encode(hasher.finalize()))
        }
        HashAlgorithm::Sha512 => {
            let mut hasher = Sha512::new();
            hasher.update(data);
            Ok(hex::encode(hasher.finalize()))
        }
    }
}

/// 使用 HKDF 从密钥派生新的密钥
///
/// # 参数
/// - `salt`: 盐值
/// - `ikm`: 输入密钥材料 (Input Key Material)
/// - `info`: 可选的上下文信息
/// - `output_length`: 输出长度（字节）
///
/// # 返回
/// 派生的密钥
pub fn hkdf_derive(salt: &[u8], ikm: &[u8], info: Option<&[u8]>, output_length: usize) -> Result<Vec<u8>> {
    let hk = Hkdf::<Sha256>::new(Some(salt), ikm);
    let mut okm = vec![0u8; output_length];
    hk.expand(info.unwrap_or(b""), &mut okm)
        .map_err(|e| MCCopilotError::Crypto(format!("HKDF expand error: {}", e)))?;
    Ok(okm)
}

/// 使用 PBKDF2 从密码派生密钥
///
/// # 参数
/// - `password`: 密码
/// - `salt`: 盐值
/// - `iterations`: 迭代次数（建议至少 100,000）
/// - `output_length`: 输出长度（字节）
///
/// # 返回
/// 派生的密钥
pub fn pbkdf2_derive(password: &[u8], salt: &[u8], iterations: u32, output_length: usize) -> Result<Vec<u8>> {
    let iterations = NonZeroU32::new(iterations)
        .ok_or_else(|| MCCopilotError::InvalidArgument("iterations must be > 0".to_string()))?;

    let mut result = vec![0u8; output_length];
    pbkdf2_hmac::<Sha256>(password, salt, iterations.into(), &mut result);

    Ok(result)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sha256() {
        let data = b"hello world";
        let result = hash(HashAlgorithm::Sha256, data).unwrap();
        assert_eq!(result, "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9");
    }

    #[test]
    fn test_hkdf() {
        let salt = b"salt";
        let ikm = b"input key material";
        let info = b"info";
        let result = hkdf_derive(salt, ikm, Some(info), 32).unwrap();
        assert_eq!(result.len(), 32);
    }

    #[test]
    fn test_pbkdf2() {
        let password = b"password";
        let salt = b"salt";
        let result = pbkdf2_derive(password, salt, 100000, 32).unwrap();
        assert_eq!(result.len(), 32);
    }
}
