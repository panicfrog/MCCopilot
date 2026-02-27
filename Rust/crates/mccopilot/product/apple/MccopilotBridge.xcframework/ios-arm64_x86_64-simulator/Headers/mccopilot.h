#pragma once

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdatomic.h>

	typedef struct { int32_t code; } FfiStatus;
	typedef struct { uint8_t* ptr; size_t len; size_t cap; } FfiString;
	typedef struct { uint8_t* ptr; size_t len; size_t cap; } FfiBuf_u8;
	typedef struct { FfiString message; } FfiError;
	typedef struct { uint64_t handle; const void* vtable; } BoltFFICallbackHandle;

	static inline bool boltffi_atomic_u8_cas(uint8_t* state, uint8_t expected, uint8_t desired) {
	    return atomic_compare_exchange_strong_explicit((_Atomic uint8_t*)state, &expected, desired, memory_order_acq_rel, memory_order_acquire);
	}

static inline uint64_t boltffi_atomic_u64_exchange(uint64_t* slot, uint64_t value) {
    return atomic_exchange_explicit((_Atomic uint64_t*)slot, value, memory_order_acq_rel);
}

static inline bool boltffi_atomic_u64_cas(uint64_t* slot, uint64_t expected, uint64_t desired) {
    return atomic_compare_exchange_strong_explicit((_Atomic uint64_t*)slot, &expected, desired, memory_order_acq_rel, memory_order_acquire);
}

static inline uint64_t boltffi_atomic_u64_load(uint64_t* slot) {
    return atomic_load_explicit((_Atomic uint64_t*)slot, memory_order_acquire);
}

typedef int32_t ___HashAlgorithm;
#define ___HashAlgorithm_Sha256 0
#define ___HashAlgorithm_Sha384 1
#define ___HashAlgorithm_Sha512 2

typedef int32_t ___AesKeySize;
#define ___AesKeySize_Aes128 0
#define ___AesKeySize_Aes192 1
#define ___AesKeySize_Aes256 2

FfiBuf_u8 boltffi_crypto_hash(const uint8_t* algorithm_ptr, uintptr_t algorithm_len, const uint8_t* data_ptr, uintptr_t data_len);
FfiBuf_u8 boltffi_crypto_hkdf_derive(const uint8_t* salt_ptr, uintptr_t salt_len, const uint8_t* ikm_ptr, uintptr_t ikm_len, const uint8_t* info_ptr, uintptr_t info_len, uintptr_t output_length);
FfiBuf_u8 boltffi_crypto_pbkdf2_derive(const uint8_t* password_ptr, uintptr_t password_len, const uint8_t* salt_ptr, uintptr_t salt_len, uint32_t iterations, uintptr_t output_length);
FfiBuf_u8 boltffi_crypto_aes_cbc_encrypt(const uint8_t* key_ptr, uintptr_t key_len, const uint8_t* iv_ptr, uintptr_t iv_len, const uint8_t* plaintext_ptr, uintptr_t plaintext_len);
FfiBuf_u8 boltffi_crypto_aes_cbc_decrypt(const uint8_t* key_ptr, uintptr_t key_len, const uint8_t* iv_ptr, uintptr_t iv_len, const uint8_t* ciphertext_ptr, uintptr_t ciphertext_len);
FfiBuf_u8 boltffi_crypto_aes_ctr(const uint8_t* key_ptr, uintptr_t key_len, const uint8_t* nonce_ptr, uintptr_t nonce_len, const uint8_t* data_ptr, uintptr_t data_len);
FfiBuf_u8 boltffi_crypto_aes_generate_iv(void);
FfiBuf_u8 boltffi_crypto_aes_gcm_encrypt(const uint8_t* key_ptr, uintptr_t key_len, const uint8_t* nonce_ptr, uintptr_t nonce_len, const uint8_t* plaintext_ptr, uintptr_t plaintext_len, const uint8_t* aad_ptr, uintptr_t aad_len);
FfiBuf_u8 boltffi_crypto_aes_gcm_decrypt(const uint8_t* key_ptr, uintptr_t key_len, const uint8_t* nonce_ptr, uintptr_t nonce_len, const uint8_t* ciphertext_ptr, uintptr_t ciphertext_len, const uint8_t* aad_ptr, uintptr_t aad_len);
FfiBuf_u8 boltffi_crypto_aes_gcm_generate_nonce(void);
FfiBuf_u8 boltffi_crypto_argon2_hash(const uint8_t* password_ptr, uintptr_t password_len, const uint8_t* params_ptr, uintptr_t params_len);
FfiBuf_u8 boltffi_crypto_argon2_hash_with_salt(const uint8_t* password_ptr, uintptr_t password_len, const uint8_t* salt_ptr, uintptr_t salt_len, const uint8_t* params_ptr, uintptr_t params_len);
FfiBuf_u8 boltffi_crypto_argon2_verify(const uint8_t* password_ptr, uintptr_t password_len, const uint8_t* hash_ptr, uintptr_t hash_len);
FfiBuf_u8 boltffi_get_version(void);

void boltffi_free_string(FfiString s);
void boltffi_free_buf_u8(FfiBuf_u8 buf);
FfiStatus boltffi_last_error_message(FfiString *out);
void boltffi_clear_last_error(void);
