import 'package:grok_dart/grok_dart.dart';
import 'package:grok_dart/src/sse.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('models', () {
    test('lists and retrieves models', () async {
      final grok = Grok(
        apiKey: 'key',
        httpClient: jsonClient((request) {
          if (request.url.path.endsWith('/models/grok-4.7')) {
            return jsonOk({
              'id': 'grok-4.7',
              'created': 99,
              'object': 'model',
              'owned_by': 'xai',
              'prompt_text_token_price': 20000,
            });
          }
          return jsonOk({
            'object': 'list',
            'data': [
              {
                'id': 'grok-4.7',
                'created': 99,
                'object': 'model',
                'owned_by': 'xai',
                'aliases': ['grok-4.7-latest'],
                'context_length': 500000,
              },
            ],
          });
        }),
        retryPolicy: RetryPolicy.disabled,
        onLog: testLog,
      );

      final list = await grok.models.list();
      expect(list.data.single.id, 'grok-4.7');
      expect(list.data.single.aliases, ['grok-4.7-latest']);
      final model = await grok.models.retrieve('grok-4.7');
      expect(model.promptTextTokenPrice, 20000);
    });

    test('uses a custom base URL', () async {
      final grok = Grok(
        apiKey: 'key',
        baseUrl: Uri.parse('https://proxy.example/v1/'),
        httpClient: jsonClient((request) {
          expect(request.url.toString(), 'https://proxy.example/v1/models');
          return jsonOk({'object': 'list', 'data': <Object?>[]});
        }),
        retryPolicy: RetryPolicy.disabled,
        onLog: testLog,
      );
      final list = await grok.models.list();
      expect(list.data, isEmpty);
    });

    test('rejects an empty API key', () {
      expect(() => Grok(apiKey: ''), throwsArgumentError);
    });
  });

  group('SseParser', () {
    test('parses split chunks and [DONE]', () {
      final parser = SseParser();
      final events = [
        ...parser.add('data: {"a":'),
        ...parser.add('1}\n\n'),
        ...parser.add('data: [DONE]\n\n'),
      ];
      expect(events, hasLength(2));
      expect(events.first.data, '{"a":1}');
      expect(events.last.isDone, isTrue);
    });

    test('parses named events and ignores comments', () {
      final parser = SseParser();
      final events = parser
          .add(
            ': keep-alive\n'
            'event: response.output_text.delta\n'
            'data: {"delta":"x"}\n'
            '\n',
          )
          .toList();
      expect(events, hasLength(1));
      expect(events.single.event, 'response.output_text.delta');
      expect(events.single.data, '{"delta":"x"}');
    });
  });

  group('enums', () {
    test('switches are exhaustive', () {
      String roleName(ChatRole role) {
        return switch (role) {
          ChatRole.system => 'system',
          ChatRole.user => 'user',
          ChatRole.assistant => 'assistant',
          ChatRole.tool => 'tool',
          ChatRole.developer => 'developer',
          ChatRole.unknown => 'unknown',
        };
      }

      expect(roleName(ChatRole.user), 'user');
      expect(FinishReason.parse('tool_calls'), FinishReason.toolCalls);
      expect(FinishReason.parse('nope'), FinishReason.unknown);
      expect(ServiceTier.parse('fast')?.wireName, 'fast');
    });
  });
}
