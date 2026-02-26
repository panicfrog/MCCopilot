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
