@TestOn('vm')
library;

import 'dart:io';

import 'package:grok_dart/grok_dart.dart';
import 'package:test/test.dart';

void main() {
  final apiKey = Platform.environment['XAI_API_KEY'];
  final skipReason =
      (apiKey == null || apiKey.isEmpty) ? 'XAI_API_KEY is not set' : null;

  group(
    'live xAI API',
    () {
      test('lists models without printing the key', () async {
        final grok = Grok(
          apiKey: apiKey!,
          timeout: const Duration(seconds: 30),
          retryPolicy: const RetryPolicy(maxRetries: 1),
        );
        addTearDown(grok.close);
        final models = await grok.models.list();
        expect(models.data, isNotEmpty);
        expect(models.data.first.id, isNotEmpty);
      });
    },
    skip: skipReason,
  );
}
