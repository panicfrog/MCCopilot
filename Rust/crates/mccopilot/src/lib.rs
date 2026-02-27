//! BoltFFI 绑定层
//!
//! 为 iOS Swift、Android Kotlin 等平台提供 FFI 接口

use boltffi::*;

// 导入核心库
use mccopilot_lib::crypto::{aes, hash};

/// FFI 导出的数据类型

#[data]
pub struct ByteArray {
    pub data: Vec<u8>,
}

#[data]
pub struct StringResult {
    pub success: bool,
    pub data: String,
    pub error: Option<String>,
}

#[data]
pub struct BytesResult {
    pub success: bool,
    pub data: Vec<u8>,
    pub error: Option<String>,
}

/// 哈希算法类型 (用于 BoltFFI)
#[data]
pub enum HashAlgorithm {
    Sha256 = 0,
    Sha384 = 1,
    Sha512 = 2,
}

/// AES 密钥长度
#[data]
pub enum AesKeySize {
    Aes128 = 0,
    Aes192 = 1,
    Aes256 = 2,
}

/// 导出哈希函数
#[export]
pub fn crypto_hash(algorithm: HashAlgorithm, data: ByteArray) -> StringResult {
    let algo = match algorithm {
        HashAlgorithm::Sha256 => hash::HashAlgorithm::Sha256,
        HashAlgorithm::Sha384 => hash::HashAlgorithm::Sha384,
        HashAlgorithm::Sha512 => hash::HashAlgorithm::Sha512,
    };

    match hash::hash(algo, &data.data) {
        Ok(result) => StringResult {
            success: true,
            data: result,
            error: None,
        },
        Err(e) => StringResult {
            success: false,
            data: String::new(),
            error: Some(e.to_string()),
        },
    }
}

/// 导出 HKDF 密钥派生
#[export]
pub fn crypto_hkdf_derive(salt: ByteArray, ikm: ByteArray, info: Option<ByteArray>, output_length: usize) -> BytesResult {
    let info_bytes = info.map(|b| b.data);

    match hash::hkdf_derive(&salt.data, &ikm.data, info_bytes.as_deref(), output_length) {
        Ok(result) => BytesResult {
            success: true,
            data: result,
            error: None,
        },
        Err(e) => BytesResult {
            success: false,
            data: Vec::new(),
            error: Some(e.to_string()),
        },
    }
}

/// 导出 PBKDF2 密钥派生
#[export]
pub fn crypto_pbkdf2_derive(password: ByteArray, salt: ByteArray, iterations: u32, output_length: usize) -> BytesResult {
    match hash::pbkdf2_derive(&password.data, &salt.data, iterations, output_length) {
        Ok(result) => BytesResult {
            success: true,
            data: result,
            error: None,
        },
        Err(e) => BytesResult {
            success: false,
            data: Vec::new(),
            error: Some(e.to_string()),
        },
    }
}

/// 导出 AES-CBC 加密
#[export]
pub fn crypto_aes_cbc_encrypt(key: ByteArray, iv: ByteArray, plaintext: ByteArray) -> BytesResult {
    match aes::aes_cbc_encrypt(&key.data, &iv.data, &plaintext.data) {
        Ok(result) => BytesResult {
            success: true,
            data: result,
            error: None,
        },
        Err(e) => BytesResult {
            success: false,
            data: Vec::new(),
            error: Some(e.to_string()),
        },
    }
}

/// 导出 AES-CBC 解密
#[export]
pub fn crypto_aes_cbc_decrypt(key: ByteArray, iv: ByteArray, ciphertext: ByteArray) -> BytesResult {
    match aes::aes_cbc_decrypt(&key.data, &iv.data, &ciphertext.data) {
        Ok(result) => BytesResult {
            success: true,
            data: result,
            error: None,
        },
        Err(e) => BytesResult {
            success: false,
            data: Vec::new(),
            error: Some(e.to_string()),
        },
    }
}

/// 导出 AES-CTR 加密/解密
#[export]
pub fn crypto_aes_ctr(key: ByteArray, nonce: ByteArray, mut data: ByteArray) -> StringResult {
    match aes::aes_ctr(&key.data, &nonce.data, &mut data.data) {
        Ok(()) => StringResult {
            success: true,
            data: String::new(),
            error: None,
        },
        Err(e) => StringResult {
            success: false,
            data: String::new(),
            error: Some(e.to_string()),
        },
    }
}

/// 导出生成随机 IV
#[export]
pub fn crypto_aes_generate_iv() -> BytesResult {
    match aes::generate_iv() {
        Ok(iv) => BytesResult {
            success: true,
            data: iv,
            error: None,
        },
        Err(e) => BytesResult {
            success: false,
            data: Vec::new(),
            error: Some(e.to_string()),
        },
    }
}

// ==================== AES-GCM 认证加密 ====================

/// 导出 AES-GCM 加密
#[export]
pub fn crypto_aes_gcm_encrypt(key: ByteArray, nonce: ByteArray, plaintext: ByteArray, aad: Option<ByteArray>) -> BytesResult {
    let aad_bytes = aad.map(|b| b.data);
    match aes::aes_gcm_encrypt(&key.data, &nonce.data, &plaintext.data, aad_bytes.as_deref()) {
        Ok(result) => BytesResult {
            success: true,
            data: result,
            error: None,
        },
        Err(e) => BytesResult {
            success: false,
            data: Vec::new(),
            error: Some(e.to_string()),
        },
    }
}

/// 导出 AES-GCM 解密
#[export]
pub fn crypto_aes_gcm_decrypt(key: ByteArray, nonce: ByteArray, ciphertext: ByteArray, aad: Option<ByteArray>) -> BytesResult {
    let aad_bytes = aad.map(|b| b.data);
    match aes::aes_gcm_decrypt(&key.data, &nonce.data, &ciphertext.data, aad_bytes.as_deref()) {
        Ok(result) => BytesResult {
            success: true,
            data: result,
            error: None,
        },
        Err(e) => BytesResult {
            success: false,
            data: Vec::new(),
            error: Some(e.to_string()),
        },
    }
}

/// 导出生成随机 GCM Nonce (12 字节)
#[export]
pub fn crypto_aes_gcm_generate_nonce() -> BytesResult {
    match aes::generate_gcm_nonce() {
        Ok(nonce) => BytesResult {
            success: true,
            data: nonce,
            error: None,
        },
        Err(e) => BytesResult {
            success: false,
            data: Vec::new(),
            error: Some(e.to_string()),
        },
    }
}

// ==================== Argon2 密码哈希 ====================

/// Argon2 参数配置 (用于 BoltFFI)
#[data]
#[derive(Clone, Copy)]
pub struct Argon2Params {
    /// 内存成本（KB），默认 64MB
    pub memory_cost: u32,
    /// 时间成本（迭代次数），默认 3
    pub time_cost: u32,
    /// 并行度，默认 4
    pub parallelism: u32,
    /// 输出长度（字节），默认 32
    pub output_length: u32,
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

/// 导出 Argon2 密码哈希
#[export]
pub fn crypto_argon2_hash(password: String, params: Option<Argon2Params>) -> StringResult {
    let lib_params = params.map(|p| hash::Argon2Params {
        memory_cost: p.memory_cost,
        time_cost: p.time_cost,
        parallelism: p.parallelism,
        output_length: p.output_length as usize,
    });

    match hash::argon2_hash(&password, lib_params) {
        Ok(hash) => StringResult {
            success: true,
            data: hash,
            error: None,
        },
        Err(e) => StringResult {
            success: false,
            data: String::new(),
            error: Some(e.to_string()),
        },
    }
}

/// 导出 Argon2 密码哈希（使用自定义盐值）
#[export]
pub fn crypto_argon2_hash_with_salt(password: ByteArray, salt: ByteArray, params: Option<Argon2Params>) -> BytesResult {
    let lib_params = params.map(|p| hash::Argon2Params {
        memory_cost: p.memory_cost,
        time_cost: p.time_cost,
        parallelism: p.parallelism,
        output_length: p.output_length as usize,
    });

    match hash::argon2_hash_with_salt(&password.data, &salt.data, lib_params) {
        Ok(result) => BytesResult {
            success: true,
            data: result,
            error: None,
        },
        Err(e) => BytesResult {
            success: false,
            data: Vec::new(),
            error: Some(e.to_string()),
        },
    }
}

/// 导出 Argon2 密码验证
#[export]
pub fn crypto_argon2_verify(password: String, hash: String) -> StringResult {
    match hash::argon2_verify(&password, &hash) {
        Ok(valid) => StringResult {
            success: true,
            data: if valid { "true" } else { "false" }.to_string(),
            error: None,
        },
        Err(e) => StringResult {
            success: false,
            data: String::new(),
            error: Some(e.to_string()),
        },
    }
}

/// 获取版本号
#[export]
pub fn get_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_version() {
        let version = get_version();
        assert!(!version.is_empty());
    }
}
