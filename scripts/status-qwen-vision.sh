#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-.env.qwen-vision}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.qwen-vision.yml}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" ps

if command -v curl >/dev/null 2>&1; then
  port="${QWEN_VISION_PORT:-8890}"
  echo
  echo "Models at http://127.0.0.1:${port}/v1/models:"
  curl --fail --silent "http://127.0.0.1:${port}/v1/models" || true
  echo
fi
