#pragma once

#include <vector>
#include <string>
#include <cstring>
#include <cstdint>
#include <optional>
#include <stdexcept>

namespace mccopilot {

class WireWriter {
  std::vector<uint8_t> bytes_;

public:
  void writeU8(uint8_t v) {
    bytes_.push_back(v);
  }

  void writeI32(int32_t v) {
    const auto* p = reinterpret_cast<const uint8_t*>(&v);
    bytes_.insert(bytes_.end(), p, p + 4);
  }

  void writeU32(uint32_t v) {
    const auto* p = reinterpret_cast<const uint8_t*>(&v);
    bytes_.insert(bytes_.end(), p, p + 4);
  }

  void writeBool(bool v) {
    bytes_.push_back(v ? 1 : 0);
  }

  void writeString(const std::string& v) {
    writeU32(static_cast<uint32_t>(v.size()));
    bytes_.insert(bytes_.end(), v.begin(), v.end());
  }

  void writeBytes(const uint8_t* ptr, size_t len) {
    writeU32(static_cast<uint32_t>(len));
    if (len > 0 && ptr != nullptr) {
      bytes_.insert(bytes_.end(), ptr, ptr + len);
    }
  }

  void writeOptionalNone() { bytes_.push_back(0); }
  void writeOptionalSome() { bytes_.push_back(1); }

  template<typename T>
  void writeBlittable(const T& v) {
    const auto* p = reinterpret_cast<const uint8_t*>(&v);
    bytes_.insert(bytes_.end(), p, p + sizeof(T));
  }

  const uint8_t* data() const { return bytes_.data(); }
  size_t size() const { return bytes_.size(); }
};

class WireReader {
  const uint8_t* data_;
  size_t len_;
  size_t pos_ = 0;

public:
  WireReader(const uint8_t* data, size_t len)
    : data_(data), len_(len) {}

  uint8_t readU8() {
    return data_[pos_++];
  }

  int32_t readI32() {
    int32_t v;
    std::memcpy(&v, data_ + pos_, 4);
    pos_ += 4;
    return v;
  }

  uint32_t readU32() {
    uint32_t v;
    std::memcpy(&v, data_ + pos_, 4);
    pos_ += 4;
    return v;
  }

  bool readBool() {
    return data_[pos_++] != 0;
  }

  std::string readString() {
    uint32_t len = readU32();
    if (len == 0) return "";
    std::string s(reinterpret_cast<const char*>(data_ + pos_), len);
    pos_ += len;
    return s;
  }

  std::vector<uint8_t> readBytes() {
    uint32_t len = readU32();
    if (len == 0) return {};
    std::vector<uint8_t> buf(data_ + pos_, data_ + pos_ + len);
    pos_ += len;
    return buf;
  }

  bool readOptionalFlag() {
    return data_[pos_++] != 0;
  }

  std::optional<std::string> readOptionalString() {
    if (!readOptionalFlag()) return std::nullopt;
    return readString();
  }

  template<typename T>
  T readBlittable() {
    T v;
    std::memcpy(&v, data_ + pos_, sizeof(T));
    pos_ += sizeof(T);
    return v;
  }
};

struct StringResult {
  bool success;
  std::string data;
  std::optional<std::string> error;

  static StringResult decode(WireReader& reader) {
    StringResult r;
    r.success = reader.readBool();
    r.data = reader.readString();
    r.error = reader.readOptionalString();
    return r;
  }

  void throwIfError() const {
    if (!success) {
      throw std::runtime_error(error.value_or("unknown FFI error"));
    }
  }
};

struct BytesResult {
  bool success;
  std::vector<uint8_t> data;
  std::optional<std::string> error;

  static BytesResult decode(WireReader& reader) {
    BytesResult r;
    r.success = reader.readBool();
    r.data = reader.readBytes();
    r.error = reader.readOptionalString();
    return r;
  }

  void throwIfError() const {
    if (!success) {
      throw std::runtime_error(error.value_or("unknown FFI error"));
    }
  }
};

} // namespace mccopilot
