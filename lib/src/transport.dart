import 'dart:async';
import 'dart:convert';

import 'package:grok_dart/src/config.dart';
import 'package:grok_dart/src/errors.dart';
import 'package:grok_dart/src/json.dart';
import 'package:grok_dart/src/retry.dart';
import 'package:grok_dart/src/sse.dart';
import 'package:grok_dart/src/version.dart';
import 'package:http/http.dart' as http;

/// Low-level JSON and SSE transport for the xAI API.
final class GrokTransport {
  /// Creates a transport.
  GrokTransport(this.config);

  /// Client configuration.
  final GrokConfig config;

  /// Sends `GET [path]` and decodes a JSON object.
  Future<Map<String, Object?>> getJson(String path) {
    return _sendJson(method: 'GET', path: path);
  }

  /// Sends `POST [path]` with a JSON body and decodes a JSON object.
  Future<Map<String, Object?>> postJson(
    String path,
    Map<String, Object?> body,
  ) {
    return _sendJson(method: 'POST', path: path, body: body);
  }

  /// Sends `DELETE [path]` and decodes a JSON object.
  Future<Map<String, Object?>> deleteJson(String path) {
    return _sendJson(method: 'DELETE', path: path);
  }

  /// Sends `POST [path]` and parses the body as SSE.
  Stream<SseEvent> postSse(
    String path,
    Map<String, Object?> body,
  ) async* {
    final response = await withRetry(
      policy: config.retryPolicy,
      sleeper: config.sleeper,
      onLog: config.onLog,
      action: () => _send(
        method: 'POST',
        path: path,
        body: body,
        accept: 'text/event-stream',
      ),
    );
    final parser = SseParser();
    final stream =
        response.stream.timeout(config.timeout).transform(utf8.decoder);
    try {
      await for (final chunk in stream) {
        yield* Stream<SseEvent>.fromIterable(parser.add(chunk));
      }
      final trailing = parser.flush();
      if (trailing != null) {
        yield trailing;
      }
    } on TimeoutException catch (error) {
      throw GrokTimeoutException(
        message: 'Timed out after ${config.timeout} while streaming $path',
        cause: error,
      );
    }
  }

  Future<Map<String, Object?>> _sendJson({
    required String method,
    required String path,
    Map<String, Object?>? body,
  }) {
    return withRetry(
      policy: config.retryPolicy,
      sleeper: config.sleeper,
      onLog: config.onLog,
      action: () async {
        final response = await _send(
          method: method,
          path: path,
          body: body,
        );
        final text = await _readBody(response);
        return asMap(jsonDecode(text), 'response');
      },
    );
  }

  Future<http.StreamedResponse> _send({
    required String method,
    required String path,
    Map<String, Object?>? body,
    String accept = 'application/json',
  }) async {
    final url = _url(path);
    final request = http.Request(method, url)
      ..headers.addAll({
        'Authorization': 'Bearer ${config.apiKey}',
        'Accept': accept,
        'User-Agent': 'grok_dart/$grokDartVersion',
      });
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    config.onLog?.call('$method $url');
    late final http.StreamedResponse response;
    try {
      response = await config.httpClient.send(request).timeout(
        config.timeout,
        onTimeout: () {
          throw GrokTimeoutException(
            message:
                'Timed out after ${config.timeout} waiting for $method $path',
          );
        },
      );
    } on GrokException {
      rethrow;
    } on TimeoutException catch (error) {
      throw GrokTimeoutException(
        message: 'Timed out after ${config.timeout} waiting for $method $path',
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw GrokNetworkException(
        message: error.message,
        cause: error,
      );
    }
    if (response.statusCode >= 400) {
      final text = await _readBody(response);
      throw exceptionForStatus(
        statusCode: response.statusCode,
        body: text,
        retryAfter: parseRetryAfter(
          response.headers['retry-after'] ?? response.headers['Retry-After'],
        ),
      );
    }
    return response;
  }

  Future<String> _readBody(http.StreamedResponse response) async {
    try {
      return await response.stream.bytesToString().timeout(config.timeout);
    } on TimeoutException catch (error) {
      throw GrokTimeoutException(
        message: 'Timed out after ${config.timeout} reading response body',
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw GrokNetworkException(
        message: error.message,
        cause: error,
      );
    }
  }

  Uri _url(String path) {
    final root = config.baseUrl.toString();
    final suffix = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$root$suffix');
  }
}
