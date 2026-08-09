#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-.env.qwen-vision}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

BASE_URL="${QWEN_VISION_BASE_URL:-http://127.0.0.1:${QWEN_VISION_PORT:-8890}/v1}"
MODEL="${QWEN_VISION_SERVED_MODEL:-qwen3.5-9b-vision}"
if [[ -z "${IMAGE_URL:-}" ]]; then
  IMAGE_URL="$(python3 -c 'import base64, struct, zlib
w = h = 64
raw = b"".join(b"\x00" + b"\xff\x00\x00" * w for _ in range(h))
def chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff)
png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b"")
print("data:image/png;base64," + base64.b64encode(png).decode())')"
fi
export MODEL IMAGE_URL

curl --fail --silent "$BASE_URL/models" >/dev/null
curl --fail --silent "$BASE_URL/chat/completions" \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer local' \
  -d "$(python3 -c 'import json, os; print(json.dumps({"model": os.environ["MODEL"], "messages": [{"role": "user", "content": [{"type": "text", "text": "What is the dominant color in this image? Answer with one word."}, {"type": "image_url", "image_url": {"url": os.environ["IMAGE_URL"]}}]}], "max_tokens": 32}))' )"
