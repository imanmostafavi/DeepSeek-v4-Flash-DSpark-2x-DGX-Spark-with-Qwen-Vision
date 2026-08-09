# Preliminary benchmarks

These measurements were taken on two NVIDIA DGX Sparks with the live
configuration documented by this recipe. They are reference numbers, not
guarantees: runtime image, model revision, cache state, fabric, prompt shape,
and vLLM version all affect results.

## Qwen Vision

Model: `qwen3.5-9b-vision` / `RedHatAI/Qwen3.5-9B-quantized.w4a16`.
Image: local 640×480 JPEG supplied as a data URI. Each case used three runs and
31 generated tokens.

| Concurrency | Median TTFT | Median request time | Median decode | Aggregate decode |
| ---: | ---: | ---: | ---: | ---: |
| 1 | 0.53 s | 3.12 s | 12.0 tok/s | 9.9 tok/s |
| 2 | 0.65 s | 3.19 s | 12.0 tok/s | 18.8 tok/s |

The reusable benchmark is `scripts/benchmark-qwen-vision.py`. It accepts a
local image so the result does not depend on the model server fetching a public
URL.

## DeepSeek with Qwen loaded

The Mia benchmark harness was run while the Qwen sidecar was loaded:

| Prompt target | Concurrency | Median TTFT | Median prefill | Median decode | Aggregate decode |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 256 | 1 | 19.05 s* | 14.7K tok/s | 54.9 tok/s | 43.1 tok/s |
| 256 | 2 | 9.62 s | 29.1K tok/s | 43.8 tok/s | 79.8 tok/s |
| 256 | 4 | 0.99 s | 303.1K tok/s | 37.8 tok/s | 74.8 tok/s |
| 2,048 | 1 | 1.57 s | 1,322.2K tok/s | 65.4 tok/s | 63.3 tok/s |
| 2,048 | 2 | 4.05 s | 511.6K tok/s | 42.7 tok/s | 65.8 tok/s |

\* The first 256-token case includes cold/warm-up behavior and should not be
used as a steady-state latency figure.

## Resource footprint and A/B status

At an idle observation after the runs, Qwen used approximately 7.0 GiB of GPU
memory and 2.5% host CPU per node. DeepSeek used approximately 94.5 GiB of GPU
memory. A no-Qwen control produced 64.4 tok/s decode on one 256-token,
concurrency-1 case, but the matched 2K control did not complete cleanly during
this run. Therefore this report does **not** claim a precise percentage
performance penalty from loading Qwen. The current evidence shows that the
sidecar fits in the available memory budget; a proper impact percentage needs a
repeatable warm-state A/B sweep under otherwise identical load.

Raw outputs:

- `results/qwen-vision-2026-08-08.json`
- `results/deepseek-with-qwen-sidecar-2026-08-08.json`
- `results/deepseek-without-qwen-sidecar-2026-08-08.json`
