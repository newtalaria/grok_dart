import 'package:grok_dart/src/json.dart';
import 'package:grok_dart/src/transport.dart';

/// Models API (`GET /v1/models`).
final class ModelsResource {
  /// Creates a models resource.
  ModelsResource(this._transport);

  final GrokTransport _transport;

  /// Lists models available to the authenticating API key.
  Future<ModelList> list() async {
    final json = await _transport.getJson('/models');
    return ModelList.fromJson(json);
  }

  /// Retrieves a single model by id.
  Future<GrokModel> retrieve(String modelId) async {
    final encoded = Uri.encodeComponent(modelId);
    final json = await _transport.getJson('/models/$encoded');
    return GrokModel.fromJson(json);
  }
}

/// A list of models.
final class ModelList {
  /// Creates a model list.
  const ModelList({
    required this.data,
    this.object = 'list',
  });

  /// Parses a model list.
  factory ModelList.fromJson(Map<String, Object?> json) {
    return ModelList(
      object: readString(json, 'object') ?? 'list',
      data: [
        for (final item in readList(json, 'data') ?? const [])
          GrokModel.fromJson(asMap(item, 'model')),
      ],
    );
  }

  /// Object type, always `list`.
  final String object;

  /// Models.
  final List<GrokModel> data;
}

/// A model available to the API key.
final class GrokModel {
  /// Creates a model.
  const GrokModel({
    required this.id,
    required this.created,
    required this.ownedBy,
    this.object = 'model',
    this.aliases = const [],
    this.contextLength,
    this.promptTextTokenPrice,
    this.cachedPromptTextTokenPrice,
    this.promptImageTokenPrice,
    this.completionTextTokenPrice,
    this.promptTextTokenPriceLongContext,
    this.completionTextTokenPriceLongContext,
    this.longContextThreshold,
    this.imagePrice,
  });

  /// Parses a model.
  factory GrokModel.fromJson(Map<String, Object?> json) {
    return GrokModel(
      id: readString(json, 'id') ?? '',
      object: readString(json, 'object') ?? 'model',
      created: readInt(json, 'created') ?? 0,
      ownedBy: readString(json, 'owned_by') ?? '',
      aliases:
          readList(json, 'aliases')?.whereType<String>().toList() ?? const [],
      contextLength: readInt(json, 'context_length'),
      promptTextTokenPrice: readInt(json, 'prompt_text_token_price'),
      cachedPromptTextTokenPrice: readInt(
        json,
        'cached_prompt_text_token_price',
      ),
      promptImageTokenPrice: readInt(json, 'prompt_image_token_price'),
      completionTextTokenPrice: readInt(json, 'completion_text_token_price'),
      promptTextTokenPriceLongContext: readInt(
        json,
        'prompt_text_token_price_long_context',
      ),
      completionTextTokenPriceLongContext: readInt(
        json,
        'completion_text_token_price_long_context',
      ),
      longContextThreshold: readInt(json, 'long_context_threshold'),
      imagePrice: readInt(json, 'image_price'),
    );
  }

  /// Model id, used as `model` in requests.
  final String id;

  /// Object type, always `model`.
  final String object;

  /// Creation time as a Unix timestamp.
  final int created;

  /// Owner, typically `xai`.
  final String ownedBy;

  /// Alternate ids accepted in the `model` field.
  final List<String> aliases;

  /// Maximum context length in tokens.
  final int? contextLength;

  /// Prompt text token price (USD cents per 100 million tokens).
  final int? promptTextTokenPrice;

  /// Cached prompt text token price.
  final int? cachedPromptTextTokenPrice;

  /// Prompt image token price.
  final int? promptImageTokenPrice;

  /// Completion text token price.
  final int? completionTextTokenPrice;

  /// Long-context prompt text token price.
  final int? promptTextTokenPriceLongContext;

  /// Long-context completion text token price.
  final int? completionTextTokenPriceLongContext;

  /// Token count at which long-context prices apply.
  final int? longContextThreshold;

  /// Per-image price for image generation models.
  final int? imagePrice;
}
