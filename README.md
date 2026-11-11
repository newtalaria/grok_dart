# grok_dart

Idiomatic Dart client for the [xAI](https://x.ai) Grok API, by
[Talaria](https://www.newtalaria.com).

Works on the Dart VM, Flutter, and web. The only runtime dependency is
[`package:http`](https://pub.dev/packages/http).

> Unofficial. Not affiliated with or endorsed by xAI.

## Install

```yaml
dependencies:
  grok_dart: ^0.1.0
```

```sh
dart pub add grok_dart
```

Create an API key at [console.x.ai](https://console.x.ai) and pass it to
`Grok`. Never commit keys; this package never prints them.

## Quick start

```dart
import 'package:grok_dart/grok_dart.dart';

void main() async {
  final grok = Grok(apiKey: 'xai-...');
  final completion = await grok.chat.create(
    model: 'grok-4.7',
    messages: [
      ChatMessage.system('You are Grok, built by xAI.'),
      ChatMessage.user('Explain prompt caching in one sentence.'),
    ],
  );
  print(completion.text);
  print(completion.usage?.totalTokens);
  grok.close();
}
```

Default base URL: `https://api.x.ai/v1` (from the [xAI docs](https://docs.x.ai)).

## Chat Completions

Sync:

```dart
final completion = await grok.chat.create(
  model: 'grok-4.7',
  messages: [ChatMessage.user('Hello')],
);
```

Streaming SSE:

```dart
await for (final chunk in grok.chat.stream(
  model: 'grok-4.7',
  messages: [ChatMessage.user('Count to three.')],
)) {
  stdout.write(chunk.text ?? '');
}
```

`stream()` requests `stream_options.include_usage` so the last chunk can carry
token usage.

## Responses API

xAI's current preferred text API. Responses can be stored for 30 days and
continued with `previousResponseId`.

```dart
final response = await grok.responses.create(
  model: 'grok-4.7',
  input: ResponseInput.text('What is 101*3?'),
);
print(response.outputText);
print(response.id);

final followUp = await grok.responses.create(
  model: 'grok-4.7',
  previousResponseId: response.id,
  input: ResponseInput.text('Multiply that by 10.'),
);
```

Retrieve or delete a stored response with `grok.responses.retrieve(id)` and
`grok.responses.delete(id)`.

## Tool / function calling

Chat Completions (OpenAI-compatible nested `function` object):

```dart
final tools = [
  FunctionTool(
    name: 'get_temperature',
    description: 'Get current temperature for a location',
    parameters: {
      'type': 'object',
      'properties': {
        'location': {'type': 'string'},
      },
      'required': ['location'],
    },
  ),
];

final first = await grok.chat.create(
  model: 'grok-4.7',
  messages: [ChatMessage.user('Temperature in SF?')],
  tools: tools,
);

for (final call in first.toolCalls) {
  // Execute locally, then:
  final second = await grok.chat.create(
    model: 'grok-4.7',
    messages: [
      ChatMessage.user('Temperature in SF?'),
      first.choices.first.message,
      ChatMessage.tool(toolCallId: call.id, content: '{"temperature":59}'),
    ],
    tools: tools,
  );
}
```

Responses API (top-level `name` / `function_call_output`):

```dart
final response = await grok.responses.create(
  model: 'grok-4.7',
  input: ResponseInput.text('Temperature in SF?'),
  tools: tools,
  toolChoice: ToolChoice.auto,
);

for (final call in response.functionCalls) {
  await grok.responses.create(
    model: 'grok-4.7',
    previousResponseId: response.id,
    tools: tools,
    input: ResponseInput.items([
      ResponseInputItem.functionCallOutput(
        callId: call.callId,
        output: '{"temperature":59}',
      ),
    ]),
  );
}
```

`ToolChoice.auto`, `.required`, `.none`, or `ToolChoice.function('name')`.

## Structured outputs

```dart
final format = ResponseFormat.jsonSchema(
  name: 'movie',
  strict: true,
  schema: {
    'type': 'object',
    'properties': {
      'title': {'type': 'string'},
      'year': {'type': 'integer'},
    },
    'required': ['title', 'year'],
    'additionalProperties': false,
  },
);

final completion = await grok.chat.create(
  model: 'grok-4.7',
  messages: [ChatMessage.user('Dune')],
  responseFormat: format,
);

final response = await grok.responses.create(
  model: 'grok-4.7',
  input: ResponseInput.text('Dune'),
  textFormat: format,
);
```

`ResponseFormat.jsonObject` and `ResponseFormat.text` are also available.

## Image input

Chat Completions:

```dart
ChatMessage.user(
  'What is in this image?',
  images: [
    ContentPart.imageUrl(
      'https://example.com/photo.png',
      detail: ImageDetail.high,
    ),
  ],
);
```

Responses API uses `input_image` parts automatically:

```dart
ResponseInputItem.user(
  'What is in this image?',
  images: [ContentPart.imageUrl('data:image/jpeg;base64,...')],
);
```

Supported types: JPEG and PNG, up to 20MiB (per xAI docs).

## Models and usage

```dart
final models = await grok.models.list();
final grok47 = await grok.models.retrieve('grok-4.7');

print(completion.usage?.totalTokens);
print(completion.usage?.promptTokensDetails?.cachedTokens);
print(response.usage?.outputTokensDetails?.reasoningTokens);
```

## Errors, retries, timeouts

All failures are a sealed `GrokException`. Switch without `default`:

```dart
try {
  await grok.chat.create(model: 'grok-4.7', messages: messages);
} on GrokException catch (error) {
  switch (error) {
    case GrokAuthException():
      // invalid or missing API key (401/403)
    case GrokRateLimitException(:final retryAfter):
      // 429; retryAfter is parsed from Retry-After when present
    case GrokServerException():
      // 5xx
    case GrokNetworkException():
      // connection / TLS / DNS
    case GrokTimeoutException():
      // exceeded Grok.timeout
    case GrokApiException():
      // other 4xx (400, 404, 422, …)
  }
}
```

Configurable retries with exponential backoff (429, 5xx, network, timeout).
Rate limits honor `Retry-After` when the header is integer seconds.

```dart
final grok = Grok(
  apiKey: apiKey,
  baseUrl: Uri.parse('https://api.x.ai/v1'),
  timeout: const Duration(minutes: 10),
  retryPolicy: const RetryPolicy(
    maxRetries: 2,
    initialBackoff: Duration(milliseconds: 250),
    maxBackoff: Duration(seconds: 8),
  ),
  httpClient: myClient, // optional; not closed by grok.close()
);
```

## Platform notes

Streaming uses `http.Client.send` and works on VM, Flutter, and web. For
reasoning models, raise `timeout` so the SSE connection is not cut short.

## Development

```sh
dart pub get
dart analyze --fatal-infos
dart test
dart pub publish --dry-run
```

Unit tests mock `package:http` and do not need a live key. Optional live tests
in `test/live/` run only when `XAI_API_KEY` is set; they never print the key.

## Licence

MIT. See the `LICENSE` file in this repository.
