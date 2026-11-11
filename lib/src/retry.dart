import 'package:grok_dart/src/errors.dart';

/// Callback used to wait between retry attempts.
typedef Sleeper = Future<void> Function(Duration duration);

/// Exponential backoff policy for retrying failed requests.
final class RetryPolicy {
  /// Creates a retry policy.
  ///
  /// [maxRetries] is the number of retries after the first attempt, so
  /// `maxRetries: 2` allows 3 total tries.
  const RetryPolicy({
    this.maxRetries = 2,
    this.initialBackoff = const Duration(milliseconds: 250),
    this.maxBackoff = const Duration(seconds: 8),
    this.multiplier = 2.0,
  });

  /// Disables retries.
  static const RetryPolicy disabled = RetryPolicy(maxRetries: 0);

  /// How many times to retry after the initial attempt.
  final int maxRetries;

  /// Delay before the first retry, before exponential growth.
  final Duration initialBackoff;

  /// Upper bound on the computed backoff.
  final Duration maxBackoff;

  /// Exponential growth factor applied after each retry.
  final double multiplier;

  /// Whether [error] should be retried.
  bool shouldRetry(GrokException error) {
    return switch (error) {
      GrokRateLimitException() => true,
      GrokServerException() => true,
      GrokNetworkException() => true,
      GrokTimeoutException() => true,
      GrokAuthException() => false,
      GrokApiException() => false,
    };
  }

  /// Backoff delay for [attempt], honoring `Retry-After` on rate limits.
  ///
  /// [attempt] is zero-based (0 is the first retry).
  Duration delayFor(int attempt, GrokException error) {
    if (error is GrokRateLimitException) {
      final retryAfter = error.retryAfter;
      if (retryAfter != null && retryAfter > Duration.zero) {
        return retryAfter > maxBackoff ? maxBackoff : retryAfter;
      }
    }
    var millis = initialBackoff.inMilliseconds.toDouble();
    for (var i = 0; i < attempt; i++) {
      millis *= multiplier;
    }
    final computed = Duration(milliseconds: millis.round());
    if (computed > maxBackoff) {
      return maxBackoff;
    }
    if (computed < Duration.zero) {
      return Duration.zero;
    }
    return computed;
  }
}

/// Runs [action] with [policy] retries.
Future<T> withRetry<T>({
  required RetryPolicy policy,
  required Sleeper sleeper,
  required Future<T> Function() action,
  void Function(String message)? onLog,
}) async {
  var attempt = 0;
  while (true) {
    try {
      return await action();
    } on GrokException catch (error) {
      if (!policy.shouldRetry(error) || attempt >= policy.maxRetries) {
        rethrow;
      }
      final delay = policy.delayFor(attempt, error);
      onLog?.call(
        'Retrying after ${error.runtimeType} '
        '(attempt ${attempt + 1}/${policy.maxRetries}, '
        'delay ${delay.inMilliseconds}ms)',
      );
      attempt += 1;
      await sleeper(delay);
    }
  }
}
