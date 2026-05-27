declare const TextEncoder: {
  new (): {encode(input: string): Uint8Array};
};

import {Script, ScriptManager} from '@callstack/repack/client';
import {API_BASE_URL} from './config';
import {NativeModules} from 'react-native';
import {MccopilotRNModule} from 'react-native-mccopilot';

const ChunkCacheModule = NativeModules.ChunkCacheModule;

type ChunkMeta = {
  hash: string;
  size: number;
  path: string;
};

type Manifest = {
  version: string;
  rn: {
    minimum_client_version: string;
    chunks: Record<string, ChunkMeta>;
  };
};

let cachedManifest: Manifest | null = null;

async function nativeFetch(
  url: string,
): Promise<{status: number; body: string}> {
  if (!ChunkCacheModule?.fetchURL) {
    throw new Error('ChunkCacheModule.fetchURL not available');
  }
  return ChunkCacheModule.fetchURL(url) as Promise<{
    status: number;
    body: string;
  }>;
}

async function getManifest(): Promise<Manifest> {
  if (cachedManifest) {
    return cachedManifest;
  }
  const {status, body} = await nativeFetch(`${API_BASE_URL}/api/v1/manifest`);
  if (status !== 200) {
    throw new Error(`Failed to fetch manifest: ${status}`);
  }
  cachedManifest = JSON.parse(body) as Manifest;
  return cachedManifest!;
}

function clearManifestCache() {
  cachedManifest = null;
}

export function setupChunkResolver() {
  if (__DEV__) {
    ScriptManager.shared.addResolver(async (scriptId: string) => {
      return {
        url: Script.getDevServerURL(scriptId),
        cache: false,
      };
    });
    return;
  }

  ScriptManager.shared.addResolver(async (scriptId: string) => {
    // 1. Fetch manifest (JS-side cached)
    const manifest = await getManifest();
    const chunkMeta = manifest.rn.chunks[scriptId];

    if (!chunkMeta) {
      throw new Error(`Chunk "${scriptId}" not found in manifest`);
    }

    // 2. Check cache with exact hash match
    if (ChunkCacheModule) {
      const cachedPath: string | null =
        await ChunkCacheModule.getCachedChunkPath(scriptId, chunkMeta.hash);
      if (cachedPath) {
        return {
          url: `file://${cachedPath}`,
          absolute: true,
          cache: true,
        };
      }
    }

    // 3. No cache hit — download fresh chunk
    const {status, body: chunkData} = await nativeFetch(
      `${API_BASE_URL}/api/v1/chunks/${scriptId}?hash=${chunkMeta.hash}`,
    );
    if (status !== 200) {
      throw new Error(`Failed to download chunk "${scriptId}": ${status}`);
    }

    // 4. Verify hash with Rust SHA-256
    const dataBuffer = new TextEncoder().encode(chunkData);
    const actualHash = MccopilotRNModule.cryptoHash(
      'sha256',
      dataBuffer.buffer as ArrayBuffer,
    );
    if (actualHash !== chunkMeta.hash) {
      throw new Error(
        `Chunk "${scriptId}" hash mismatch: expected ${chunkMeta.hash}, got ${actualHash}`,
      );
    }

    // 5. Save to cache and return
    if (ChunkCacheModule) {
      const savedPath: string = await ChunkCacheModule.saveChunk(
        scriptId,
        chunkMeta.hash,
        chunkData,
      );
      return {
        url: `file://${savedPath}`,
        absolute: true,
        cache: true,
      };
    }

    return {
      url: `${API_BASE_URL}/api/v1/chunks/${scriptId}`,
      cache: false,
    };
  });
}

export {getManifest, clearManifestCache};
