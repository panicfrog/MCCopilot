import Foundation
import React

/// RN Native Module bridge for chunk caching
/// Exposes ChunkCacheManager methods to React Native via RCTBridge
@objc(ChunkCacheModule)
class ChunkCacheModule: NSObject {

    @objc
    static func requiresMainQueueSetup() -> Bool {
        return false
    }

    @objc(getCachedChunkPath:hash:resolver:rejecter:)
    func getCachedChunkPath(_ chunkId: String,
                            hash: String?,
                            resolve: @escaping RCTPromiseResolveBlock,
                            reject: @escaping RCTPromiseRejectBlock) {
        print("[ChunkCacheModule] getCachedChunkPath called: \(chunkId), hash: \(hash ?? "nil")")
        if let path = ChunkCacheManager.shared.getCachedChunkPath(chunkId: chunkId, hash: hash) {
            print("[ChunkCacheModule] Found cached chunk: \(path)")
            resolve(path)
        } else {
            print("[ChunkCacheModule] No cached chunk for: \(chunkId)")
            resolve(nil)
        }
    }

    @objc(isChunkStale:resolver:rejecter:)
    func isChunkStale(_ chunkId: String,
                      resolve: @escaping RCTPromiseResolveBlock,
                      reject: @escaping RCTPromiseRejectBlock) {
        let stale = ChunkCacheManager.shared.isChunkStale(chunkId: chunkId)
        print("[ChunkCacheModule] isChunkStale(\(chunkId)): \(stale)")
        resolve(stale)
    }

    @objc(saveChunk:hash:data:resolver:rejecter:)
    func saveChunk(_ chunkId: String,
                   hash: String,
                   data: String,
                   resolve: @escaping RCTPromiseResolveBlock,
                   reject: @escaping RCTPromiseRejectBlock) {
        print("[ChunkCacheModule] saveChunk: \(chunkId), hash: \(hash), dataSize: \(data.count)")
        if let path = ChunkCacheManager.shared.saveChunk(chunkId: chunkId, hash: hash, data: data) {
            print("[ChunkCacheModule] Saved chunk to: \(path)")
            resolve(path)
        } else {
            print("[ChunkCacheModule] Failed to save chunk: \(chunkId)")
            reject("SAVE_ERROR", "Failed to save chunk", nil)
        }
    }

    @objc(updateManifest:resolver:rejecter:)
    func updateManifest(_ manifestJSON: String,
                        resolve: @escaping RCTPromiseResolveBlock,
                        reject: @escaping RCTPromiseRejectBlock) {
        print("[ChunkCacheModule] updateManifest called, json length: \(manifestJSON.count)")
        ChunkCacheManager.shared.updateManifest(manifestJSON)
        resolve(nil)
    }

    @objc(getCacheDirectory:rejecter:)
    func getCacheDirectory(_ resolve: @escaping RCTPromiseResolveBlock,
                           reject: @escaping RCTPromiseRejectBlock) {
        resolve(ChunkCacheManager.shared.getCacheDirectory())
    }

    @objc(getCacheStats:rejecter:)
    func getCacheStats(_ resolve: @escaping RCTPromiseResolveBlock,
                       reject: @escaping RCTPromiseRejectBlock) {
        resolve(ChunkCacheManager.shared.getCacheStats())
    }

    @objc(fetchURL:resolver:rejecter:)
    func fetchURL(_ url: String,
                  resolve: @escaping RCTPromiseResolveBlock,
                  reject: @escaping RCTPromiseRejectBlock) {
        print("[ChunkCacheModule] fetchURL: \(url)")
        guard let requestURL = URL(string: url) else {
            reject("INVALID_URL", "Invalid URL: \(url)", nil)
            return
        }

        let task = URLSession.shared.dataTask(with: requestURL) { data, response, error in
            if let error = error {
                print("[ChunkCacheModule] fetchURL error: \(error)")
                reject("FETCH_ERROR", error.localizedDescription, error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                reject("FETCH_ERROR", "Not an HTTP response", nil)
                return
            }

            guard let data = data, let text = String(data: data, encoding: .utf8) else {
                reject("FETCH_ERROR", "Failed to decode response", nil)
                return
            }

            print("[ChunkCacheModule] fetchURL success: status=\(httpResponse.statusCode), size=\(text.count)")
            resolve([
                "status": httpResponse.statusCode,
                "body": text,
            ])
        }
        task.resume()
    }
}
