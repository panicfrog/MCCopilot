#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REMOTES_DIR="$PROJECT_ROOT/ReactNative/build/outputs/ios/remotes"
MANIFEST_FILE="$SCRIPT_DIR/manifest.json"

# Configuration (override via env vars)
API_BASE_URL="${API_BASE_URL:-http://localhost:3000}"
AUTH_TOKEN="${AUTH_TOKEN:-dev-secret-change-me}"

echo "=== MCCopilot Chunk Upload ==="
echo "API: $API_BASE_URL"
echo ""

# Step 1: Build RN bundle
echo ">>> Step 1: Building RN bundle..."
cd "$PROJECT_ROOT/ReactNative"
npm run bundle-ios

# Step 2: Generate manifest
echo ""
echo ">>> Step 2: Generating manifest..."
cd "$PROJECT_ROOT"
node "$SCRIPT_DIR/build-manifest.mjs" "$REMOTES_DIR" "$MANIFEST_FILE"

# Step 3: Upload each chunk file
echo ""
echo ">>> Step 3: Uploading chunks..."

if [ ! -d "$REMOTES_DIR" ]; then
  echo "ERROR: Remotes directory not found: $REMOTES_DIR"
  exit 1
fi

for file in "$REMOTES_DIR"/*; do
  [ -f "$file" ] || continue
  filename=$(basename "$file")
  chunk_id=$(echo "$filename" | cut -d'.' -f1)

  echo "Uploading chunk: $chunk_id ($filename)"
  curl -s -X POST "$API_BASE_URL/api/v1/upload" \
    -H "Authorization: Bearer $AUTH_TOKEN" \
    -F "chunk_id=$chunk_id" \
    -F "platform=rn" \
    -F "file=@$file" | python3 -m json.tool
  echo ""
done

# Step 4: Update manifest on server
echo ">>> Step 4: Updating manifest..."
curl -s -X PUT "$API_BASE_URL/api/v1/manifest" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d @"$MANIFEST_FILE" | python3 -m json.tool

echo ""
echo "=== Upload complete! ==="
