import 'package:grok_dart/src/retry.dart';
import 'package:http/http.dart' as http;

/// Default xAI inference base URL.
const String defaultGrokBaseUrl = 'https://api.x.ai/v1';

/// Default request timeout. Reasoning models can think for a long time.
const Duration defaultGrokTimeout = Duration(minutes: 10);

/// Optional log sink used by the client. Never logs secrets.
typedef GrokLogCallback = void Function(String message);

/// Immutable client configuration.
final class GrokConfig {
  /// Creates client configuration.
  GrokConfig({
    required this.apiKey,
    Uri? baseUrl,
    this.timeout = defaultGrokTimeout,
    this.retryPolicy = const RetryPolicy(),
    http.Client? httpClient,
    this.sleeper = Future<void>.delayed,
    this.onLog,
  })  : baseUrl = _normalizeBaseUrl(baseUrl ?? Uri.parse(defaultGrokBaseUrl)),
        httpClient = httpClient ?? http.Client(),
        ownsHttpClient = httpClient == null {
    if (apiKey.isEmpty) {
      throw ArgumentError.value(apiKey, 'apiKey', 'must not be empty');
    }
  }

  /// Bearer token for `Authorization`.
  final String apiKey;

  /// API root, including `/v1`.
  final Uri baseUrl;

  /// Per-request timeout, covering headers and the full body.
  final Duration timeout;

  /// Retry / backoff policy.
  final RetryPolicy retryPolicy;

  /// HTTP client used for all requests.
  final http.Client httpClient;

  /// Whether [httpClient] was created by this config and should be closed.
  final bool ownsHttpClient;

  /// Delay function, injectable in tests.
  final Sleeper sleeper;

  /// Optional diagnostic log callback.
  final GrokLogCallback? onLog;

  static Uri _normalizeBaseUrl(Uri uri) {
    final path = uri.path.endsWith('/')
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    return uri.replace(path: path);
  }
}
