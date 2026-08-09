#!/usr/bin/env python3
"""Benchmark an OpenAI-compatible Qwen vision endpoint with a local image."""

import argparse
import asyncio
import base64
import json
import mimetypes
import statistics
import time
import urllib.request
from pathlib import Path


def stream_one(base_url, model, image_data, mime_type, prompt):
    data_uri = f"data:{mime_type};base64,{image_data}"
    body = {
        "model": model,
        "messages": [{"role": "user", "content": [
            {"type": "text", "text": prompt},
            {"type": "image_url", "image_url": {"url": data_uri}},
        ]}],
        "stream": True,
        "stream_options": {"include_usage": True},
        "temperature": 0,
        "max_tokens": 128,
    }
    request = urllib.request.Request(
        f"{base_url.rstrip('/')}/chat/completions",
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json", "Authorization": "Bearer local"},
    )
    started = time.perf_counter()
    first = None
    usage = None
    with urllib.request.urlopen(request, timeout=300) as response:
        for raw in response:
            line = raw.decode().strip()
            if not line.startswith("data: ") or line == "data: [DONE]":
                continue
            event = json.loads(line[6:])
            choices = event.get("choices") or []
            delta = choices[0].get("delta", {}) if choices else {}
            if first is None and (delta.get("content") or delta.get("reasoning") or delta.get("reasoning_content")):
                first = time.perf_counter()
            if event.get("usage"):
                usage = event["usage"]
    finished = time.perf_counter()
    output_tokens = (usage or {}).get("completion_tokens", 0)
    return {
        "ttft_s": (first or finished) - started,
        "elapsed_s": finished - started,
        "output_tokens": output_tokens,
        "output_tok_s": output_tokens / max(0.001, finished - (first or finished)),
    }


async def run_case(args, image_data, mime_type, concurrency):
    results = await asyncio.gather(*[
        asyncio.to_thread(stream_one, args.base_url, args.model, image_data, mime_type, args.prompt)
        for _ in range(concurrency)
    ])
    return {
        "concurrency": concurrency,
        "requests": results,
        "median_ttft_s": statistics.median(item["ttft_s"] for item in results),
        "median_elapsed_s": statistics.median(item["elapsed_s"] for item in results),
        "median_output_tok_s": statistics.median(item["output_tok_s"] for item in results),
        "aggregate_output_tok_s": sum(item["output_tokens"] for item in results) / max(
            0.001, max(item["elapsed_s"] for item in results)
        ),
    }


async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", default="http://127.0.0.1:8890/v1")
    parser.add_argument("--model", default="qwen3.5-9b-vision")
    parser.add_argument("--image", required=True)
    parser.add_argument("--prompt", default="Describe this image in one concise sentence.")
    parser.add_argument("--runs", type=int, default=3)
    parser.add_argument("--concurrency", default="1,2")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    image_path = Path(args.image)
    image_data = base64.b64encode(image_path.read_bytes()).decode()
    mime_type = mimetypes.guess_type(image_path.name)[0] or "application/octet-stream"
    report = {"base_url": args.base_url, "model": args.model, "image": image_path.name, "cases": []}
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)

    for concurrency in [int(value) for value in args.concurrency.split(",")]:
        for run in range(args.runs):
            case = await run_case(args, image_data, mime_type, concurrency)
            case["run"] = run + 1
            report["cases"].append(case)
            output.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
            print(json.dumps(case, sort_keys=True), flush=True)


if __name__ == "__main__":
    asyncio.run(main())
