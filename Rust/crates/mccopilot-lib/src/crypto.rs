pub mod aes;
pub mod rsa;
pub mod hash;

// 重新导出子模块的公共类型和函数
pub use aes::{
    AesMode, AesKeySize,
    aes_cbc_encrypt, aes_cbc_decrypt,
    aes_ctr,
    aes_gcm_encrypt, aes_gcm_decrypt,
    generate_iv, generate_gcm_nonce,
};
pub use hash::{
    HashAlgorithm, hash,
    hkdf_derive, pbkdf2_derive,
    Argon2Params, argon2_hash, argon2_hash_with_salt, argon2_verify,
};
pub use rsa::{RsaKeySize, RsaKeyPair, rsa_encrypt, rsa_decrypt, rsa_sign, rsa_verify, generate_rsa_key_pair};