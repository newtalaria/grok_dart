import 'dart:convert';

import 'package:grok_dart/src/json.dart';

/// An error thrown by the Grok client.
///
/// Switch on the subtype without a `default` clause so newly added error
/// kinds fail analysis until they are handled.
sealed class GrokException implements Exception {
  /// Creates a Grok exception.
  const GrokException({
    required this.message,
    this.statusCode,
    this.body,
    this.code,
    this.type,
    this.cause,
  });

  /// Human-readable error message.
  final String message;

  /// HTTP status code when the error came from the API.
  final int? statusCode;

  /// Raw response body, if any.
  final String? body;

  /// API error code, when provided.
  final String? code;

  /// API error type, when provided (for example `authentication_error`).
  final String? type;

  /// Underlying exception, if this error wraps a transport failure.
  final Object? cause;

  /// Type name for [toString] without using `runtimeType`.
  String get _kind {
    return switch (this) {
      GrokAuthException() => 'GrokAuthException',
      GrokRateLimitException() => 'GrokRateLimitException',
      GrokServerException() => 'GrokServerException',
      GrokNetworkException() => 'GrokNetworkException',
      GrokTimeoutException() => 'GrokTimeoutException',
      GrokApiException() => 'GrokApiException',
    };
  }

  @override
  String toString() {
    final status = statusCode == null ? '' : ' ($statusCode)';
    return '$_kind$status: $message';
  }
}

/// Invalid or missing API credentials (HTTP 401 or 403).
final class GrokAuthException extends GrokException {
  /// Creates an authentication/authorization error.
  const GrokAuthException({
    required super.message,
    super.statusCode,
    super.body,
    super.code,
    super.type,
    super.cause,
  });
}

/// The client exceeded an xAI rate limit (HTTP 429).
final class GrokRateLimitException extends GrokException {
  /// Creates a rate-limit error.
  const GrokRateLimitException({
    required super.message,
    super.statusCode,
    super.body,
    super.code,
    super.type,
    super.cause,
    this.retryAfter,
  });

  /// Delay requested by the `Retry-After` response header, if present.
  final Duration? retryAfter;
}

/// An xAI server-side failure (HTTP 5xx).
final class GrokServerException extends GrokException {
  /// Creates a server error.
  const GrokServerException({
    required super.message,
    super.statusCode,
    super.body,
    super.code,
    super.type,
    super.cause,
  });
}

/// A network-level failure (DNS, connection reset, TLS, and similar).
final class GrokNetworkException extends GrokException {
  /// Creates a network error.
  const GrokNetworkException({
    required super.message,
    super.statusCode,
    super.body,
    super.code,
    super.type,
    super.cause,
  });
}

/// The request exceeded the configured timeout.
final class GrokTimeoutException extends GrokException {
  /// Creates a timeout error.
  const GrokTimeoutException({
    required super.message,
    super.statusCode,
    super.body,
    super.code,
    super.type,
    super.cause,
  });
}

/// Any other API error (HTTP 400, 404, 422, and similar client failures).
final class GrokApiException extends GrokException {
  /// Creates a generic API error.
  const GrokApiException({
    required super.message,
    super.statusCode,
    super.body,
    super.code,
    super.type,
    super.cause,
  });
}

/// Parsed fields from an xAI error payload.
final class ApiErrorFields {
  /// Creates parsed error fields.
  const ApiErrorFields({
    required this.message,
    this.code,
    this.type,
  });

  /// Error message.
  final String message;

  /// Optional machine-readable code.
  final String? code;

  /// Optional error type string.
  final String? type;
}

/// Parses an xAI JSON error payload into a message, code, and type.
ApiErrorFields parseApiError(String body) {
  if (body.isEmpty) {
    return const ApiErrorFields(message: 'Request failed');
  }
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      return ApiErrorFields(message: body);
    }
    final map = asMap(decoded, 'error body');
    final error = map['error'];
    if (error is String && error.isNotEmpty) {
      return ApiErrorFields(
        message: error,
        code: readString(map, 'code'),
      );
    }
    if (error is Map) {
      final inner = asMap(error, 'error');
      return ApiErrorFields(
        message:
            readString(inner, 'message') ?? readString(inner, 'error') ?? body,
        code: readString(inner, 'code') ?? readString(map, 'code'),
        type: readString(inner, 'type'),
      );
    }
    final message = readString(map, 'message');
    if (message != null && message.isNotEmpty) {
      return ApiErrorFields(
        message: message,
        code: readString(map, 'code'),
        type: readString(map, 'type'),
      );
    }
  } on FormatException {
    // Use the raw body.
  }
  return ApiErrorFields(message: body);
}

/// Maps an HTTP status and body to a [GrokException] subtype.
GrokException exceptionForStatus({
  required int statusCode,
  required String body,
  Duration? retryAfter,
}) {
  final fields = parseApiError(body);
  final message = fields.message;
  if (statusCode == 401 || statusCode == 403) {
    return GrokAuthException(
      message: message,
      statusCode: statusCode,
      body: body,
      code: fields.code,
      type: fields.type,
    );
  }
  if (statusCode == 429) {
    return GrokRateLimitException(
      message: message,
      statusCode: statusCode,
      body: body,
      code: fields.code,
      type: fields.type,
      retryAfter: retryAfter,
    );
  }
  if (statusCode >= 500) {
    return GrokServerException(
      message: message,
      statusCode: statusCode,
      body: body,
      code: fields.code,
      type: fields.type,
    );
  }
  return GrokApiException(
    message: message,
    statusCode: statusCode,
    body: body,
    code: fields.code,
    type: fields.type,
  );
}

/// Parses a `Retry-After` header as a [Duration].
///
/// Supports integer seconds. HTTP-date values are ignored.
Duration? parseRetryAfter(String? header) {
  if (header == null) {
    return null;
  }
  final trimmed = header.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final seconds = int.tryParse(trimmed);
  if (seconds == null) {
    return null;
  }
  return Duration(seconds: seconds < 0 ? 0 : seconds);
}
