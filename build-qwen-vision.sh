#!/usr/bin/env bash
set -euo pipefail

IMAGE="${QWEN_VISION_IMAGE:-ghcr.io/imanmostafavi/dspark-qwen-vision:0.1.0}"

docker build \
  --platform linux/arm64 \
  --file Dockerfile.qwen-vision \
  --tag "${IMAGE}" \
  .

if [[ "${PUSH_QWEN_VISION_IMAGE:-0}" == "1" ]]; then
  docker push "${IMAGE}"
fi
