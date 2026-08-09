#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${QWEN_VISION_BASE_URL:-http://127.0.0.1:${QWEN_VISION_PORT:-8890}/v1}"
MODEL="${QWEN_VISION_SERVED_MODEL:-qwen3.5-9b-vision}"
IMAGE_URL="${IMAGE_URL:-https://upload.wikimedia.org/wikipedia/commons/3/3f/Fronalpstock_big.jpg}"
export MODEL IMAGE_URL

curl --fail --silent "$BASE_URL/models" >/dev/null
curl --fail --silent "$BASE_URL/chat/completions" \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer local' \
  -d "$(python3 -c 'import json, os; print(json.dumps({"model": os.environ["MODEL"], "messages": [{"role": "user", "content": [{"type": "text", "text": "Describe this image in one sentence."}, {"type": "image_url", "image_url": {"url": os.environ["IMAGE_URL"]}}]}], "max_tokens": 128}))' )"
