import { type HybridObject } from 'react-native-nitro-modules'

export interface Argon2Params {
  memoryCost: number
  timeCost: number
  parallelism: number
  outputLength: number
}

export interface MccopilotRN extends HybridObject<{ ios: 'c++' }> {
  getVersion(): string

  // Hash
  cryptoHash(algorithm: string, data: ArrayBuffer): string

  // Key Derivation
  cryptoHkdfDerive(
    salt: ArrayBuffer,
    ikm: ArrayBuffer,
    info: ArrayBuffer | undefined,
    outputLength: number
  ): ArrayBuffer
  cryptoPbkdf2Derive(
    password: ArrayBuffer,
    salt: ArrayBuffer,
    iterations: number,
    outputLength: number
  ): ArrayBuffer

  // AES-CBC
  cryptoAesCbcEncrypt(
    key: ArrayBuffer,
    iv: ArrayBuffer,
    plaintext: ArrayBuffer
  ): ArrayBuffer
  cryptoAesCbcDecrypt(
    key: ArrayBuffer,
    iv: ArrayBuffer,
    ciphertext: ArrayBuffer
  ): ArrayBuffer

  // AES-CTR
  cryptoAesCtr(
    key: ArrayBuffer,
    nonce: ArrayBuffer,
    data: ArrayBuffer
  ): string

  // AES-GCM
  cryptoAesGcmEncrypt(
    key: ArrayBuffer,
    nonce: ArrayBuffer,
    plaintext: ArrayBuffer,
    aad: ArrayBuffer | undefined
  ): ArrayBuffer
  cryptoAesGcmDecrypt(
    key: ArrayBuffer,
    nonce: ArrayBuffer,
    ciphertext: ArrayBuffer,
    aad: ArrayBuffer | undefined
  ): ArrayBuffer
  cryptoAesGcmGenerateNonce(): ArrayBuffer
  cryptoAesGenerateIv(): ArrayBuffer

  // Argon2
  cryptoArgon2Hash(
    password: string,
    params: Argon2Params | undefined
  ): string
  cryptoArgon2HashWithSalt(
    password: ArrayBuffer,
    salt: ArrayBuffer,
    params: Argon2Params | undefined
  ): ArrayBuffer
  cryptoArgon2Verify(password: string, hash: string): boolean
}
