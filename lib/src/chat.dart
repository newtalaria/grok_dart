import 'dart:convert';

import 'package:grok_dart/src/content.dart';
import 'package:grok_dart/src/enums.dart';
import 'package:grok_dart/src/json.dart';
import 'package:grok_dart/src/messages.dart';
import 'package:grok_dart/src/tools.dart';
import 'package:grok_dart/src/transport.dart';
import 'package:grok_dart/src/usage.dart';

/// Chat Completions API (`POST /v1/chat/completions`).
final class ChatResource {
  /// Creates a chat resource.
  ChatResource(this._transport);

  final GrokTransport _transport;

  /// Creates a non-streaming chat completion.
  Future<ChatCompletion> create({
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxCompletionTokens,
    int? maxTokens,
    int? n,
    bool? parallelToolCalls,
    List<GrokTool>? tools,
    ToolChoice? toolChoice,
    ResponseFormat? responseFormat,
    ReasoningEffort? reasoningEffort,
    ServiceTier? serviceTier,
    SearchParameters? searchParameters,
    List<String>? stop,
    double? frequencyPenalty,
    double? presencePenalty,
    int? seed,
    String? user,
    String? promptCacheKey,
    String? safetyIdentifier,
    Map<String, Object?>? extra,
  }) async {
    final body = _requestBody(
      model: model,
      messages: messages,
      stream: false,
      temperature: temperature,
      topP: topP,
      maxCompletionTokens: maxCompletionTokens,
      maxTokens: maxTokens,
      n: n,
      parallelToolCalls: parallelToolCalls,
      tools: tools,
      toolChoice: toolChoice,
      responseFormat: responseFormat,
      reasoningEffort: reasoningEffort,
      serviceTier: serviceTier,
      searchParameters: searchParameters,
      stop: stop,
      frequencyPenalty: frequencyPenalty,
      presencePenalty: presencePenalty,
      seed: seed,
      user: user,
      promptCacheKey: promptCacheKey,
      safetyIdentifier: safetyIdentifier,
      extra: extra,
    );
    final json = await _transport.postJson('/chat/completions', body);
    return ChatCompletion.fromJson(json);
  }

  /// Streams a chat completion as SSE chunks.
  Stream<ChatCompletionChunk> stream({
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxCompletionTokens,
    int? maxTokens,
    int? n,
    bool? parallelToolCalls,
    List<GrokTool>? tools,
    ToolChoice? toolChoice,
    ResponseFormat? responseFormat,
    ReasoningEffort? reasoningEffort,
    ServiceTier? serviceTier,
    SearchParameters? searchParameters,
    List<String>? stop,
    double? frequencyPenalty,
    double? presencePenalty,
    int? seed,
    String? user,
    String? promptCacheKey,
    String? safetyIdentifier,
    bool includeUsage = true,
    Map<String, Object?>? extra,
  }) async* {
    final body = _requestBody(
      model: model,
      messages: messages,
      stream: true,
      temperature: temperature,
      topP: topP,
      maxCompletionTokens: maxCompletionTokens,
      maxTokens: maxTokens,
      n: n,
      parallelToolCalls: parallelToolCalls,
      tools: tools,
      toolChoice: toolChoice,
      responseFormat: responseFormat,
      reasoningEffort: reasoningEffort,
      serviceTier: serviceTier,
      searchParameters: searchParameters,
      stop: stop,
      frequencyPenalty: frequencyPenalty,
      presencePenalty: presencePenalty,
      seed: seed,
      user: user,
      promptCacheKey: promptCacheKey,
      safetyIdentifier: safetyIdentifier,
      extra: extra,
      streamOptions: includeUsage ? const {'include_usage': true} : null,
    );
    await for (final event in _transport.postSse('/chat/completions', body)) {
      if (event.isDone) {
        return;
      }
      if (event.data.trim().isEmpty) {
        continue;
      }
      yield ChatCompletionChunk.fromJson(
        asMap(jsonDecode(event.data), 'chunk'),
      );
    }
  }

  /// Streams only text deltas from [stream].
  Stream<String> streamText({
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxCompletionTokens,
    int? maxTokens,
    List<GrokTool>? tools,
    ToolChoice? toolChoice,
    ResponseFormat? responseFormat,
    ReasoningEffort? reasoningEffort,
    Map<String, Object?>? extra,
  }) async* {
    await for (final chunk in stream(
      model: model,
      messages: messages,
      temperature: temperature,
      topP: topP,
      maxCompletionTokens: maxCompletionTokens,
      maxTokens: maxTokens,
      tools: tools,
      toolChoice: toolChoice,
      responseFormat: responseFormat,
      reasoningEffort: reasoningEffort,
      extra: extra,
    )) {
      final text = chunk.text;
      if (text != null && text.isNotEmpty) {
        yield text;
      }
    }
  }
}

Map<String, Object?> _requestBody({
  required String model,
  required List<ChatMessage> messages,
  required bool stream,
  double? temperature,
  double? topP,
  int? maxCompletionTokens,
  int? maxTokens,
  int? n,
  bool? parallelToolCalls,
  List<GrokTool>? tools,
  ToolChoice? toolChoice,
  ResponseFormat? responseFormat,
  ReasoningEffort? reasoningEffort,
  ServiceTier? serviceTier,
  SearchParameters? searchParameters,
  List<String>? stop,
  double? frequencyPenalty,
  double? presencePenalty,
  int? seed,
  String? user,
  String? promptCacheKey,
  String? safetyIdentifier,
  Map<String, Object?>? extra,
  Map<String, Object?>? streamOptions,
}) {
  return omitNulls({
    'model': model,
    'messages': messages.map((message) => message.toJson()).toList(),
    'stream': stream ? true : null,
    'stream_options': streamOptions,
    'temperature': temperature,
    'top_p': topP,
    'max_completion_tokens': maxCompletionTokens,
    'max_tokens': maxTokens,
    'n': n,
    'parallel_tool_calls': parallelToolCalls,
    'tools': tools?.map((tool) => tool.toJson()).toList(),
    'tool_choice': toolChoice?.toJson(),
    'response_format': responseFormat?.toJson(),
    'reasoning_effort': reasoningEffort?.wireName,
    'service_tier': serviceTier?.wireName,
    'search_parameters': searchParameters?.toJson(),
    'stop': stop,
    'frequency_penalty': frequencyPenalty,
    'presence_penalty': presencePenalty,
    'seed': seed,
    'user': user,
    'prompt_cache_key': promptCacheKey,
    'safety_identifier': safetyIdentifier,
    ...?extra,
  });
}

/// A non-streaming chat completion.
final class ChatCompletion {
  /// Creates a chat completion.
  const ChatCompletion({
    required this.id,
    required this.model,
    required this.choices,
    required this.created,
    this.object = 'chat.completion',
    this.usage,
    this.systemFingerprint,
    this.citations,
    this.serviceTier,
  });

  /// Parses a chat completion.
  factory ChatCompletion.fromJson(Map<String, Object?> json) {
    return ChatCompletion(
      id: readString(json, 'id') ?? '',
      object: readString(json, 'object') ?? 'chat.completion',
      created: readInt(json, 'created') ?? 0,
      model: readString(json, 'model') ?? '',
      choices: [
        for (final item in readList(json, 'choices') ?? const [])
          ChatChoice.fromJson(asMap(item, 'choice')),
      ],
      usage: _usage(json),
      systemFingerprint: readString(json, 'system_fingerprint'),
      citations: readList(json, 'citations')?.whereType<String>().toList(),
      serviceTier: ServiceTier.parse(readString(json, 'service_tier')),
    );
  }

  /// Completion id.
  final String id;

  /// Object type, always `chat.completion`.
  final String object;

  /// Unix timestamp.
  final int created;

  /// Model id.
  final String model;

  /// Choices (length matches request `n`, default 1).
  final List<ChatChoice> choices;

  /// Token usage.
  final CompletionUsage? usage;

  /// Backend configuration fingerprint.
  final String? systemFingerprint;

  /// Citation URLs, when live search was used.
  final List<String>? citations;

  /// Processing tier.
  final ServiceTier? serviceTier;

  /// Assistant text of the first choice.
  String? get text => choices.isEmpty ? null : choices.first.message.text;

  /// Tool calls of the first choice.
  List<ToolCall> get toolCalls {
    if (choices.isEmpty) {
      return const [];
    }
    return choices.first.message.toolCalls ?? const [];
  }
}

/// One choice in a chat completion.
final class ChatChoice {
  /// Creates a choice.
  const ChatChoice({
    required this.index,
    required this.message,
    this.finishReason,
  });

  /// Parses a choice.
  factory ChatChoice.fromJson(Map<String, Object?> json) {
    return ChatChoice(
      index: readInt(json, 'index') ?? 0,
      message: ChatMessage.fromJson(
        readMap(json, 'message') ?? const {},
      ),
      finishReason: FinishReason.parse(readString(json, 'finish_reason')),
    );
  }

  /// Zero-based index.
  final int index;

  /// Assistant message.
  final ChatMessage message;

  /// Why generation stopped.
  final FinishReason? finishReason;
}

/// A streaming chat-completion chunk.
final class ChatCompletionChunk {
  /// Creates a chunk.
  const ChatCompletionChunk({
    required this.id,
    required this.model,
    required this.choices,
    required this.created,
    this.object = 'chat.completion.chunk',
    this.usage,
    this.systemFingerprint,
  });

  /// Parses a chunk.
  factory ChatCompletionChunk.fromJson(Map<String, Object?> json) {
    return ChatCompletionChunk(
      id: readString(json, 'id') ?? '',
      object: readString(json, 'object') ?? 'chat.completion.chunk',
      created: readInt(json, 'created') ?? 0,
      model: readString(json, 'model') ?? '',
      choices: [
        for (final item in readList(json, 'choices') ?? const [])
          ChatChunkChoice.fromJson(asMap(item, 'choice')),
      ],
      usage: _usage(json),
      systemFingerprint: readString(json, 'system_fingerprint'),
    );
  }

  /// Completion id.
  final String id;

  /// Object type, always `chat.completion.chunk`.
  final String object;

  /// Unix timestamp.
  final int created;

  /// Model id.
  final String model;

  /// Incremental choices.
  final List<ChatChunkChoice> choices;

  /// Usage, typically on the last chunk when `include_usage` is set.
  final CompletionUsage? usage;

  /// Backend configuration fingerprint.
  final String? systemFingerprint;

  /// Text delta of the first choice.
  String? get text {
    if (choices.isEmpty) {
      return null;
    }
    return choices.first.delta.content;
  }
}

/// One choice in a streaming chunk.
final class ChatChunkChoice {
  /// Creates a streaming choice.
  const ChatChunkChoice({
    required this.index,
    required this.delta,
    this.finishReason,
  });

  /// Parses a streaming choice.
  factory ChatChunkChoice.fromJson(Map<String, Object?> json) {
    return ChatChunkChoice(
      index: readInt(json, 'index') ?? 0,
      delta: ChatDelta.fromJson(readMap(json, 'delta') ?? const {}),
      finishReason: FinishReason.parse(readString(json, 'finish_reason')),
    );
  }

  /// Zero-based index.
  final int index;

  /// Incremental message delta.
  final ChatDelta delta;

  /// Why generation stopped, on the last chunk.
  final FinishReason? finishReason;
}

/// Incremental assistant payload in a stream chunk.
final class ChatDelta {
  /// Creates a delta.
  const ChatDelta({
    this.role,
    this.content,
    this.reasoningContent,
    this.toolCalls,
    this.refusal,
  });

  /// Parses a delta.
  factory ChatDelta.fromJson(Map<String, Object?> json) {
    return ChatDelta(
      role: _role(readString(json, 'role')),
      content: readString(json, 'content'),
      reasoningContent: readString(json, 'reasoning_content'),
      toolCalls: readList(json, 'tool_calls')
          ?.whereType<Map<dynamic, dynamic>>()
          .map((item) => ToolCall.fromJson(asMap(item, 'tool_call')))
          .toList(),
      refusal: readString(json, 'refusal'),
    );
  }

  /// Role, usually only on the first chunk.
  final ChatRole? role;

  /// Text delta.
  final String? content;

  /// Reasoning text delta.
  final String? reasoningContent;

  /// Tool-call deltas. xAI returns function calls whole in one chunk.
  final List<ToolCall>? toolCalls;

  /// Refusal delta.
  final String? refusal;
}

CompletionUsage? _usage(Map<String, Object?> json) {
  final value = readMap(json, 'usage');
  if (value == null) {
    return null;
  }
  return CompletionUsage.fromJson(value);
}

ChatRole? _role(String? value) {
  if (value == null) {
    return null;
  }
  return ChatRole.parse(value);
}
