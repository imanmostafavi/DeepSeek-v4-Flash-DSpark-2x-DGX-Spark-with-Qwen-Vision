#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.qwen-vision.yml}"

docker compose --env-file "${ENV_FILE:-.env.qwen-vision}" -f "$COMPOSE_FILE" ps

if command -v curl >/dev/null 2>&1; then
  port="${QWEN_VISION_PORT:-8890}"
  echo
  echo "Models at http://127.0.0.1:${port}/v1/models:"
  curl --fail --silent "http://127.0.0.1:${port}/v1/models" || true
  echo
fi
