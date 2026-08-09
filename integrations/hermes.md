# Optional Hermes Agent integration

Hermes supports custom OpenAI-compatible endpoints. Configure the Qwen sidecar
as a vision-capable model and keep DeepSeek as the default text/tool model.

The interactive path is:

```sh
hermes model
```

Choose a custom/self-hosted endpoint and use the Qwen base URL and served model
shown by `scripts/status-qwen-vision.sh`. If editing `~/.hermes/config.yaml`,
back it up first and merge the model entry rather than replacing the file.

Hermes configuration is client-version-sensitive. Run `hermes --help` and
consult its installed documentation before applying automated edits.
