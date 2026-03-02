#include "HybridMccopilotRN.hpp"
#include "BoltFFIWire.hpp"
#include <NitroModules/ArrayBuffer.hpp>
#include <stdexcept>
#include <cmath>
#include <limits>

extern "C" {
#include "mccopilot.h"
}

namespace margelo::nitro::mccopilot {

using ::mccopilot::WireWriter;
using ::mccopilot::WireReader;
using ::mccopilot::StringResult;
using ::mccopilot::BytesResult;

// RAII guard for FfiBuf_u8, prevents memory leaks on exceptions
class FfiBufGuard {
  FfiBuf_u8 buf_;

public:
  explicit FfiBufGuard(FfiBuf_u8 buf) : buf_(buf) {}
  ~FfiBufGuard() { boltffi_free_buf_u8(buf_); }
  FfiBufGuard(const FfiBufGuard&) = delete;
  FfiBufGuard& operator=(const FfiBufGuard&) = delete;

  const uint8_t* data() const { return buf_.ptr; }
  size_t size() const { return buf_.len; }
};

// --- helpers ---

static int32_t parseHashAlgorithm(const std::string& algo) {
  if (algo == "sha256") return 0;
  if (algo == "sha384") return 1;
  if (algo == "sha512") return 2;
  throw std::runtime_error("Unknown hash algorithm: " + algo);
}

static uint32_t safeToU32(double v, const char* name) {
  if (std::isnan(v) || v < 0 || v > static_cast<double>(std::numeric_limits<uint32_t>::max())) {
    throw std::runtime_error(std::string(name) + " must be a non-negative integer within uint32 range");
  }
  return static_cast<uint32_t>(v);
}

static void writeArgon2Params(WireWriter& w, const std::optional<Argon2Params>& params) {
  if (!params.has_value()) {
    w.writeU8(0);
    return;
  }
  w.writeU8(1);
  w.writeBlittable(safeToU32(params->memoryCost, "memoryCost"));
  w.writeBlittable(safeToU32(params->timeCost, "timeCost"));
  w.writeBlittable(safeToU32(params->parallelism, "parallelism"));
  w.writeBlittable(safeToU32(params->outputLength, "outputLength"));
}

static void writeBuffer(WireWriter& w, const std::shared_ptr<ArrayBuffer>& buf) {
  w.writeBytes(buf->data(), buf->size());
}

static void writeOptionalBuffer(WireWriter& w, const std::optional<std::shared_ptr<ArrayBuffer>>& buf) {
  if (!buf.has_value()) {
    w.writeU8(0);
    return;
  }
  const auto& val = buf.value();
  if (!val) {
    throw std::runtime_error("BoltFFI: optional ArrayBuffer has value but shared_ptr is null");
  }
  w.writeU8(1);
  writeBuffer(w, val);
}

static std::shared_ptr<ArrayBuffer> bytesToArrayBuffer(const std::vector<uint8_t>& bytes) {
  if (bytes.empty()) {
    return ArrayBuffer::allocate(0);
  }
  return ArrayBuffer::copy(bytes);
}

// --- HybridMccopilotRN implementation ---

std::string HybridMccopilotRN::getVersion() {
  FfiBufGuard guard(boltffi_get_version());
  WireReader reader(guard.data(), guard.size());
  return reader.readString();
}

std::string HybridMccopilotRN::cryptoHash(
    const std::string& algorithm,
    const std::shared_ptr<ArrayBuffer>& data) {
  WireWriter algoW;
  algoW.writeI32(parseHashAlgorithm(algorithm));

  WireWriter dataW;
  writeBuffer(dataW, data);

  FfiBufGuard guard(boltffi_crypto_hash(
    algoW.data(), algoW.size(),
    dataW.data(), dataW.size()));
  WireReader reader(guard.data(), guard.size());
  auto result = StringResult::decode(reader);
  result.throwIfError();
  return result.data;
}

std::shared_ptr<ArrayBuffer> HybridMccopilotRN::cryptoHkdfDerive(
    const std::shared_ptr<ArrayBuffer>& salt,
    const std::shared_ptr<ArrayBuffer>& ikm,
    const std::optional<std::shared_ptr<ArrayBuffer>>& info,
    double outputLength) {
  auto outLen = safeToU32(outputLength, "outputLength");

  WireWriter saltW; writeBuffer(saltW, salt);
  WireWriter ikmW;  writeBuffer(ikmW, ikm);
  WireWriter infoW; writeOptionalBuffer(infoW, info);

  FfiBufGuard guard(boltffi_crypto_hkdf_derive(
    saltW.data(), saltW.size(),
    ikmW.data(), ikmW.size(),
    infoW.data(), infoW.size(),
    static_cast<uintptr_t>(outLen)));
  WireReader reader(guard.data(), guard.size());
  auto result = BytesResult::decode(reader);
  result.throwIfError();
  return bytesToArrayBuffer(result.data);
}

std::shared_ptr<ArrayBuffer> HybridMccopilotRN::cryptoPbkdf2Derive(
    const std::shared_ptr<ArrayBuffer>& password,
    const std::shared_ptr<ArrayBuffer>& salt,
    double iterations,
    double outputLength) {
  auto iter   = safeToU32(iterations, "iterations");
  auto outLen = safeToU32(outputLength, "outputLength");

  WireWriter pwW;   writeBuffer(pwW, password);
  WireWriter saltW; writeBuffer(saltW, salt);

  FfiBufGuard guard(boltffi_crypto_pbkdf2_derive(
    pwW.data(), pwW.size(),
    saltW.data(), saltW.size(),
    iter,
    static_cast<uintptr_t>(outLen)));
  WireReader reader(guard.data(), guard.size());
  auto result = BytesResult::decode(reader);
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

  FfiBufGuard guard(boltffi_crypto_aes_cbc_encrypt(
    keyW.data(), keyW.size(),
    ivW.data(), ivW.size(),
    ptW.data(), ptW.size()));
  WireReader reader(guard.data(), guard.size());
  auto result = BytesResult::decode(reader);
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

  FfiBufGuard guard(boltffi_crypto_aes_cbc_decrypt(
    keyW.data(), keyW.size(),
    ivW.data(), ivW.size(),
    ctW.data(), ctW.size()));
  WireReader reader(guard.data(), guard.size());
  auto result = BytesResult::decode(reader);
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

  FfiBufGuard guard(boltffi_crypto_aes_ctr(
    keyW.data(), keyW.size(),
    nonceW.data(), nonceW.size(),
    dataW.data(), dataW.size()));
  WireReader reader(guard.data(), guard.size());
  auto result = StringResult::decode(reader);
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

  FfiBufGuard guard(boltffi_crypto_aes_gcm_encrypt(
    keyW.data(), keyW.size(),
    nonceW.data(), nonceW.size(),
    ptW.data(), ptW.size(),
    aadW.data(), aadW.size()));
  WireReader reader(guard.data(), guard.size());
  auto result = BytesResult::decode(reader);
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

  FfiBufGuard guard(boltffi_crypto_aes_gcm_decrypt(
    keyW.data(), keyW.size(),
    nonceW.data(), nonceW.size(),
    ctW.data(), ctW.size(),
    aadW.data(), aadW.size()));
  WireReader reader(guard.data(), guard.size());
  auto result = BytesResult::decode(reader);
  result.throwIfError();
  return bytesToArrayBuffer(result.data);
}

std::shared_ptr<ArrayBuffer> HybridMccopilotRN::cryptoAesGcmGenerateNonce() {
  FfiBufGuard guard(boltffi_crypto_aes_gcm_generate_nonce());
  WireReader reader(guard.data(), guard.size());
  auto result = BytesResult::decode(reader);
  result.throwIfError();
  return bytesToArrayBuffer(result.data);
}

std::shared_ptr<ArrayBuffer> HybridMccopilotRN::cryptoAesGenerateIv() {
  FfiBufGuard guard(boltffi_crypto_aes_generate_iv());
  WireReader reader(guard.data(), guard.size());
  auto result = BytesResult::decode(reader);
  result.throwIfError();
  return bytesToArrayBuffer(result.data);
}

std::string HybridMccopilotRN::cryptoArgon2Hash(
    const std::string& password,
    const std::optional<Argon2Params>& params) {
  WireWriter paramsW;
  writeArgon2Params(paramsW, params);

  FfiBufGuard guard(boltffi_crypto_argon2_hash(
    reinterpret_cast<const uint8_t*>(password.data()),
    static_cast<uintptr_t>(password.size()),
    paramsW.data(), paramsW.size()));
  WireReader reader(guard.data(), guard.size());
  auto result = StringResult::decode(reader);
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

  FfiBufGuard guard(boltffi_crypto_argon2_hash_with_salt(
    pwW.data(), pwW.size(),
    saltW.data(), saltW.size(),
    paramsW.data(), paramsW.size()));
  WireReader reader(guard.data(), guard.size());
  auto result = BytesResult::decode(reader);
  result.throwIfError();
  return bytesToArrayBuffer(result.data);
}

bool HybridMccopilotRN::cryptoArgon2Verify(
    const std::string& password,
    const std::string& hash) {
  FfiBufGuard guard(boltffi_crypto_argon2_verify(
    reinterpret_cast<const uint8_t*>(password.data()),
    static_cast<uintptr_t>(password.size()),
    reinterpret_cast<const uint8_t*>(hash.data()),
    static_cast<uintptr_t>(hash.size())));
  WireReader reader(guard.data(), guard.size());
  auto result = StringResult::decode(reader);
  result.throwIfError();
  return result.data == "true";
}

} // namespace margelo::nitro::mccopilot
