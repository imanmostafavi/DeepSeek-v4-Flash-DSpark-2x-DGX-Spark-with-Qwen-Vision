# Setup — two DGX Sparks with Qwen Vision

This is the canonical setup path for a working two-node Mia-style DeepSeek
deployment. It adds the optional `RedHatAI/Qwen3.5-9B-quantized.w4a16` vision
sidecar. Hermes and Pi are optional clients and are not required.

The old upstream four-Spark notes are preserved in
[`LEGACY-UPSTREAM.md`](LEGACY-UPSTREAM.md) and should not be used for this
deployment.

## Requirements

- Two networked NVIDIA DGX Sparks (GB10 / SM121), one head and one worker.
- Docker with the NVIDIA runtime on both nodes.
- Passwordless SSH from head to worker, plus `rsync`.
- A working DeepSeek DSpark deployment, or the compatible Mia recipe checked
  out on both nodes.
- A RoCE interface/HCA that works for tensor-parallel vLLM traffic.
- Enough disk space for the Qwen runtime image and model cache.

The scripts do not assume that the nodes are named `spark1` and `spark2`.
They use the host and interface values supplied in `.env.qwen-vision`.

## 1. Discover the node and fabric values

Run these on both nodes and use the matching head/worker values in the env
file:

```bash
hostname
ip -br address
ibdev2netdev || true
docker info
nvidia-smi
```

Confirm head-to-worker access before starting:

```bash
ssh <WORKER_HOST> hostname
ssh <WORKER_HOST> docker info
```

## 2. Configure the Qwen sidecar

On the head node:

```bash
cp .env.qwen-vision.example .env.qwen-vision
```

Edit these values for the cluster:

```env
QWEN_WORKER_HOST=<worker SSH host>
QWEN_WORKER_DIR=<worker checkout path>
MASTER_ADDR=<head RoCE IP>
NCCL_IB_HCA=<head HCA>
NCCL_SOCKET_IFNAME=<head RoCE interface>
HF_CACHE=<head Hugging Face cache>
QWEN_WORKER_HF_CACHE=<worker Hugging Face cache>
```

Keep the pinned image and model revision unless you are intentionally testing
another runtime or checkpoint.

## 3. Download and sync the model cache

The script downloads the pinned Qwen revision once on the head and synchronizes
the cache to the worker:

```bash
./prepare-qwen-vision-cache.sh
```

No model weights are stored in this repository. Set `HF_TOKEN` only when the
selected Hugging Face model requires authentication.

## 4. Start worker-first and verify

```bash
./start-qwen-vision.sh
./scripts/status-qwen-vision.sh
```

The launcher starts the worker first, starts the head, waits for `/v1/models`,
and synchronizes the compose/env files. Run the vision smoke test after the
endpoint is ready:

```bash
./scripts/smoke-qwen-vision.sh
```

## Resource guidance

The tested Qwen sidecar uses about 7 GiB of GPU memory per Spark alongside
DeepSeek. The configuration is suitable for moderate mixed use, but host RAM
and swap—not just GPU memory—limit long-context/high-concurrency workloads.
Start with the example limits (`QWEN_VISION_MAX_NUM_SEQS=5` and DeepSeek's
conservative profile), monitor memory, and lower concurrency if swap grows.

## Optional clients

- [Generic OpenAI-compatible clients](../integrations/generic-openai-compatible.md)
- [Hermes Agent](../integrations/hermes.md)
- [Pi Coding Agent](../integrations/pi.md)

## Troubleshooting

- Start the worker before the head; NCCL initialization is sensitive to order.
- Verify that head and worker use the same image digest and model revision.
- If the head is healthy but the worker is not, inspect
  `docker logs qwen3.5-vision` on both nodes.
- If available RAM is low or swap is active before startup, resolve the host
  pressure before increasing concurrency.
