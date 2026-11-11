import 'dart:convert';

import 'package:grok_dart/grok_dart.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('Chat Completions', () {
    test('creates a completion and reports usage', () async {
      final grok = Grok(
        apiKey: 'test-key',
        httpClient: jsonClient((request) {
          expect(request.method, 'POST');
          expect(request.url.path, '/v1/chat/completions');
          expect(request.headers['authorization'], 'Bearer test-key');
          final body = decodeMap(request.body);
          expect(body['model'], 'grok-4.7');
          expect(body['stream'], isNull);
          return jsonOk({
            'id': 'chatcmpl-1',
            'object': 'chat.completion',
            'created': 1,
            'model': 'grok-4.7',
            'choices': [
              {
                'index': 0,
                'message': {
                  'role': 'assistant',
                  'content': 'Hello from Grok',
                  'refusal': null,
                },
                'finish_reason': 'stop',
              },
            ],
            'usage': {
              'prompt_tokens': 12,
              'completion_tokens': 4,
              'total_tokens': 16,
              'prompt_tokens_details': {
                'text_tokens': 12,
                'cached_tokens': 2,
                'image_tokens': 0,
                'audio_tokens': 0,
              },
              'completion_tokens_details': {
                'reasoning_tokens': 3,
              },
            },
          });
        }),
        retryPolicy: RetryPolicy.disabled,
        onLog: testLog,
      );

      final completion = await grok.chat.create(
        model: 'grok-4.7',
        messages: [
          ChatMessage.system('You are Grok.'),
          ChatMessage.user('Hello'),
        ],
      );

      expect(completion.text, 'Hello from Grok');
      expect(completion.choices.first.finishReason, FinishReason.stop);
      expect(completion.usage?.promptTokens, 12);
      expect(completion.usage?.completionTokens, 4);
      expect(completion.usage?.totalTokens, 16);
      expect(completion.usage?.promptTokensDetails?.cachedTokens, 2);
      expect(
        completion.usage?.completionTokensDetails?.reasoningTokens,
        3,
      );
    });

    test('encodes image input and JSON schema', () async {
      late Map<String, Object?> sent;
      final grok = Grok(
        apiKey: 'test-key',
        httpClient: jsonClient((request) {
          sent = decodeMap(request.body);
          return jsonOk({
            'id': 'x',
            'created': 0,
            'model': 'grok-4.7',
            'choices': [
              {
                'index': 0,
                'message': {'role': 'assistant', 'content': '{"ok":true}'},
                'finish_reason': 'stop',
              },
            ],
          });
        }),
        retryPolicy: RetryPolicy.disabled,
        onLog: testLog,
      );

      await grok.chat.create(
        model: 'grok-4.7',
        messages: [
          ChatMessage.user(
            'Describe this',
            images: [
              ContentPart.imageUrl(
                'https://example.com/a.png',
                detail: ImageDetail.high,
              ),
            ],
          ),
        ],
        responseFormat: ResponseFormat.jsonSchema(
          name: 'result',
          schema: {
            'type': 'object',
            'properties': {
              'ok': {'type': 'boolean'},
            },
            'required': ['ok'],
          },
          strict: true,
        ),
      );

      final messages = asObjList(sent['messages']);
      final content = asObjList(asObjMap(messages.first)['content']);
      final imagePart = asObjMap(content.first);
      expect(imagePart['type'], 'image_url');
      expect(asObjMap(imagePart['image_url'])['detail'], 'high');
      final format = asObjMap(sent['response_format']);
      expect(format['type'], 'json_schema');
      final schema = asObjMap(format['json_schema']);
      expect(schema['name'], 'result');
      expect(schema['strict'], isTrue);
    });

    test('parses tool calls and round-trips tool results', () async {
      late Map<String, Object?> sent;
      final grok = Grok(
        apiKey: 'test-key',
        httpClient: jsonClient((request) {
          sent = decodeMap(request.body);
          return jsonOk({
            'id': 'x',
            'created': 0,
            'model': 'grok-4.7',
            'choices': [
              {
                'index': 0,
                'message': {
                  'role': 'assistant',
                  'content': null,
                  'tool_calls': [
                    {
                      'id': 'call_1',
                      'type': 'function',
                      'function': {
                        'name': 'get_temperature',
                        'arguments': '{"location":"SF"}',
                      },
                    },
                  ],
                },
                'finish_reason': 'tool_calls',
              },
            ],
          });
        }),
        retryPolicy: RetryPolicy.disabled,
        onLog: testLog,
      );

      final completion = await grok.chat.create(
        model: 'grok-4.7',
        messages: [ChatMessage.user('Temp in SF?')],
        tools: [
          const FunctionTool(
            name: 'get_temperature',
            description: 'Get temperature',
            parameters: {
              'type': 'object',
              'properties': {
                'location': {'type': 'string'},
              },
              'required': ['location'],
            },
          ),
        ],
        toolChoice: ToolChoice.auto,
      );

      expect(completion.choices.first.finishReason, FinishReason.toolCalls);
      expect(completion.toolCalls.single.function.name, 'get_temperature');
      expect(sent['tool_choice'], 'auto');
      final tool = asObjMap(asObjList(sent['tools']).first);
      expect(tool['type'], 'function');
      expect(asObjMap(tool['function'])['name'], 'get_temperature');

      await grok.chat.create(
        model: 'grok-4.7',
        messages: [
          ChatMessage.user('Temp in SF?'),
          completion.choices.first.message,
          ChatMessage.tool(
            toolCallId: completion.toolCalls.single.id,
            content: '{"temperature":59}',
          ),
        ],
      );
      final roles = asObjList(sent['messages'])
          .map((item) => asObjMap(item)['role'])
          .toList();
      expect(roles, ['user', 'assistant', 'tool']);
    });

    test('streams SSE text deltas and usage', () async {
      final grok = Grok(
        apiKey: 'test-key',
        httpClient: streamClient((request) {
          expect(request.url.path, '/v1/chat/completions');
          return sseResponse([
            jsonEncode({
              'id': 'c',
              'object': 'chat.completion.chunk',
              'created': 1,
              'model': 'grok-4.7',
              'choices': [
                {
                  'index': 0,
                  'delta': {'role': 'assistant', 'content': 'Hel'},
                },
              ],
            }),
            jsonEncode({
              'id': 'c',
              'object': 'chat.completion.chunk',
              'created': 1,
              'model': 'grok-4.7',
              'choices': [
                {
                  'index': 0,
                  'delta': {'content': 'lo'},
                  'finish_reason': 'stop',
                },
              ],
              'usage': {
                'prompt_tokens': 5,
                'completion_tokens': 2,
                'total_tokens': 7,
              },
            }),
          ]);
        }),
        retryPolicy: RetryPolicy.disabled,
        onLog: testLog,
      );

      final texts = <String>[];
      CompletionUsage? usage;
      await for (final chunk in grok.chat.stream(
        model: 'grok-4.7',
        messages: [ChatMessage.user('Hi')],
      )) {
        if (chunk.text != null) {
          texts.add(chunk.text!);
        }
        usage = chunk.usage ?? usage;
      }
      expect(texts.join(), 'Hello');
      expect(usage?.totalTokens, 7);
    });
  });
}
