# Optional Pi integration

Pi reads custom providers and models from `~/.pi/agent/models.json`. Add the
Qwen model alongside the existing DeepSeek entry:

```json
{
  "id": "qwen3.5-9b-vision",
  "name": "Qwen 3.5 9B Vision (2x DGX Spark)",
  "input": ["text", "image"],
  "reasoning": false,
  "contextWindow": 32768,
  "maxTokens": 8192,
  "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}
}
```

Use the Qwen model when the task contains an image. Keep the existing
DeepSeek configuration for text and tool-heavy sessions. Back up
`~/.pi/agent/models.json` before merging this provider.
