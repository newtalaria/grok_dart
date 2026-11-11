import 'package:grok_dart/src/enums.dart';
import 'package:grok_dart/src/json.dart';

/// A multimodal content part in a chat message.
sealed class ContentPart {
  /// Creates a content part.
  const ContentPart();

  /// Parses a Chat Completions content part.
  factory ContentPart.fromJson(Map<String, Object?> json) {
    final type = readString(json, 'type');
    if (type == 'image_url') {
      return ImageContentPart.fromJson(json);
    }
    if (type == 'input_image') {
      return ImageContentPart.fromResponsesJson(json);
    }
    final text = readString(json, 'text') ?? '';
    return TextContentPart(text);
  }

  /// A text part.
  factory ContentPart.text(String text) = TextContentPart;

  /// An image URL or data-URL part.
  factory ContentPart.imageUrl(
    String url, {
    ImageDetail? detail,
  }) = ImageContentPart.url;

  /// JSON body sent to Chat Completions.
  Map<String, Object?> toJson();

  /// JSON body sent to the Responses API.
  Map<String, Object?> toResponsesJson();
}

/// Text content.
final class TextContentPart extends ContentPart {
  /// Creates a text part.
  const TextContentPart(this.text);

  /// Text.
  final String text;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'text',
      'text': text,
    };
  }

  @override
  Map<String, Object?> toResponsesJson() {
    return {
      'type': 'input_text',
      'text': text,
    };
  }
}

/// An image supplied by URL or base64 data URL.
final class ImageContentPart extends ContentPart {
  /// Creates an image part.
  const ImageContentPart({
    required this.url,
    this.detail,
  });

  /// Creates an image part from a URL or data URL.
  const ImageContentPart.url(
    this.url, {
    this.detail,
  });

  /// Parses a Chat Completions `image_url` part.
  factory ImageContentPart.fromJson(Map<String, Object?> json) {
    final image = readMap(json, 'image_url') ?? const {};
    return ImageContentPart(
      url: readString(image, 'url') ?? readString(json, 'image_url') ?? '',
      detail: ImageDetail.parse(readString(image, 'detail')),
    );
  }

  /// Parses a Responses API `input_image` part.
  factory ImageContentPart.fromResponsesJson(Map<String, Object?> json) {
    final url = readString(json, 'image_url') ?? '';
    return ImageContentPart(
      url: url,
      detail: ImageDetail.parse(readString(json, 'detail')),
    );
  }

  /// Image URL or `data:image/jpeg;base64,...` data URL.
  final String url;

  /// Optional detail level.
  final ImageDetail? detail;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'image_url',
      'image_url': omitNulls({
        'url': url,
        'detail': detail?.wireName,
      }),
    };
  }

  @override
  Map<String, Object?> toResponsesJson() {
    return omitNulls({
      'type': 'input_image',
      'image_url': url,
      'detail': detail?.wireName,
    });
  }
}

/// Structured output format for Chat Completions (`response_format`).
sealed class ResponseFormat {
  /// Creates a response format.
  const ResponseFormat();

  /// JSON matching [schema].
  factory ResponseFormat.jsonSchema({
    required String name,
    required Map<String, Object?> schema,
    String? description,
    bool? strict,
  }) = JsonSchemaResponseFormat;

  /// Free-form text (the default).
  static const ResponseFormat text = TextResponseFormat();

  /// Any well-formed JSON object.
  static const ResponseFormat jsonObject = JsonObjectResponseFormat();

  /// Chat Completions `response_format` body.
  Map<String, Object?> toJson();

  /// Responses API `text.format` body.
  Map<String, Object?> toResponsesFormat();
}

/// Free-form text.
final class TextResponseFormat extends ResponseFormat {
  /// Creates a text format.
  const TextResponseFormat();

  @override
  Map<String, Object?> toJson() => const {'type': 'text'};

  @override
  Map<String, Object?> toResponsesFormat() => const {'type': 'text'};
}

/// Unstructured JSON object.
final class JsonObjectResponseFormat extends ResponseFormat {
  /// Creates a JSON-object format.
  const JsonObjectResponseFormat();

  @override
  Map<String, Object?> toJson() => const {'type': 'json_object'};

  @override
  Map<String, Object?> toResponsesFormat() => const {'type': 'json_object'};
}

/// JSON constrained by a schema.
final class JsonSchemaResponseFormat extends ResponseFormat {
  /// Creates a JSON-schema format.
  const JsonSchemaResponseFormat({
    required this.name,
    required this.schema,
    this.description,
    this.strict,
  });

  /// Schema name.
  final String name;

  /// JSON Schema document.
  final Map<String, Object?> schema;

  /// Optional description.
  final String? description;

  /// Whether the model must match [schema] strictly.
  final bool? strict;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'json_schema',
      'json_schema': omitNulls({
        'name': name,
        'description': description,
        'schema': schema,
        'strict': strict,
      }),
    };
  }

  @override
  Map<String, Object?> toResponsesFormat() {
    return omitNulls({
      'type': 'json_schema',
      'name': name,
      'description': description,
      'schema': schema,
      'strict': strict,
    });
  }
}
