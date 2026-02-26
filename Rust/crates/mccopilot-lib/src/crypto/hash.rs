//! 哈希算法实现

use crate::error::{MCCopilotError, Result};
use sha2::{Digest, Sha256, Sha384, Sha512};
use hkdf::Hkdf;
use pbkdf2::pbkdf2_hmac;
use argon2::{Algorithm, Argon2, Params, Version, PasswordHasher, PasswordVerifier};
use argon2::password_hash::{PasswordHash, SaltString};
use rand::rngs::OsRng;
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

/// Argon2 参数配置
#[derive(Debug, Clone)]
pub struct Argon2Params {
    /// 内存成本（KB），默认 64MB
    pub memory_cost: u32,
    /// 时间成本（迭代次数），默认 3
    pub time_cost: u32,
    /// 并行度，默认 4
    pub parallelism: u32,
    /// 输出长度（字节），默认 32
    pub output_length: usize,
}

impl Default for Argon2Params {
    fn default() -> Self {
        Self {
            memory_cost: 65536,  // 64MB
            time_cost: 3,
            parallelism: 4,
            output_length: 32,
        }
    }
}

/// 使用 Argon2id 哈希密码
///
/// Argon2 是密码哈希竞赛 (PHC) 的获胜者，比 PBKDF2 更安全：
/// - 抗 GPU/ASIC 攻击（需要大量内存）
/// - 抗侧信道攻击
/// - Argon2id 是推荐的混合模式
///
/// # 参数
/// - `password`: 密码
/// - `params`: Argon2 参数配置
///
/// # 返回
/// PHC 格式的哈希字符串，例如: $argon2id$v=19$m=65536,t=3,p=4$salt$hash
pub fn argon2_hash(password: &str, params: Option<Argon2Params>) -> Result<String> {
    let params = params.unwrap_or_default();

    let argon2_params = Params::new(
        params.memory_cost,
        params.time_cost,
        params.parallelism,
        Some(params.output_length),
    ).map_err(|e| MCCopilotError::Crypto(format!("Argon2 params error: {}", e)))?;

    let argon2 = Argon2::new(
        Algorithm::Argon2id,
        Version::V0x13,
        argon2_params,
    );

    let salt = SaltString::generate(&mut OsRng);
    let hash = argon2
        .hash_password(password.as_bytes(), &salt)
        .map_err(|e| MCCopilotError::Crypto(format!("Argon2 hash error: {}", e)))?
        .to_string();

    Ok(hash)
}

/// 使用 Argon2id 哈希密码（使用自定义盐值）
///
/// # 参数
/// - `password`: 密码
/// - `salt`: 盐值（建议至少 16 字节）
/// - `params`: Argon2 参数配置
///
/// # 返回
/// 派生的密钥
pub fn argon2_hash_with_salt(password: &[u8], salt: &[u8], params: Option<Argon2Params>) -> Result<Vec<u8>> {
    if salt.len() < 8 {
        return Err(MCCopilotError::InvalidArgument("Salt must be at least 8 bytes".to_string()));
    }

    let params = params.unwrap_or_default();

    let argon2_params = Params::new(
        params.memory_cost,
        params.time_cost,
        params.parallelism,
        Some(params.output_length),
    ).map_err(|e| MCCopilotError::Crypto(format!("Argon2 params error: {}", e)))?;

    let argon2 = Argon2::new(
        Algorithm::Argon2id,
        Version::V0x13,
        argon2_params,
    );

    let mut output = vec![0u8; params.output_length];
    argon2
        .hash_password_into(password, salt, &mut output)
        .map_err(|e| MCCopilotError::Crypto(format!("Argon2 hash error: {}", e)))?;

    Ok(output)
}

/// 验证 Argon2 哈希密码
///
/// # 参数
/// - `password`: 待验证的密码
/// - `hash`: PHC 格式的哈希字符串
///
/// # 返回
/// 验证是否通过
pub fn argon2_verify(password: &str, hash: &str) -> Result<bool> {
    let parsed_hash = PasswordHash::new(hash)
        .map_err(|e| MCCopilotError::Crypto(format!("Invalid hash format: {}", e)))?;

    Ok(Argon2::default()
        .verify_password(password.as_bytes(), &parsed_hash)
        .is_ok())
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

    #[test]
    fn test_argon2_hash_and_verify() {
        let password = "my_secure_password";
        let hash = argon2_hash(password, None).unwrap();

        // 哈希应该是 PHC 格式
        assert!(hash.starts_with("$argon2id$"));

        // 验证正确的密码
        assert!(argon2_verify(password, &hash).unwrap());

        // 验证错误的密码应该失败
        assert!(!argon2_verify("wrong_password", &hash).unwrap());
    }

    #[test]
    fn test_argon2_hash_with_salt() {
        let password = b"password";
        let salt = b"salt_value_123456";
        let result = argon2_hash_with_salt(password, salt, None).unwrap();
        assert_eq!(result.len(), 32);

        // 相同的密码和盐应该产生相同的哈希
        let result2 = argon2_hash_with_salt(password, salt, None).unwrap();
        assert_eq!(result, result2);
    }

    #[test]
    fn test_argon2_custom_params() {
        let password = "test_password";
        let params = Argon2Params {
            memory_cost: 32768,  // 32MB
            time_cost: 2,
            parallelism: 2,
            output_length: 64,
        };
        let hash = argon2_hash(password, Some(params)).unwrap();
        assert!(argon2_verify(password, &hash).unwrap());
    }
}
