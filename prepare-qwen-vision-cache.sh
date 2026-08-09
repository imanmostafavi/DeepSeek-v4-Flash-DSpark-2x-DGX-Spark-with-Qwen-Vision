#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-.env.qwen-vision}"
IMAGE="${QWEN_VISION_IMAGE:-ghcr.io/imanmostafavi/dspark-qwen-vision@sha256:0898f08028ffc48d5f232d750c58ea8cac9e434ec21d3b875c6c62a945acb2a3}"
MODEL="${QWEN_VISION_MODEL:-RedHatAI/Qwen3.5-9B-quantized.w4a16}"
HF_CACHE="${HF_CACHE:-$HOME/.cache/huggingface}"
QWEN_SYNC_CACHE="${QWEN_SYNC_CACHE:-1}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
  IMAGE="${QWEN_VISION_IMAGE:-$IMAGE}"
  MODEL="${QWEN_VISION_MODEL:-$MODEL}"
  HF_CACHE="${HF_CACHE:-$HOME/.cache/huggingface}"
  QWEN_SYNC_CACHE="${QWEN_SYNC_CACHE:-1}"
fi

mkdir -p "$HF_CACHE"
echo "Preparing Qwen Vision model cache: $MODEL"

docker run --rm --gpus all \
  -v "$HF_CACHE:/cache/huggingface" \
  -e HF_HOME=/cache/huggingface \
  -e HF_TOKEN="${HF_TOKEN:-}" \
  -e MODEL="$MODEL" \
  "$IMAGE" \
  python3 -c 'from huggingface_hub import snapshot_download; import os; print(snapshot_download(os.environ["MODEL"], max_workers=4))'

echo "Qwen Vision cache is ready at $HF_CACHE"

if [[ -n "${QWEN_WORKER_HOST:-}" && -n "${QWEN_WORKER_DIR:-}" && "${PREPARE_WORKER:-1}" == "1" ]]; then
  WORKER_HF_CACHE="${QWEN_WORKER_HF_CACHE:-$HF_CACHE}"
  echo "Preparing the worker cache on $QWEN_WORKER_HOST"
  ssh "$QWEN_WORKER_HOST" "mkdir -p '$QWEN_WORKER_DIR'"
  ssh "$QWEN_WORKER_HOST" "mkdir -p '$WORKER_HF_CACHE'"

  if [[ "$QWEN_SYNC_CACHE" == "1" ]]; then
    echo "Syncing the prepared Hugging Face cache to $QWEN_WORKER_HOST:$WORKER_HF_CACHE"
    rsync -aH --info=progress2 "$HF_CACHE/" "$QWEN_WORKER_HOST:$WORKER_HF_CACHE/"
  else
    echo "QWEN_SYNC_CACHE=0; downloading independently on the worker"
    rsync -a --delete --exclude '.git' "$ENV_FILE" "$(basename "$0")" "$QWEN_WORKER_HOST:$QWEN_WORKER_DIR/"
    ssh "$QWEN_WORKER_HOST" "cd '$QWEN_WORKER_DIR' && PREPARE_WORKER=0 ENV_FILE='$ENV_FILE' HF_CACHE='$WORKER_HF_CACHE' ./$(basename "$0")"
  fi
fi
