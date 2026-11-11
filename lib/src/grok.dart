import 'package:grok_dart/src/chat.dart';
import 'package:grok_dart/src/config.dart';
import 'package:grok_dart/src/models.dart';
import 'package:grok_dart/src/responses.dart';
import 'package:grok_dart/src/retry.dart';
import 'package:grok_dart/src/transport.dart';
import 'package:http/http.dart' as http;

/// Idiomatic Dart client for the xAI Grok API.
///
/// Works on the Dart VM, Flutter, and web. The only runtime dependency is
/// `package:http`.
///
/// ```dart
/// final grok = Grok(apiKey: 'xai-...');
/// final completion = await grok.chat.create(
///   model: 'grok-4.7',
///   messages: [ChatMessage.user('Hello')],
/// );
/// print(completion.text);
/// grok.close();
/// ```
final class Grok {
  /// Creates a Grok client.
  ///
  /// [apiKey] is sent as `Authorization: Bearer`. [baseUrl] defaults to
  /// `https://api.x.ai/v1`. Pass [httpClient] to reuse a client or to inject
  /// a mock in tests; the client is closed by [close] only when this
  /// constructor created it.
  factory Grok({
    required String apiKey,
    Uri? baseUrl,
    Duration timeout = defaultGrokTimeout,
    RetryPolicy retryPolicy = const RetryPolicy(),
    http.Client? httpClient,
    Sleeper sleeper = Future<void>.delayed,
    GrokLogCallback? onLog,
  }) {
    final config = GrokConfig(
      apiKey: apiKey,
      baseUrl: baseUrl,
      timeout: timeout,
      retryPolicy: retryPolicy,
      httpClient: httpClient,
      sleeper: sleeper,
      onLog: onLog,
    );
    return Grok._(config, GrokTransport(config));
  }

  Grok._(this.config, GrokTransport transport)
      : chat = ChatResource(transport),
        responses = ResponsesResource(transport),
        models = ModelsResource(transport);

  /// Client configuration.
  final GrokConfig config;

  /// Chat Completions API.
  final ChatResource chat;

  /// Responses API.
  final ResponsesResource responses;

  /// Models list/retrieve API.
  final ModelsResource models;

  /// Closes the underlying [http.Client] when this instance owns it.
  void close() {
    if (config.ownsHttpClient) {
      config.httpClient.close();
    }
  }
}
