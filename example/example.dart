// This example is meant to be read; stdout is the output.
// ignore_for_file: avoid_print

import 'package:grok_dart/grok_dart.dart';

/// Demonstrates constructing requests. Swap in a real key and uncomment
/// the API calls to talk to xAI.
void main() {
  print('grok_dart $grokDartVersion');
  print('Default base URL: $defaultGrokBaseUrl');

  const apiKey = String.fromEnvironment('XAI_API_KEY');
  if (apiKey.isEmpty) {
    print(
      'Set XAI_API_KEY to run live calls. This example only shows request '
      'shapes so it stays safe to run in CI.',
    );
  }

  final user = ChatMessage.user(
    'What is in this image?',
    images: [
      ContentPart.imageUrl(
        'https://science.nasa.gov/wp-content/uploads/2023/09/web-first-images-release.png',
        detail: ImageDetail.high,
      ),
    ],
  );
  print('User message role: ${user.role.wireName}');

  const tool = FunctionTool(
    name: 'get_temperature',
    description: 'Get current temperature for a location',
    parameters: {
      'type': 'object',
      'properties': {
        'location': {'type': 'string', 'description': 'City name'},
      },
      'required': ['location'],
    },
  );
  print('Tool JSON type: ${tool.toJson()['type']}');

  final format = ResponseFormat.jsonSchema(
    name: 'answer',
    strict: true,
    schema: {
      'type': 'object',
      'properties': {
        'text': {'type': 'string'},
      },
      'required': ['text'],
      'additionalProperties': false,
    },
  );
  print('Structured output: ${format.toJson()['type']}');
}
