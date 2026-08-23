#!/usr/bin/env bash
# Download the Helpa model weights.
#
#   - idempotent: safe to run repeatedly
#   - no credentials: public HuggingFace URL
#   - output path matches `_runtime.model_path` in metadata.json

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_DIR="$HERE/model"
MODEL_FILE="$MODEL_DIR/Helpa-Gemma4-E2B-Q4_K_M.gguf"

# ── PUBLIC model weight URL ───────────────────────────────────────────────────
MODEL_URL="https://huggingface.co/yusasif/Helpa-ADTC-challenge/resolve/main/FirstAid-Gemma4-E2B-Q4_K_M.gguf"
# ──────────────────────────────────────────────────────────────────────────────

mkdir -p "$MODEL_DIR"

if [[ -f "$MODEL_FILE" ]]; then
  echo "model already present at $MODEL_FILE — skipping download"
  exit 0
fi

echo "downloading $MODEL_URL → $MODEL_FILE …"

if command -v curl > /dev/null 2>&1; then
  curl -L --fail --progress-bar -o "$MODEL_FILE.partial" "$MODEL_URL"
elif command -v wget > /dev/null 2>&1; then
  wget --show-progress -O "$MODEL_FILE.partial" "$MODEL_URL"
else
  echo "error: neither curl nor wget found" >&2
  exit 1
fi

mv "$MODEL_FILE.partial" "$MODEL_FILE"
echo "done: $MODEL_FILE"
