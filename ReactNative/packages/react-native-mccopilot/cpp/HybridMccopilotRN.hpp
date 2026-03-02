#pragma once

#include "HybridMccopilotRNSpec.hpp"

namespace margelo::nitro::mccopilot {

class HybridMccopilotRN : public HybridMccopilotRNSpec {
public:
  HybridMccopilotRN() : HybridObject(TAG) {}

  std::string getVersion() override;

  std::string cryptoHash(const std::string& algorithm, const std::shared_ptr<ArrayBuffer>& data) override;

  std::shared_ptr<ArrayBuffer> cryptoHkdfDerive(const std::shared_ptr<ArrayBuffer>& salt, const std::shared_ptr<ArrayBuffer>& ikm, const std::optional<std::shared_ptr<ArrayBuffer>>& info, double outputLength) override;
  std::shared_ptr<ArrayBuffer> cryptoPbkdf2Derive(const std::shared_ptr<ArrayBuffer>& password, const std::shared_ptr<ArrayBuffer>& salt, double iterations, double outputLength) override;

  std::shared_ptr<ArrayBuffer> cryptoAesCbcEncrypt(const std::shared_ptr<ArrayBuffer>& key, const std::shared_ptr<ArrayBuffer>& iv, const std::shared_ptr<ArrayBuffer>& plaintext) override;
  std::shared_ptr<ArrayBuffer> cryptoAesCbcDecrypt(const std::shared_ptr<ArrayBuffer>& key, const std::shared_ptr<ArrayBuffer>& iv, const std::shared_ptr<ArrayBuffer>& ciphertext) override;

  std::string cryptoAesCtr(const std::shared_ptr<ArrayBuffer>& key, const std::shared_ptr<ArrayBuffer>& nonce, const std::shared_ptr<ArrayBuffer>& data) override;

  std::shared_ptr<ArrayBuffer> cryptoAesGcmEncrypt(const std::shared_ptr<ArrayBuffer>& key, const std::shared_ptr<ArrayBuffer>& nonce, const std::shared_ptr<ArrayBuffer>& plaintext, const std::optional<std::shared_ptr<ArrayBuffer>>& aad) override;
  std::shared_ptr<ArrayBuffer> cryptoAesGcmDecrypt(const std::shared_ptr<ArrayBuffer>& key, const std::shared_ptr<ArrayBuffer>& nonce, const std::shared_ptr<ArrayBuffer>& ciphertext, const std::optional<std::shared_ptr<ArrayBuffer>>& aad) override;
  std::shared_ptr<ArrayBuffer> cryptoAesGcmGenerateNonce() override;
  std::shared_ptr<ArrayBuffer> cryptoAesGenerateIv() override;

  std::string cryptoArgon2Hash(const std::string& password, const std::optional<Argon2Params>& params) override;
  std::shared_ptr<ArrayBuffer> cryptoArgon2HashWithSalt(const std::shared_ptr<ArrayBuffer>& password, const std::shared_ptr<ArrayBuffer>& salt, const std::optional<Argon2Params>& params) override;
  bool cryptoArgon2Verify(const std::string& password, const std::string& hash) override;
};

} // namespace margelo::nitro::mccopilot
