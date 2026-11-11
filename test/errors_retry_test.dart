import 'package:grok_dart/grok_dart.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('errors', () {
    test('maps 401 to GrokAuthException', () async {
      final grok = Grok(
        apiKey: 'bad',
        httpClient: jsonClient(
          (_) => jsonError(401, message: 'Invalid token'),
        ),
        retryPolicy: RetryPolicy.disabled,
        onLog: testLog,
      );
      expect(
        grok.models.list,
        throwsA(
          isA<GrokAuthException>().having(
            (error) => error.message,
            'message',
            'Invalid token',
          ),
        ),
      );
    });

    test('maps 429 with Retry-After', () async {
      final grok = Grok(
        apiKey: 'key',
        httpClient: jsonClient(
          (_) => jsonError(429, message: 'Slow down', retryAfter: '7'),
        ),
        retryPolicy: RetryPolicy.disabled,
        onLog: testLog,
      );
      expect(
        grok.models.list,
        throwsA(
          isA<GrokRateLimitException>().having(
            (error) => error.retryAfter,
            'retryAfter',
            const Duration(seconds: 7),
          ),
        ),
      );
    });

    test('maps 500 to GrokServerException', () async {
      final grok = Grok(
        apiKey: 'key',
        httpClient: jsonClient((_) => jsonError(503, message: 'down')),
        retryPolicy: RetryPolicy.disabled,
        onLog: testLog,
      );
      expect(
        grok.models.list,
        throwsA(isA<GrokServerException>()),
      );
    });

    test('maps network failures to GrokNetworkException', () async {
      final grok = Grok(
        apiKey: 'key',
        httpClient: jsonClient(
          (_) => throw http.ClientException('connection reset'),
        ),
        retryPolicy: RetryPolicy.disabled,
        onLog: testLog,
      );
      expect(
        grok.models.list,
        throwsA(isA<GrokNetworkException>()),
      );
    });

    test('maps timeouts to GrokTimeoutException', () async {
      final grok = Grok(
        apiKey: 'key',
        timeout: const Duration(milliseconds: 20),
        httpClient: jsonClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return jsonOk({'object': 'list', 'data': <Object?>[]});
        }),
        retryPolicy: RetryPolicy.disabled,
        onLog: testLog,
      );
      expect(
        grok.models.list,
        throwsA(isA<GrokTimeoutException>()),
      );
    });

    test('maps 400 to GrokApiException', () async {
      final grok = Grok(
        apiKey: 'key',
        httpClient: jsonClient((_) => jsonError(400, message: 'bad schema')),
        retryPolicy: RetryPolicy.disabled,
        onLog: testLog,
      );
      expect(
        grok.models.list,
        throwsA(isA<GrokApiException>()),
      );
    });
  });

  group('retries', () {
    test('retries 429 then succeeds', () async {
      var attempts = 0;
      final delays = <Duration>[];
      final grok = Grok(
        apiKey: 'key',
        httpClient: jsonClient((_) {
          attempts += 1;
          if (attempts == 1) {
            return jsonError(429, message: 'wait', retryAfter: '2');
          }
          return jsonOk({
            'object': 'list',
            'data': [
              {
                'id': 'grok-4.7',
                'created': 1,
                'object': 'model',
                'owned_by': 'xai',
              },
            ],
          });
        }),
        sleeper: (duration) async => delays.add(duration),
        onLog: testLog,
      );

      final models = await grok.models.list();
      expect(attempts, 2);
      expect(delays, [const Duration(seconds: 2)]);
      expect(models.data.single.id, 'grok-4.7');
    });

    test('does not retry auth errors', () async {
      var attempts = 0;
      final grok = Grok(
        apiKey: 'key',
        httpClient: jsonClient((_) {
          attempts += 1;
          return jsonError(401, message: 'nope');
        }),
        retryPolicy: const RetryPolicy(maxRetries: 3),
        sleeper: (_) async {},
        onLog: testLog,
      );
      await expectLater(grok.models.list(), throwsA(isA<GrokAuthException>()));
      expect(attempts, 1);
    });

    test('RetryPolicy switches exhaustively', () {
      const policy = RetryPolicy();
      expect(
        policy.shouldRetry(const GrokRateLimitException(message: 'x')),
        isTrue,
      );
      expect(
        policy.shouldRetry(const GrokServerException(message: 'x')),
        isTrue,
      );
      expect(
        policy.shouldRetry(const GrokNetworkException(message: 'x')),
        isTrue,
      );
      expect(
        policy.shouldRetry(const GrokTimeoutException(message: 'x')),
        isTrue,
      );
      expect(
        policy.shouldRetry(const GrokAuthException(message: 'x')),
        isFalse,
      );
      expect(
        policy.shouldRetry(const GrokApiException(message: 'x')),
        isFalse,
      );
    });
  });
}
