import Foundation

/// RN 远程 Chunk 的本地文件缓存管理器
class ChunkCacheManager {

    static let shared = ChunkCacheManager()

    private let cacheDirectory: URL
    private let queue = DispatchQueue(label: "com.mccopilot.chunkcache", qos: .userInitiated)
    private var manifestChunks: [String: [String: Any]] = [:]

    // 缓存策略常量
    private let maxVersionsPerChunk = 3
    private let maxCacheSizeBytes: Int64 = 50 * 1024 * 1024  // 50 MB
    private let maxVersionAgeDays: Int = 7
    private let maxOrphanAgeDays: Int = 1

    private init() {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDir.appendingPathComponent("MCCopilot/rn/chunks", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Get cached chunk file path, optionally matching a specific hash
    func getCachedChunkPath(chunkId: String, hash: String? = nil) -> String? {
        return queue.sync {
            let files = (try? FileManager.default.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: nil
            )) ?? []
            let prefix = "\(chunkId)."
            let matchingFiles = files.filter { $0.lastPathComponent.hasPrefix(prefix) }

            if let targetHash = hash {
                return matchingFiles.first { file in
                    let parts = file.lastPathComponent.components(separatedBy: ".")
                    return parts.count >= 2 && parts[1] == targetHash
                }?.path
            }

            return matchingFiles.first?.path
        }
    }

    /// Check if cached chunk is stale compared to manifest
    func isChunkStale(chunkId: String) -> Bool {
        return queue.sync {
            guard let manifestHash = (manifestChunks[chunkId] as? [String: Any])?["hash"] as? String else {
                return true
            }
            let files = (try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)) ?? []
            let prefix = "\(chunkId)."
            guard let cachedFile = files.first(where: { $0.lastPathComponent.hasPrefix(prefix) }) else {
                return true
            }
            let parts = cachedFile.lastPathComponent.components(separatedBy: ".")
            guard parts.count >= 3 else { return true }
            let fileHash = parts[1]
            return fileHash != manifestHash
        }
    }

    /// Save chunk data to cache with multi-version retention
    @discardableResult
    func saveChunk(chunkId: String, hash: String, data: String) -> String? {
        return queue.sync {
            let filename = "\(chunkId).\(hash).js"
            let filePath = cacheDirectory.appendingPathComponent(filename)

            // Already cached with this exact hash
            if FileManager.default.fileExists(atPath: filePath.path) {
                return filePath.path
            }

            // Write new version
            do {
                try data.write(to: filePath, atomically: true, encoding: .utf8)
            } catch {
                print("[ChunkCacheManager] Failed to save chunk \(chunkId): \(error)")
                return nil
            }

            // Enforce version limit and cache size
            enforceVersionLimit(chunkId: chunkId)
            enforceCacheSizeLimit()

            return filePath.path
        }
    }

    /// Update the in-memory manifest for staleness checks
    func updateManifest(_ manifestJSON: String) {
        queue.sync {
            guard let data = manifestJSON.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let rn = json["rn"] as? [String: Any],
                  let chunks = rn["chunks"] as? [String: [String: Any]] else {
                return
            }
            manifestChunks = chunks
        }
    }

    /// Get the cache directory path
    func getCacheDirectory() -> String {
        return cacheDirectory.path
    }

    /// Clean stale cache with age and size enforcement
    func cleanStaleCache() {
        queue.sync {
            let files = ((try? FileManager.default.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.creationDateKey]
            )) ?? [])

            let now = Date()

            for file in files {
                let filename = file.lastPathComponent
                let chunkId = filename.components(separatedBy: ".").first ?? ""
                let creationDate = (try? file.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                let age = now.timeIntervalSince(creationDate)

                if !manifestChunks.keys.contains(chunkId) {
                    if age > Double(maxOrphanAgeDays * 86400) {
                        try? FileManager.default.removeItem(at: file)
                    }
                } else {
                    let parts = filename.components(separatedBy: ".")
                    let fileHash = parts.count >= 2 ? parts[1] : ""
                    let currentHash = (manifestChunks[chunkId] as? [String: Any])?["hash"] as? String

                    if fileHash != currentHash, age > Double(maxVersionAgeDays * 86400) {
                        try? FileManager.default.removeItem(at: file)
                    }
                }
            }

            enforceCacheSizeLimit()
        }
    }

    /// Get cache statistics
    func getCacheStats() -> [String: Any] {
        return queue.sync {
            let files = ((try? FileManager.default.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey]
            )) ?? [])

            var totalSize: Int64 = 0
            var versionCounts: [String: Int] = [:]

            for file in files {
                let size = Int64((try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
                totalSize += size
                let chunkId = file.lastPathComponent.components(separatedBy: ".").first ?? ""
                versionCounts[chunkId, default: 0] += 1
            }

            return [
                "totalSize": totalSize,
                "fileCount": files.count,
                "maxSize": maxCacheSizeBytes,
                "versionCounts": versionCounts,
            ]
        }
    }

    // MARK: - Private

    private func enforceVersionLimit(chunkId: String) {
        let prefix = "\(chunkId)."
        let files = ((try? FileManager.default.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.creationDateKey]
        )) ?? [])
        .filter { $0.lastPathComponent.hasPrefix(prefix) }

        guard files.count > maxVersionsPerChunk else { return }

        let sorted = files.sorted { a, b in
            let dateA = (try? a.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
            let dateB = (try? b.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
            return dateA < dateB
        }

        let toRemove = sorted.prefix(files.count - maxVersionsPerChunk)
        for file in toRemove {
            try? FileManager.default.removeItem(at: file)
        }
    }

    private func enforceCacheSizeLimit() {
        let size = totalCacheSize()
        guard size > maxCacheSizeBytes else { return }

        let files = ((try? FileManager.default.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentAccessDateKey, .fileSizeKey]
        )) ?? [])
        .sorted { a, b in
            let dateA = (try? a.resourceValues(forKeys: [.contentAccessDateKey]))?.contentAccessDate ?? .distantPast
            let dateB = (try? b.resourceValues(forKeys: [.contentAccessDateKey]))?.contentAccessDate ?? .distantPast
            return dateA < dateB
        }

        var remainingSize = size
        for file in files {
            guard remainingSize > maxCacheSizeBytes else { break }
            let fileSize = Int64((try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
            try? FileManager.default.removeItem(at: file)
            remainingSize -= fileSize
        }
    }

    private func totalCacheSize() -> Int64 {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        )) ?? []
        return files.reduce(Int64(0)) { sum, file in
            let size = Int64((try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
            return sum + size
        }
    }
}
