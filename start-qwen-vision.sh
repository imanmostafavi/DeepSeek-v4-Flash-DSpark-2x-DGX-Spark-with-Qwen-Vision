#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-.env.qwen-vision}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.qwen-vision.yml}"
WORKER_HOST="${QWEN_WORKER_HOST:?Set QWEN_WORKER_HOST to the worker SSH host}"
WORKER_DIR="${QWEN_WORKER_DIR:?Set QWEN_WORKER_DIR to the worker checkout path}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE; copy .env.qwen-vision.example and edit it first." >&2
  exit 2
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

if [[ "${NODE_RANK:-0}" != "0" ]]; then
  echo "Run this launcher on the head node with NODE_RANK=0." >&2
  exit 2
fi

echo "Syncing Qwen Vision compose configuration to $WORKER_HOST:$WORKER_DIR"
ssh "$WORKER_HOST" "mkdir -p '$WORKER_DIR'"
rsync -a --delete \
  --exclude '.git' \
  "$COMPOSE_FILE" "$ENV_FILE" \
  "$WORKER_HOST:$WORKER_DIR/"

echo "Starting Qwen Vision worker first"
ssh "$WORKER_HOST" "cd '$WORKER_DIR' && NODE_RANK=1 docker compose --env-file '$ENV_FILE' -f '$COMPOSE_FILE' up -d"

echo "Starting Qwen Vision head"
NODE_RANK=0 docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d

echo "Checking the head endpoint"
for _ in {1..60}; do
  if curl --fail --silent "http://${QWEN_VISION_HOST:-127.0.0.1}:${QWEN_VISION_PORT:-8890}/v1/models" >/dev/null; then
    echo "Qwen Vision is ready at http://${QWEN_VISION_HOST:-127.0.0.1}:${QWEN_VISION_PORT:-8890}/v1"
    exit 0
  fi
  sleep 5
done

echo "Qwen Vision did not become ready; inspect logs on both nodes." >&2
exit 1
