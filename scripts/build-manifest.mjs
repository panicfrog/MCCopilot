#!/usr/bin/env node

/**
 * Build manifest.json from remote chunk files.
 * Reads the remotes directory, computes SHA-256 hashes, and outputs a manifest.
 *
 * Usage:
 *   node scripts/build-manifest.mjs [remotes-dir] [output-path]
 *
 * Defaults:
 *   remotes-dir: ReactNative/build/outputs/ios/remotes
 *   output-path: scripts/manifest.json
 */

import { createHash } from 'node:crypto';
import { readFileSync, readdirSync, writeFileSync, existsSync } from 'node:fs';
import { resolve, basename } from 'node:path';

const remotesDir = resolve(process.argv[2] || 'ReactNative/build/outputs/ios/remotes');
const outputPath = resolve(process.argv[3] || 'scripts/manifest.json');

if (!existsSync(remotesDir)) {
  console.error(`Remotes directory not found: ${remotesDir}`);
  console.error('Run "cd ReactNative && npm run bundle-ios" first.');
  process.exit(1);
}

const files = readdirSync(remotesDir).filter(f => f.endsWith('.js') || f.endsWith('.bundle'));

if (files.length === 0) {
  console.error('No chunk files found in remotes directory.');
  process.exit(1);
}

const chunks = {};

for (const file of files) {
  const filePath = resolve(remotesDir, file);
  const data = readFileSync(filePath);
  const hash = createHash('sha256').update(data).digest('hex');
  const size = data.length;

  // Extract chunk name from filename: "SecondRNApp.chunk.bundle" → "SecondRNApp"
  // or "SecondRNApp.abc123.js" → "SecondRNApp"
  const chunkId = file.split('.')[0];
  const s3Key = `rn/chunks/${chunkId}.${hash}.js`;

  chunks[chunkId] = { hash, size, path: s3Key };
}

const manifest = {
  version: '1.0.0',
  rn: {
    minimum_client_version: '1.0.0',
    chunks,
  },
};

writeFileSync(outputPath, JSON.stringify(manifest, null, 2));
console.log(`Manifest written to ${outputPath}`);
console.log(`Chunks: ${Object.keys(chunks).join(', ')}`);
