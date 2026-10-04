#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="${1:-/tmp/Light-Engine-source.tar.gz}"

rm -f "$OUTPUT"
tar -C "$ROOT" \
  --exclude='./.git' \
  --exclude='./release' \
  --exclude='./android/keystore.jks' \
  --exclude='./android/keystore.properties' \
  --exclude='*.apk' \
  --exclude='*.idsig' \
  --exclude='*.love' \
  --exclude='*.keystore' \
  -czf "$OUTPUT" .

echo "$OUTPUT"
