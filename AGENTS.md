# Agent instructions

This repository is an agent-ready deployment recipe for two NVIDIA DGX Sparks.
Read `docs/SETUP.md` before changing a host. Do not assume hostnames, interface
names, IP addresses, model-cache paths, or Docker image names are portable.
Treat `docs/LEGACY-UPSTREAM.md` as historical reference only; it is not part of
the current two-Spark setup path.

## Operating rules

1. Inspect both nodes first and confirm SSH, Docker, NVIDIA, `/dev/infiniband`,
   storage, and the selected RoCE interface.
2. Copy `.env.dspark.example` and `.env.qwen-vision.example` to local, ignored
   environment files. Never commit credentials, tunnel tokens, private keys,
   or machine-specific IP addresses.
3. Start the worker before the head for distributed vLLM services.
4. Validate `/v1/models`, text generation, tool calls, and an image prompt
   before configuring any client.
5. Treat Hermes and Pi as optional integrations. Do not overwrite existing
   client configuration; create a backup and merge only the named local models.
6. Prefer the generic OpenAI-compatible instructions when the user uses another
   agent or client.

## Intended model roles

- DeepSeek V4 Flash: primary long-context text, reasoning, and tool-use model.
- Qwen Vision: named multimodal sidecar for requests containing images.

The recipe does not silently route every client to Qwen. Configure a client to
select the vision model when an image is present.
