#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="${1:-/tmp/FNF-LOVE-source.tar.gz}"

rm -f "$OUTPUT"
tar -C "$ROOT" \
  --exclude='./.git' \
  --exclude='./release' \
  --exclude='*.apk' \
  --exclude='*.idsig' \
  --exclude='*.love' \
  --exclude='*.keystore' \
  -czf "$OUTPUT" .

echo "$OUTPUT"
