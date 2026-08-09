# Generic OpenAI-compatible clients

The services expose OpenAI-compatible APIs. Use the head node's reachable
address, not the worker address:

| Capability | Base URL | Model |
| --- | --- | --- |
| DeepSeek text/tools | `http://HEAD_NODE:8888/v1` | `deepseek-v4-flash-0731` |
| Qwen vision | `http://HEAD_NODE:8890/v1` | `qwen3.5-9b-vision` |

For local, unauthenticated services, clients commonly accept any placeholder
API key such as `local`. Keep these endpoints on a trusted network or put them
behind authentication and a firewall before exposing them outside the LAN.

When an image is included, select `qwen3.5-9b-vision`. Keep DeepSeek as the
default model for text-heavy agent work unless the client has explicit
modality-based routing.
