# Optional Pi integration

Pi uses `~/.pi/agent/models.json` for custom providers. This recipe exposes two
separate OpenAI-compatible endpoints:

- DeepSeek on `http://SPARK_HEAD_IP:8888/v1` for text, reasoning, and tools.
- Qwen Vision on `http://SPARK_HEAD_IP:8890/v1` for image analysis.

This is auxiliary routing, not a fused endpoint. Keep DeepSeek as Pi's active
model. The `pi-vision-tool` extension calls Qwen only when DeepSeek invokes its
`describe_image` tool, then returns Qwen's text description to DeepSeek.

## 1. Discover the served model IDs

Query both endpoints from the machine running Pi:

```bash
curl -fsS http://SPARK_HEAD_IP:8888/v1/models
curl -fsS http://SPARK_HEAD_IP:8890/v1/models
```

Use the exact `id` returned by each endpoint. The Qwen service in this recipe
normally returns `qwen3.5-9b-vision`. The DeepSeek ID can differ when
`SERVED_MODEL_NAME` has been customized; common values include
`deepseek-v4-flash-0731` and `deepseek-v4-flash-dspark`.

## 2. Add both providers to Pi

Back up an existing configuration, then merge the provider entries from
[`../pi-models.dspark.example.json`](../pi-models.dspark.example.json) into its
top-level `providers` object:

```bash
mkdir -p ~/.pi/agent
if [ -f ~/.pi/agent/models.json ]; then
  cp -p ~/.pi/agent/models.json ~/.pi/agent/models.json.backup
fi
```

Do not replace an existing `models.json`; doing so would remove the user's other
providers. Replace `SPARK_HEAD_IP` in both base URLs and replace either example
model ID if `/v1/models` returned a different value.

The Qwen provider must remain separate because it uses port `8890`. Its model
definition must include:

```json
{
  "id": "qwen3.5-9b-vision",
  "name": "Qwen 3.5 9B Vision (Dual Spark)",
  "reasoning": false,
  "input": ["text", "image"],
  "contextWindow": 32768,
  "maxTokens": 8192,
  "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}
}
```

The `input: ["text", "image"]` declaration is required for Pi to recognize the
model as vision-capable. `reasoning: false` matches the tested Qwen sidecar.

## 3. Install and configure the vision extension

Install the extension:

```bash
pi install npm:pi-vision-tool
```

Start Pi with DeepSeek as the active model. Inside that Pi session, configure
the persistent auxiliary model and enable the tool:

```text
/vision config provider Qwen Vision Local
/vision config model qwen3.5-9b-vision
/vision config reasoning-effort off
/vision on
/vision
```

These commands write `~/.pi/agent/vision-tool.json`. The equivalent settings
are:

```json
{
  "provider": "Qwen Vision Local",
  "model": "qwen3.5-9b-vision",
  "defaultReasoningEffort": "off",
  "enabled": true
}
```

Use the commands when possible so existing extension settings are preserved.
If the Qwen endpoint returned a different model ID, use it in both
`models.json` and `/vision config model`.

## 4. Verify auxiliary routing

In Pi, `/model` should still show DeepSeek as the active model. `/vision` should
show `Qwen Vision Local`, `qwen3.5-9b-vision`, reasoning effort `off`, and the
tool enabled. Ask Pi to describe an image and confirm that it invokes
`describe_image`.

Normal text and tool requests continue to use DeepSeek on port `8888`. Only
`describe_image` calls use Qwen on port `8890`; clients must not treat the two
services as one fused model or one automatically routing API endpoint.
