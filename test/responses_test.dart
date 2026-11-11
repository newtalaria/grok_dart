import 'dart:convert';

import 'package:grok_dart/grok_dart.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('Responses API', () {
    test('creates a response and concatenates output text', () async {
      final grok = Grok(
        apiKey: 'test-key',
        httpClient: jsonClient((request) {
          expect(request.url.path, '/v1/responses');
          final body = decodeMap(request.body);
          expect(body['model'], 'grok-4.7');
          expect(body['input'], '2+2?');
          expect(
            asObjMap(asObjMap(body['text'])['format'])['type'],
            'json_schema',
          );
          return jsonOk({
            'id': 'resp_1',
            'object': 'response',
            'created_at': 10,
            'model': 'grok-4.7',
            'status': 'completed',
            'output': [
              {
                'id': 'msg_1',
                'type': 'message',
                'role': 'assistant',
                'status': 'completed',
                'content': [
                  {
                    'type': 'output_text',
                    'text': '4',
                    'annotations': <Object?>[],
                  },
                ],
              },
            ],
            'usage': {
              'input_tokens': 8,
              'output_tokens': 1,
              'total_tokens': 20,
              'input_tokens_details': {'cached_tokens': 1},
              'output_tokens_details': {'reasoning_tokens': 11},
            },
          });
        }),
        retryPolicy: RetryPolicy.disabled,
        onLog: testLog,
      );

      final response = await grok.responses.create(
        model: 'grok-4.7',
        input: ResponseInput.text('2+2?'),
        textFormat: ResponseFormat.jsonSchema(
          name: 'answer',
          schema: {
            'type': 'object',
            'properties': {
              'value': {'type': 'number'},
            },
          },
        ),
      );

      expect(response.outputText, '4');
      expect(response.status, ResponseStatus.completed);
      expect(response.usage?.inputTokens, 8);
      expect(response.usage?.outputTokensDetails?.reasoningTokens, 11);
    });

    test('encodes image input, tools, and function_call_output', () async {
      late Map<String, Object?> sent;
      final grok = Grok(
        apiKey: 'test-key',
        httpClient: jsonClient((request) {
          sent = decodeMap(request.body);
          return jsonOk({
            'id': 'resp_2',
            'created_at': 1,
            'model': 'grok-4.7',
            'status': 'completed',
            'output': [
              {
                'type': 'function_call',
                'call_id': 'call_9',
                'name': 'get_temperature',
                'arguments': '{"location":"SF"}',
              },
            ],
          });
        }),
        retryPolicy: RetryPolicy.disabled,
        onLog: testLog,
      );

      final response = await grok.responses.create(
        model: 'grok-4.7',
        input: ResponseInput.items([
          ResponseInputItem.user(
            'What is in this image, and the temperature?',
            images: [
              ContentPart.imageUrl('https://example.com/p.png'),
            ],
          ),
        ]),
        tools: [
          const WebSearchTool(),
          const FunctionTool(
            name: 'get_temperature',
            parameters: {
              'type': 'object',
              'properties': {
                'location': {'type': 'string'},
              },
              'required': ['location'],
            },
          ),
        ],
        previousResponseId: 'resp_prev',
      );

      expect(response.functionCalls.single.name, 'get_temperature');
      expect(sent['previous_response_id'], 'resp_prev');
      final toolsJson = asObjList(sent['tools']);
      expect(asObjMap(toolsJson[0])['type'], 'web_search');
      expect(asObjMap(toolsJson[1])['name'], 'get_temperature');
      final input = asObjList(sent['input']);
      final content = asObjList(asObjMap(input.first)['content']);
      expect(asObjMap(content.first)['type'], 'input_image');

      await grok.responses.create(
        model: 'grok-4.7',
        previousResponseId: response.id,
        input: ResponseInput.items([
          ResponseInputItem.functionCallOutput(
            callId: response.functionCalls.single.callId,
            output: '{"temperature":59}',
          ),
        ]),
      );
      final item = asObjMap(asObjList(sent['input']).first);
      expect(item['type'], 'function_call_output');
      expect(item['call_id'], 'call_9');
    });

    test('retrieves and deletes a response', () async {
      final grok = Grok(
        apiKey: 'test-key',
        httpClient: jsonClient((request) {
          if (request.method == 'GET') {
            expect(request.url.path, '/v1/responses/resp_1');
            return jsonOk({
              'id': 'resp_1',
              'created_at': 1,
              'model': 'grok-4.7',
              'status': 'completed',
              'output': [
                {
                  'type': 'message',
                  'content': [
                    {'type': 'output_text', 'text': 'hi'},
                  ],
                },
              ],
            });
          }
          expect(request.method, 'DELETE');
          return jsonOk({
            'id': 'resp_1',
            'object': 'response',
            'deleted': true,
          });
        }),
        retryPolicy: RetryPolicy.disabled,
        onLog: testLog,
      );

      final fetched = await grok.responses.retrieve('resp_1');
      expect(fetched.outputText, 'hi');
      final deleted = await grok.responses.delete('resp_1');
      expect(deleted.deleted, isTrue);
    });

    test('streams response text deltas', () async {
      final grok = Grok(
        apiKey: 'test-key',
        httpClient: streamClient((request) {
          return sseResponse([
            jsonEncode({
              'type': 'response.output_text.delta',
              'delta': 'Hi',
            }),
            jsonEncode({
              'type': 'response.output_text.delta',
              'delta': '!',
            }),
          ]);
        }),
        retryPolicy: RetryPolicy.disabled,
        onLog: testLog,
      );

      final texts = <String>[];
      await for (final event in grok.responses.stream(
        model: 'grok-4.7',
        input: ResponseInput.text('Hi'),
      )) {
        switch (event) {
          case ResponseTextDeltaEvent(:final delta):
            texts.add(delta);
          case ResponseCompletedEvent():
          case ResponseUnknownEvent():
            break;
        }
      }
      expect(texts.join(), 'Hi!');
    });
  });
}
