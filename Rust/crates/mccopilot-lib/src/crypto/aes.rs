//! AES 加密/解密实现

use crate::error::{MCCopilotError, Result};
use aes::{Aes128, Aes192, Aes256};
use cbc::cipher::{BlockEncryptMut, BlockDecryptMut, KeyIvInit, StreamCipher};
use cbc::cipher::block_padding::Pkcs7;
use ctr::Ctr128BE;
use rand::RngCore;

// 定义 CBC 加密/解密器类型别名
type Aes128CbcEnc = cbc::Encryptor<Aes128>;
type Aes128CbcDec = cbc::Decryptor<Aes128>;
type Aes192CbcEnc = cbc::Encryptor<Aes192>;
type Aes192CbcDec = cbc::Decryptor<Aes192>;
type Aes256CbcEnc = cbc::Encryptor<Aes256>;
type Aes256CbcDec = cbc::Decryptor<Aes256>;

// 定义 CTR 类型别名
type Aes128Ctr = Ctr128BE<Aes128>;
type Aes192Ctr = Ctr128BE<Aes192>;
type Aes256Ctr = Ctr128BE<Aes256>;

/// AES 模式
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AesMode {
    /// CBC 模式
    Cbc,
    /// CTR 模式
    Ctr,
}

/// AES 密钥长度
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AesKeySize {
    /// 128 位 (16 字节)
    Aes128,
    /// 192 位 (24 字节)
    Aes192,
    /// 256 位 (32 字节)
    Aes256,
}

impl AesKeySize {
    /// 返回密钥长度（字节）
    pub fn key_size(&self) -> usize {
        match self {
            AesKeySize::Aes128 => 16,
            AesKeySize::Aes192 => 24,
            AesKeySize::Aes256 => 32,
        }
    }

    /// 返回 IV 长度（字节）
    pub fn iv_size(&self) -> usize {
        16 // AES 块大小始终为 16 字节
    }
}

/// AES-CBC 加密
pub fn aes_cbc_encrypt(key: &[u8], iv: &[u8], plaintext: &[u8]) -> Result<Vec<u8>> {
    if key.len() != 16 && key.len() != 24 && key.len() != 32 {
        return Err(MCCopilotError::InvalidArgument(
            "Key must be 16, 24, or 32 bytes".to_string(),
        ));
    }
    if iv.len() != 16 {
        return Err(MCCopilotError::InvalidArgument("IV must be 16 bytes".to_string()));
    }

    // 计算填充后需要的缓冲区大小
    let block_size = 16;
    let padded_len = ((plaintext.len() / block_size) + 1) * block_size;
    let mut buffer = vec![0u8; padded_len];
    buffer[..plaintext.len()].copy_from_slice(plaintext);

    match key.len() {
        16 => {
            let cipher = Aes128CbcEnc::new_from_slices(key, iv)
                .map_err(|e| MCCopilotError::Crypto(format!("AES-128 init error: {}", e)))?;
            cipher.encrypt_padded_mut::<Pkcs7>(&mut buffer, plaintext.len())
                .map_err(|e| MCCopilotError::Crypto(format!("AES-128 encrypt error: {}", e)))?;
        }
        24 => {
            let cipher = Aes192CbcEnc::new_from_slices(key, iv)
                .map_err(|e| MCCopilotError::Crypto(format!("AES-192 init error: {}", e)))?;
            cipher.encrypt_padded_mut::<Pkcs7>(&mut buffer, plaintext.len())
                .map_err(|e| MCCopilotError::Crypto(format!("AES-192 encrypt error: {}", e)))?;
        }
        32 => {
            let cipher = Aes256CbcEnc::new_from_slices(key, iv)
                .map_err(|e| MCCopilotError::Crypto(format!("AES-256 init error: {}", e)))?;
            cipher.encrypt_padded_mut::<Pkcs7>(&mut buffer, plaintext.len())
                .map_err(|e| MCCopilotError::Crypto(format!("AES-256 encrypt error: {}", e)))?;
        }
        _ => unreachable!(),
    }

    Ok(buffer)
}

/// AES-CBC 解密
pub fn aes_cbc_decrypt(key: &[u8], iv: &[u8], ciphertext: &[u8]) -> Result<Vec<u8>> {
    if key.len() != 16 && key.len() != 24 && key.len() != 32 {
        return Err(MCCopilotError::InvalidArgument(
            "Key must be 16, 24, or 32 bytes".to_string(),
        ));
    }
    if iv.len() != 16 {
        return Err(MCCopilotError::InvalidArgument("IV must be 16 bytes".to_string()));
    }

    let buffer = ciphertext.to_vec();

    match key.len() {
        16 => {
            let cipher = Aes128CbcDec::new_from_slices(key, iv)
                .map_err(|e| MCCopilotError::Crypto(format!("AES-128 init error: {}", e)))?;
            decrypt_cbc(cipher, buffer)
        }
        24 => {
            let cipher = Aes192CbcDec::new_from_slices(key, iv)
                .map_err(|e| MCCopilotError::Crypto(format!("AES-192 init error: {}", e)))?;
            decrypt_cbc(cipher, buffer)
        }
        32 => {
            let cipher = Aes256CbcDec::new_from_slices(key, iv)
                .map_err(|e| MCCopilotError::Crypto(format!("AES-256 init error: {}", e)))?;
            decrypt_cbc(cipher, buffer)
        }
        _ => unreachable!(),
    }
}

fn decrypt_cbc<C: BlockDecryptMut>(cipher: C, mut buffer: Vec<u8>) -> Result<Vec<u8>> {
    let decrypted = cipher.decrypt_padded_mut::<Pkcs7>(&mut buffer)
        .map_err(|e| MCCopilotError::Crypto(format!("Decrypt error: {}", e)))?;
    Ok(decrypted.to_vec())
}

/// AES-CTR 加密/解密（流密码模式，同一函数）
pub fn aes_ctr(key: &[u8], nonce: &[u8], data: &mut [u8]) -> Result<()> {
    if key.len() != 16 && key.len() != 24 && key.len() != 32 {
        return Err(MCCopilotError::InvalidArgument(
            "Key must be 16, 24, or 32 bytes".to_string(),
        ));
    }
    if nonce.len() != 16 {
        return Err(MCCopilotError::InvalidArgument("Nonce must be 16 bytes".to_string()));
    }

    match key.len() {
        16 => {
            let mut cipher = Aes128Ctr::new_from_slices(key, nonce)
                .map_err(|e| MCCopilotError::Crypto(format!("AES-128-CTR init error: {}", e)))?;
            cipher.apply_keystream(data);
        }
        24 => {
            let mut cipher = Aes192Ctr::new_from_slices(key, nonce)
                .map_err(|e| MCCopilotError::Crypto(format!("AES-192-CTR init error: {}", e)))?;
            cipher.apply_keystream(data);
        }
        32 => {
            let mut cipher = Aes256Ctr::new_from_slices(key, nonce)
                .map_err(|e| MCCopilotError::Crypto(format!("AES-256-CTR init error: {}", e)))?;
            cipher.apply_keystream(data);
        }
        _ => unreachable!(),
    }

    Ok(())
}

/// 生成随机 IV
pub fn generate_iv() -> Result<Vec<u8>> {
    let mut iv = vec![0u8; 16];
    rand::rngs::OsRng.fill_bytes(&mut iv);
    Ok(iv)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_aes_cbc_round_trip() {
        let key = [0u8; 32]; // AES-256
        let iv = generate_iv().unwrap();
        let plaintext = b"hello, world!";

        let ciphertext = aes_cbc_encrypt(&key, &iv, plaintext).unwrap();
        let decrypted = aes_cbc_decrypt(&key, &iv, &ciphertext).unwrap();

        assert_eq!(plaintext.to_vec(), decrypted);
    }

    #[test]
    fn test_aes_ctr_round_trip() {
        let key = [0u8; 32]; // AES-256
        let nonce = generate_iv().unwrap();
        let mut data = b"hello, world!".to_vec();
        let original = data.clone();

        aes_ctr(&key, &nonce, &mut data).unwrap();
        aes_ctr(&key, &nonce, &mut data).unwrap();

        assert_eq!(original, data);
    }

    #[test]
    fn test_aes_cbc_empty_data() {
        let key = [0u8; 32];
        let iv = generate_iv().unwrap();
        let plaintext = b"";
        let ciphertext = aes_cbc_encrypt(&key, &iv, plaintext).unwrap();
        let decrypted = aes_cbc_decrypt(&key, &iv, &ciphertext).unwrap();
        assert_eq!(plaintext.to_vec(), decrypted);
    }

    #[test]
    fn test_aes_different_key_sizes() {
        for (key, key_size) in [
            (&[0u8; 16][..], "AES-128"),
            (&[0u8; 24][..], "AES-192"),
            (&[0u8; 32][..], "AES-256"),
        ] {
            let iv = generate_iv().unwrap();
            let plaintext = b"test data";
            let ciphertext = aes_cbc_encrypt(key, &iv, plaintext).unwrap();
            let decrypted = aes_cbc_decrypt(key, &iv, &ciphertext).unwrap();
            assert_eq!(plaintext.to_vec(), decrypted, "{} round trip failed", key_size);
        }
    }
}
