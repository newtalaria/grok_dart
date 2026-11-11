## 0.1.0

- First real client release (0.0.1 was a name reservation only).
- Chat Completions: sync create, SSE streaming, usage on the final chunk.
- Responses API: create, stream, retrieve, delete, previous_response_id.
- Tool/function calling for both APIs, plus web_search and x_search tools.
- Structured outputs via JSON Schema (`response_format` / `text.format`).
- Image input (URL or data URL) for chat messages and Responses items.
- Models list and retrieve (`GET /v1/models`).
- Token usage reporting, including cached and reasoning tokens.
- Sealed errors: auth, rate limit (`Retry-After`), server, network, timeout.
- Configurable retries with exponential backoff, timeouts, base URL, and a
  custom `http.Client`.
- Dart VM, Flutter, and web; runtime dependency is `http` only.

## 0.0.1

- Placeholder release to reserve the `grok_dart` name on pub.dev.
  The client API is not implemented yet.
