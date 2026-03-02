#include "HybridMccopilotRN.hpp"
#include "BoltFFIWire.hpp"
#include <NitroModules/ArrayBuffer.hpp>
#include <stdexcept>

extern "C" {
#include "mccopilot.h"
}

namespace margelo::nitro::mccopilot {

using ::mccopilot::WireWriter;
using ::mccopilot::WireReader;
using ::mccopilot::StringResult;
using ::mccopilot::BytesResult;

// --- helpers ---

static int32_t parseHashAlgorithm(const std::string& algo) {
  if (algo == "sha256") return 0;
  if (algo == "sha384") return 1;
  if (algo == "sha512") return 2;
  throw std::runtime_error("Unknown hash algorithm: " + algo);
}

static void writeArgon2Params(WireWriter& w, const std::optional<Argon2Params>& params) {
  if (!params.has_value()) {
    w.writeU8(0);
    return;
  }
  w.writeU8(1);
  // Argon2Params is blittable as 4x uint32 in the BoltFFI wire format
  w.writeBlittable(static_cast<uint32_t>(params->memoryCost));
  w.writeBlittable(static_cast<uint32_t>(params->timeCost));
  w.writeBlittable(static_cast<uint32_t>(params->parallelism));
  w.writeBlittable(static_cast<uint32_t>(params->outputLength));
}

static void writeBuffer(WireWriter& w, const std::shared_ptr<ArrayBuffer>& buf) {
  w.writeBytes(buf->data(), buf->size());
}

static void writeOptionalBuffer(WireWriter& w, const std::optional<std::shared_ptr<ArrayBuffer>>& buf) {
  if (!buf.has_value()) {
    w.writeU8(0);
    return;
  }
  w.writeU8(1);
  writeBuffer(w, buf.value());
}

static std::shared_ptr<ArrayBuffer> bytesToArrayBuffer(const std::vector<uint8_t>& bytes) {
  if (bytes.empty()) {
    return ArrayBuffer::allocate(0);
  }
  return ArrayBuffer::copy(bytes);
}

// --- HybridMccopilotRN implementation ---

std::string HybridMccopilotRN::getVersion() {
  FfiBuf_u8 buf = boltffi_get_version();
  WireReader reader(buf.ptr, buf.len);
  std::string version = reader.readString();
  boltffi_free_buf_u8(buf);
  return version;
}

std::string HybridMccopilotRN::cryptoHash(
    const std::string& algorithm,
    const std::shared_ptr<ArrayBuffer>& data) {
  WireWriter algoW;
  algoW.writeI32(parseHashAlgorithm(algorithm));

  WireWriter dataW;
  writeBuffer(dataW, data);

  FfiBuf_u8 buf = boltffi_crypto_hash(
    algoW.data(), algoW.size(),
    dataW.data(), dataW.size());
  WireReader reader(buf.ptr, buf.len);
  auto result = StringResult::decode(reader);
  boltffi_free_buf_u8(buf);
  result.throwIfError();
  return result.data;
}

std::shared_ptr<ArrayBuffer> HybridMccopilotRN::cryptoHkdfDerive(
    const std::shared_ptr<ArrayBuffer>& salt,
    const std::shared_ptr<ArrayBuffer>& ikm,
    const std::optional<std::shared_ptr<ArrayBuffer>>& info,
    double outputLength) {
  WireWriter saltW; writeBuffer(saltW, salt);
  WireWriter ikmW;  writeBuffer(ikmW, ikm);
  WireWriter infoW; writeOptionalBuffer(infoW, info);

  FfiBuf_u8 buf = boltffi_crypto_hkdf_derive(
    saltW.data(), saltW.size(),
    ikmW.data(), ikmW.size(),
    infoW.data(), infoW.size(),
    static_cast<uintptr_t>(outputLength));
  WireReader reader(buf.ptr, buf.len);
  auto result = BytesResult::decode(reader);
  boltffi_free_buf_u8(buf);
  result.throwIfError();
  return bytesToArrayBuffer(result.data);
}

std::shared_ptr<ArrayBuffer> HybridMccopilotRN::cryptoPbkdf2Derive(
    const std::shared_ptr<ArrayBuffer>& password,
    const std::shared_ptr<ArrayBuffer>& salt,
    double iterations,
    double outputLength) {
  WireWriter pwW;   writeBuffer(pwW, password);
  WireWriter saltW; writeBuffer(saltW, salt);

  FfiBuf_u8 buf = boltffi_crypto_pbkdf2_derive(
    pwW.data(), pwW.size(),
    saltW.data(), saltW.size(),
    static_cast<uint32_t>(iterations),
    static_cast<uintptr_t>(outputLength));
  WireReader reader(buf.ptr, buf.len);
  auto result = BytesResult::decode(reader);
  boltffi_free_buf_u8(buf);
  result.throwIfError();
  return bytesToArrayBuffer(result.data);
}

std::shared_ptr<ArrayBuffer> HybridMccopilotRN::cryptoAesCbcEncrypt(
    const std::shared_ptr<ArrayBuffer>& key,
    const std::shared_ptr<ArrayBuffer>& iv,
    const std::shared_ptr<ArrayBuffer>& plaintext) {
  WireWriter keyW; writeBuffer(keyW, key);
  WireWriter ivW;  writeBuffer(ivW, iv);
  WireWriter ptW;  writeBuffer(ptW, plaintext);

  FfiBuf_u8 buf = boltffi_crypto_aes_cbc_encrypt(
    keyW.data(), keyW.size(),
    ivW.data(), ivW.size(),
    ptW.data(), ptW.size());
  WireReader reader(buf.ptr, buf.len);
  auto result = BytesResult::decode(reader);
  boltffi_free_buf_u8(buf);
  result.throwIfError();
  return bytesToArrayBuffer(result.data);
}

std::shared_ptr<ArrayBuffer> HybridMccopilotRN::cryptoAesCbcDecrypt(
    const std::shared_ptr<ArrayBuffer>& key,
    const std::shared_ptr<ArrayBuffer>& iv,
    const std::shared_ptr<ArrayBuffer>& ciphertext) {
  WireWriter keyW; writeBuffer(keyW, key);
  WireWriter ivW;  writeBuffer(ivW, iv);
  WireWriter ctW;  writeBuffer(ctW, ciphertext);

  FfiBuf_u8 buf = boltffi_crypto_aes_cbc_decrypt(
    keyW.data(), keyW.size(),
    ivW.data(), ivW.size(),
    ctW.data(), ctW.size());
  WireReader reader(buf.ptr, buf.len);
  auto result = BytesResult::decode(reader);
  boltffi_free_buf_u8(buf);
  result.throwIfError();
  return bytesToArrayBuffer(result.data);
}

std::string HybridMccopilotRN::cryptoAesCtr(
    const std::shared_ptr<ArrayBuffer>& key,
    const std::shared_ptr<ArrayBuffer>& nonce,
    const std::shared_ptr<ArrayBuffer>& data) {
  WireWriter keyW;   writeBuffer(keyW, key);
  WireWriter nonceW; writeBuffer(nonceW, nonce);
  WireWriter dataW;  writeBuffer(dataW, data);

  FfiBuf_u8 buf = boltffi_crypto_aes_ctr(
    keyW.data(), keyW.size(),
    nonceW.data(), nonceW.size(),
    dataW.data(), dataW.size());
  WireReader reader(buf.ptr, buf.len);
  auto result = StringResult::decode(reader);
  boltffi_free_buf_u8(buf);
  result.throwIfError();
  return result.data;
}

std::shared_ptr<ArrayBuffer> HybridMccopilotRN::cryptoAesGcmEncrypt(
    const std::shared_ptr<ArrayBuffer>& key,
    const std::shared_ptr<ArrayBuffer>& nonce,
    const std::shared_ptr<ArrayBuffer>& plaintext,
    const std::optional<std::shared_ptr<ArrayBuffer>>& aad) {
  WireWriter keyW;   writeBuffer(keyW, key);
  WireWriter nonceW; writeBuffer(nonceW, nonce);
  WireWriter ptW;    writeBuffer(ptW, plaintext);
  WireWriter aadW;   writeOptionalBuffer(aadW, aad);

  FfiBuf_u8 buf = boltffi_crypto_aes_gcm_encrypt(
    keyW.data(), keyW.size(),
    nonceW.data(), nonceW.size(),
    ptW.data(), ptW.size(),
    aadW.data(), aadW.size());
  WireReader reader(buf.ptr, buf.len);
  auto result = BytesResult::decode(reader);
  boltffi_free_buf_u8(buf);
  result.throwIfError();
  return bytesToArrayBuffer(result.data);
}

std::shared_ptr<ArrayBuffer> HybridMccopilotRN::cryptoAesGcmDecrypt(
    const std::shared_ptr<ArrayBuffer>& key,
    const std::shared_ptr<ArrayBuffer>& nonce,
    const std::shared_ptr<ArrayBuffer>& ciphertext,
    const std::optional<std::shared_ptr<ArrayBuffer>>& aad) {
  WireWriter keyW;   writeBuffer(keyW, key);
  WireWriter nonceW; writeBuffer(nonceW, nonce);
  WireWriter ctW;    writeBuffer(ctW, ciphertext);
  WireWriter aadW;   writeOptionalBuffer(aadW, aad);

  FfiBuf_u8 buf = boltffi_crypto_aes_gcm_decrypt(
    keyW.data(), keyW.size(),
    nonceW.data(), nonceW.size(),
    ctW.data(), ctW.size(),
    aadW.data(), aadW.size());
  WireReader reader(buf.ptr, buf.len);
  auto result = BytesResult::decode(reader);
  boltffi_free_buf_u8(buf);
  result.throwIfError();
  return bytesToArrayBuffer(result.data);
}

std::shared_ptr<ArrayBuffer> HybridMccopilotRN::cryptoAesGcmGenerateNonce() {
  FfiBuf_u8 buf = boltffi_crypto_aes_gcm_generate_nonce();
  WireReader reader(buf.ptr, buf.len);
  auto result = BytesResult::decode(reader);
  boltffi_free_buf_u8(buf);
  result.throwIfError();
  return bytesToArrayBuffer(result.data);
}

std::shared_ptr<ArrayBuffer> HybridMccopilotRN::cryptoAesGenerateIv() {
  FfiBuf_u8 buf = boltffi_crypto_aes_generate_iv();
  WireReader reader(buf.ptr, buf.len);
  auto result = BytesResult::decode(reader);
  boltffi_free_buf_u8(buf);
  result.throwIfError();
  return bytesToArrayBuffer(result.data);
}

std::string HybridMccopilotRN::cryptoArgon2Hash(
    const std::string& password,
    const std::optional<Argon2Params>& params) {
  WireWriter paramsW;
  writeArgon2Params(paramsW, params);

  FfiBuf_u8 buf = boltffi_crypto_argon2_hash(
    reinterpret_cast<const uint8_t*>(password.data()),
    static_cast<uintptr_t>(password.size()),
    paramsW.data(), paramsW.size());
  WireReader reader(buf.ptr, buf.len);
  auto result = StringResult::decode(reader);
  boltffi_free_buf_u8(buf);
  result.throwIfError();
  return result.data;
}

std::shared_ptr<ArrayBuffer> HybridMccopilotRN::cryptoArgon2HashWithSalt(
    const std::shared_ptr<ArrayBuffer>& password,
    const std::shared_ptr<ArrayBuffer>& salt,
    const std::optional<Argon2Params>& params) {
  WireWriter pwW;   writeBuffer(pwW, password);
  WireWriter saltW; writeBuffer(saltW, salt);
  WireWriter paramsW;
  writeArgon2Params(paramsW, params);

  FfiBuf_u8 buf = boltffi_crypto_argon2_hash_with_salt(
    pwW.data(), pwW.size(),
    saltW.data(), saltW.size(),
    paramsW.data(), paramsW.size());
  WireReader reader(buf.ptr, buf.len);
  auto result = BytesResult::decode(reader);
  boltffi_free_buf_u8(buf);
  result.throwIfError();
  return bytesToArrayBuffer(result.data);
}

bool HybridMccopilotRN::cryptoArgon2Verify(
    const std::string& password,
    const std::string& hash) {
  FfiBuf_u8 buf = boltffi_crypto_argon2_verify(
    reinterpret_cast<const uint8_t*>(password.data()),
    static_cast<uintptr_t>(password.size()),
    reinterpret_cast<const uint8_t*>(hash.data()),
    static_cast<uintptr_t>(hash.size()));
  WireReader reader(buf.ptr, buf.len);
  auto result = StringResult::decode(reader);
  boltffi_free_buf_u8(buf);
  result.throwIfError();
  return result.data == "true";
}

} // namespace margelo::nitro::mccopilot
