import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Decodes a JSON object.
Map<String, Object?> decodeMap(String body) {
  return Map<String, Object?>.from(jsonDecode(body) as Map);
}

/// Casts [value] to a JSON object.
Map<String, Object?> asObjMap(Object? value) {
  return Map<String, Object?>.from(value! as Map);
}

/// Casts [value] to a JSON array.
List<Object?> asObjList(Object? value) {
  return List<Object?>.from(value! as List);
}

final IOSink _logSink = _openLog();

IOSink _openLog() {
  Directory('logs').createSync(recursive: true);
  return File('logs/test.log').openWrite(mode: FileMode.append);
}

/// Writes [message] to `logs/test.log` without printing.
void testLog(String message) {
  _logSink.writeln('${DateTime.now().toIso8601String()} $message');
}

/// JSON mock that records requests.
MockClient jsonClient(
  FutureOr<http.Response> Function(http.Request request) handler,
) {
  return MockClient((request) async {
    testLog('${request.method} ${request.url}');
    return handler(request);
  });
}

/// Streaming mock.
MockClient streamClient(
  FutureOr<http.StreamedResponse> Function(http.BaseRequest request) handler,
) {
  return MockClient.streaming((request, body) async {
    testLog('STREAM ${request.method} ${request.url}');
    return handler(request);
  });
}

/// JSON 200 response.
http.Response jsonOk(Map<String, Object?> body, {int status = 200}) {
  return http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
}

/// JSON error response.
http.Response jsonError(
  int status, {
  String message = 'error',
  String? retryAfter,
  Map<String, String>? headers,
}) {
  return http.Response(
    jsonEncode({
      'error': {
        'message': message,
        'type': 'api_error',
        'code': '$status',
      },
    }),
    status,
    headers: {
      'content-type': 'application/json',
      if (retryAfter != null) 'retry-after': retryAfter,
      ...?headers,
    },
  );
}

/// SSE streamed response from [payloads].
http.StreamedResponse sseResponse(List<String> payloads) {
  final chunks = [
    for (final payload in payloads) 'data: $payload\n\n',
    'data: [DONE]\n\n',
  ];
  return http.StreamedResponse(
    Stream<List<int>>.fromIterable(
      chunks.map(utf8.encode),
    ),
    200,
    headers: {'content-type': 'text/event-stream'},
  );
}
