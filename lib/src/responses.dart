import 'dart:convert';

import 'package:grok_dart/src/content.dart';
import 'package:grok_dart/src/enums.dart';
import 'package:grok_dart/src/json.dart';
import 'package:grok_dart/src/tools.dart';
import 'package:grok_dart/src/transport.dart';
import 'package:grok_dart/src/usage.dart';

/// Responses API (`/v1/responses`).
final class ResponsesResource {
  /// Creates a responses resource.
  ResponsesResource(this._transport);

  final GrokTransport _transport;

  /// Creates a model response.
  Future<GrokResponse> create({
    required String model,
    required ResponseInput input,
    String? instructions,
    String? previousResponseId,
    int? maxOutputTokens,
    double? temperature,
    double? topP,
    bool? store,
    bool? parallelToolCalls,
    List<GrokTool>? tools,
    ToolChoice? toolChoice,
    ResponseFormat? textFormat,
    ReasoningEffort? reasoningEffort,
    ServiceTier? serviceTier,
    SearchParameters? searchParameters,
    String? promptCacheKey,
    String? user,
    String? safetyIdentifier,
    List<String>? include,
    Map<String, Object?>? extra,
  }) async {
    final body = _body(
      model: model,
      input: input,
      stream: false,
      instructions: instructions,
      previousResponseId: previousResponseId,
      maxOutputTokens: maxOutputTokens,
      temperature: temperature,
      topP: topP,
      store: store,
      parallelToolCalls: parallelToolCalls,
      tools: tools,
      toolChoice: toolChoice,
      textFormat: textFormat,
      reasoningEffort: reasoningEffort,
      serviceTier: serviceTier,
      searchParameters: searchParameters,
      promptCacheKey: promptCacheKey,
      user: user,
      safetyIdentifier: safetyIdentifier,
      include: include,
      extra: extra,
    );
    final json = await _transport.postJson('/responses', body);
    return GrokResponse.fromJson(json);
  }

  /// Streams a response as SSE events.
  Stream<ResponseStreamEvent> stream({
    required String model,
    required ResponseInput input,
    String? instructions,
    String? previousResponseId,
    int? maxOutputTokens,
    double? temperature,
    double? topP,
    bool? store,
    bool? parallelToolCalls,
    List<GrokTool>? tools,
    ToolChoice? toolChoice,
    ResponseFormat? textFormat,
    ReasoningEffort? reasoningEffort,
    ServiceTier? serviceTier,
    SearchParameters? searchParameters,
    String? promptCacheKey,
    String? user,
    Map<String, Object?>? extra,
  }) async* {
    final body = _body(
      model: model,
      input: input,
      stream: true,
      instructions: instructions,
      previousResponseId: previousResponseId,
      maxOutputTokens: maxOutputTokens,
      temperature: temperature,
      topP: topP,
      store: store,
      parallelToolCalls: parallelToolCalls,
      tools: tools,
      toolChoice: toolChoice,
      textFormat: textFormat,
      reasoningEffort: reasoningEffort,
      serviceTier: serviceTier,
      searchParameters: searchParameters,
      promptCacheKey: promptCacheKey,
      user: user,
      extra: extra,
    );
    await for (final event in _transport.postSse('/responses', body)) {
      if (event.isDone) {
        return;
      }
      if (event.data.trim().isEmpty) {
        continue;
      }
      yield ResponseStreamEvent.fromJson(
        asMap(jsonDecode(event.data), 'event'),
        event: event.event,
      );
    }
  }

  /// Retrieves a stored response by id.
  Future<GrokResponse> retrieve(String responseId) async {
    final encoded = Uri.encodeComponent(responseId);
    final json = await _transport.getJson('/responses/$encoded');
    return GrokResponse.fromJson(json);
  }

  /// Deletes a stored response by id.
  Future<DeletedResponse> delete(String responseId) async {
    final encoded = Uri.encodeComponent(responseId);
    final json = await _transport.deleteJson('/responses/$encoded');
    return DeletedResponse.fromJson(json);
  }
}

Map<String, Object?> _body({
  required String model,
  required ResponseInput input,
  required bool stream,
  String? instructions,
  String? previousResponseId,
  int? maxOutputTokens,
  double? temperature,
  double? topP,
  bool? store,
  bool? parallelToolCalls,
  List<GrokTool>? tools,
  ToolChoice? toolChoice,
  ResponseFormat? textFormat,
  ReasoningEffort? reasoningEffort,
  ServiceTier? serviceTier,
  SearchParameters? searchParameters,
  String? promptCacheKey,
  String? user,
  String? safetyIdentifier,
  List<String>? include,
  Map<String, Object?>? extra,
}) {
  return omitNulls({
    'model': model,
    'input': input.toJson(),
    'stream': stream ? true : null,
    'instructions': instructions,
    'previous_response_id': previousResponseId,
    'max_output_tokens': maxOutputTokens,
    'temperature': temperature,
    'top_p': topP,
    'store': store,
    'parallel_tool_calls': parallelToolCalls,
    'tools': tools?.map(_toolJson).toList(),
    'tool_choice': toolChoice?.toResponsesJson(),
    'text':
        textFormat == null ? null : {'format': textFormat.toResponsesFormat()},
    'reasoning':
        reasoningEffort == null ? null : {'effort': reasoningEffort.wireName},
    'service_tier': serviceTier?.wireName,
    'search_parameters': searchParameters?.toJson(),
    'prompt_cache_key': promptCacheKey,
    'user': user,
    'safety_identifier': safetyIdentifier,
    'include': include,
    ...?extra,
  });
}

Map<String, Object?> _toolJson(GrokTool tool) {
  return switch (tool) {
    FunctionTool() => tool.toResponsesJson(),
    WebSearchTool() => tool.toJson(),
    XSearchTool() => tool.toJson(),
  };
}

/// Input to `POST /v1/responses`.
sealed class ResponseInput {
  /// Creates response input.
  const ResponseInput();

  /// A plain-text prompt.
  factory ResponseInput.text(String text) = TextResponseInput;

  /// A list of input items / messages.
  factory ResponseInput.items(List<ResponseInputItem> items) =
      ItemsResponseInput;

  /// JSON value sent as `input`.
  Object toJson();
}

/// String input.
final class TextResponseInput extends ResponseInput {
  /// Creates text input.
  const TextResponseInput(this.text);

  /// Prompt text.
  final String text;

  @override
  Object toJson() => text;
}

/// Item-list input.
final class ItemsResponseInput extends ResponseInput {
  /// Creates item-list input.
  const ItemsResponseInput(this.items);

  /// Input items.
  final List<ResponseInputItem> items;

  @override
  Object toJson() => items.map((item) => item.toJson()).toList();
}

/// One item in a Responses API input array.
sealed class ResponseInputItem {
  /// Creates an input item.
  const ResponseInputItem();

  /// A user, system, or assistant message.
  factory ResponseInputItem.message({
    required ChatRole role,
    required Object content,
  }) = ResponseInputMessage;

  /// A user text message.
  factory ResponseInputItem.user(
    String text, {
    List<ContentPart>? images,
  }) {
    if (images == null || images.isEmpty) {
      return ResponseInputMessage(role: ChatRole.user, content: text);
    }
    return ResponseInputMessage(
      role: ChatRole.user,
      content: <ContentPart>[...images, TextContentPart(text)],
    );
  }

  /// Output of a previous function call.
  factory ResponseInputItem.functionCallOutput({
    required String callId,
    required String output,
  }) = FunctionCallOutputItem;

  /// JSON body.
  Map<String, Object?> toJson();
}

/// A message input item.
final class ResponseInputMessage extends ResponseInputItem {
  /// Creates a message item.
  const ResponseInputMessage({
    required this.role,
    required this.content,
  });

  /// Role.
  final ChatRole role;

  /// String or [List] of [ContentPart].
  final Object content;

  @override
  Map<String, Object?> toJson() {
    return {
      'role': role.wireName,
      'content': _encode(content),
    };
  }
}

/// A function-call output item.
final class FunctionCallOutputItem extends ResponseInputItem {
  /// Creates a function-call output.
  const FunctionCallOutputItem({
    required this.callId,
    required this.output,
  });

  /// Call id from [ResponseFunctionCall.callId].
  final String callId;

  /// Tool result, usually JSON.
  final String output;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'function_call_output',
      'call_id': callId,
      'output': output,
    };
  }
}

Object _encode(Object content) {
  if (content is String) {
    return content;
  }
  if (content is List<ContentPart>) {
    return content.map((part) => part.toResponsesJson()).toList();
  }
  if (content is List) {
    return [
      for (final item in content)
        if (item is ContentPart) item.toResponsesJson() else item,
    ];
  }
  return content;
}

/// A Responses API object.
final class GrokResponse {
  /// Creates a response.
  const GrokResponse({
    required this.id,
    required this.model,
    required this.status,
    required this.output,
    required this.createdAt,
    this.object = 'response',
    this.usage,
    this.previousResponseId,
    this.instructions,
    this.parallelToolCalls,
    this.store,
    this.error,
    this.incompleteDetails,
    this.completedAt,
  });

  /// Parses a response.
  factory GrokResponse.fromJson(Map<String, Object?> json) {
    return GrokResponse(
      id: readString(json, 'id') ?? '',
      object: readString(json, 'object') ?? 'response',
      createdAt: readInt(json, 'created_at') ?? 0,
      completedAt: readInt(json, 'completed_at'),
      model: readString(json, 'model') ?? '',
      status: ResponseStatus.parse(readString(json, 'status')),
      output: [
        for (final item in readList(json, 'output') ?? const [])
          ResponseOutputItem.fromJson(asMap(item, 'output item')),
      ],
      usage: _usage(json),
      previousResponseId: readString(json, 'previous_response_id'),
      instructions: readString(json, 'instructions'),
      parallelToolCalls: readBool(json, 'parallel_tool_calls'),
      store: readBool(json, 'store'),
      error: readMap(json, 'error'),
      incompleteDetails: readMap(json, 'incomplete_details'),
    );
  }

  /// Response id, usable with [previousResponseId]
  /// and [ResponsesResource.retrieve].
  final String id;

  /// Object type, always `response`.
  final String object;

  /// Creation timestamp.
  final int createdAt;

  /// Completion timestamp.
  final int? completedAt;

  /// Model id.
  final String model;

  /// Status.
  final ResponseStatus status;

  /// Output items.
  final List<ResponseOutputItem> output;

  /// Token usage.
  final ResponseUsage? usage;

  /// Previous response this one continues.
  final String? previousResponseId;

  /// System / developer instructions.
  final String? instructions;

  /// Whether parallel tool calls were allowed.
  final bool? parallelToolCalls;

  /// Whether the response was stored.
  final bool? store;

  /// Error object when generation failed.
  final Map<String, Object?>? error;

  /// Details when [status] is incomplete.
  final Map<String, Object?>? incompleteDetails;

  /// Concatenated `output_text` parts.
  String get outputText {
    final buffer = StringBuffer();
    for (final item in output) {
      if (item is ResponseOutputMessage) {
        buffer.write(item.text);
      }
    }
    return buffer.toString();
  }

  /// Function calls in [output].
  List<ResponseFunctionCall> get functionCalls {
    return [
      for (final item in output)
        if (item is ResponseFunctionCall) item,
    ];
  }
}

/// Result of `DELETE /v1/responses/{id}`.
final class DeletedResponse {
  /// Creates a deleted-response payload.
  const DeletedResponse({
    required this.id,
    required this.deleted,
    this.object = 'response',
  });

  /// Parses a deleted-response payload.
  factory DeletedResponse.fromJson(Map<String, Object?> json) {
    return DeletedResponse(
      id: readString(json, 'id') ?? '',
      object: readString(json, 'object') ?? 'response',
      deleted: readBool(json, 'deleted') ?? true,
    );
  }

  /// Deleted response id.
  final String id;

  /// Object type.
  final String object;

  /// Whether deletion succeeded.
  final bool deleted;
}

/// An item in [GrokResponse.output].
sealed class ResponseOutputItem {
  /// Creates an output item.
  const ResponseOutputItem();

  /// Parses an output item by `type`.
  factory ResponseOutputItem.fromJson(Map<String, Object?> json) {
    final type = readString(json, 'type');
    if (type == 'function_call') {
      return ResponseFunctionCall.fromJson(json);
    }
    if (type == 'reasoning') {
      return ResponseReasoning.fromJson(json);
    }
    if (type == 'message' || type == null) {
      return ResponseOutputMessage.fromJson(json);
    }
    return ResponseUnknownOutput(type: type, json: json);
  }
}

/// An assistant message.
final class ResponseOutputMessage extends ResponseOutputItem {
  /// Creates an output message.
  const ResponseOutputMessage({
    required this.content,
    this.id,
    this.role = ChatRole.assistant,
    this.status,
  });

  /// Parses an output message.
  factory ResponseOutputMessage.fromJson(Map<String, Object?> json) {
    return ResponseOutputMessage(
      id: readString(json, 'id'),
      role: ChatRole.parse(readString(json, 'role') ?? 'assistant'),
      status: ResponseStatus.parse(readString(json, 'status')),
      content: [
        for (final item in readList(json, 'content') ?? const [])
          ResponseContentPart.fromJson(asMap(item, 'content part')),
      ],
    );
  }

  /// Message id.
  final String? id;

  /// Role, always assistant for model output.
  final ChatRole role;

  /// Item status.
  final ResponseStatus? status;

  /// Content parts.
  final List<ResponseContentPart> content;

  /// Concatenated text parts.
  String get text {
    final buffer = StringBuffer();
    for (final part in content) {
      if (part is ResponseOutputText) {
        buffer.write(part.text);
      }
    }
    return buffer.toString();
  }
}

/// A function call requested by the model.
final class ResponseFunctionCall extends ResponseOutputItem {
  /// Creates a function call.
  const ResponseFunctionCall({
    required this.name,
    required this.arguments,
    required this.callId,
    this.id,
    this.status,
  });

  /// Parses a function call.
  factory ResponseFunctionCall.fromJson(Map<String, Object?> json) {
    return ResponseFunctionCall(
      id: readString(json, 'id'),
      callId: readString(json, 'call_id') ?? '',
      name: readString(json, 'name') ?? '',
      arguments: readString(json, 'arguments') ?? '',
      status: ResponseStatus.parse(readString(json, 'status')),
    );
  }

  /// Item id.
  final String? id;

  /// Call id, passed back with the tool result.
  final String callId;

  /// Function name.
  final String name;

  /// JSON-encoded arguments.
  final String arguments;

  /// Item status.
  final ResponseStatus? status;
}

/// Encrypted or summarized reasoning.
final class ResponseReasoning extends ResponseOutputItem {
  /// Creates a reasoning item.
  const ResponseReasoning({
    this.id,
    this.summary = const [],
    this.encryptedContent,
    this.status,
  });

  /// Parses a reasoning item.
  factory ResponseReasoning.fromJson(Map<String, Object?> json) {
    return ResponseReasoning(
      id: readString(json, 'id'),
      encryptedContent: readString(json, 'encrypted_content'),
      status: ResponseStatus.parse(readString(json, 'status')),
      summary: [
        for (final item in readList(json, 'summary') ?? const [])
          if (item is Map)
            readString(asMap(item, 'summary'), 'text') ?? ''
          else
            item.toString(),
      ],
    );
  }

  /// Item id.
  final String? id;

  /// Summary texts.
  final List<String> summary;

  /// Encrypted reasoning, when requested via `include`.
  final String? encryptedContent;

  /// Item status.
  final ResponseStatus? status;
}

/// An output type not modeled by this SDK.
final class ResponseUnknownOutput extends ResponseOutputItem {
  /// Creates an unknown output item.
  const ResponseUnknownOutput({
    required this.type,
    required this.json,
  });

  /// Raw `type` field.
  final String type;

  /// Raw JSON.
  final Map<String, Object?> json;
}

/// A content part inside an output message.
sealed class ResponseContentPart {
  /// Creates a content part.
  const ResponseContentPart();

  /// Parses a content part.
  factory ResponseContentPart.fromJson(Map<String, Object?> json) {
    final type = readString(json, 'type');
    if (type == 'output_text' || type == 'text' || type == null) {
      return ResponseOutputText(
        text: readString(json, 'text') ?? '',
        annotations: readList(json, 'annotations'),
      );
    }
    if (type == 'refusal') {
      return ResponseRefusal(readString(json, 'refusal') ?? '');
    }
    return ResponseUnknownContent(type: type, json: json);
  }
}

/// Output text.
final class ResponseOutputText extends ResponseContentPart {
  /// Creates output text.
  const ResponseOutputText({
    required this.text,
    this.annotations,
  });

  /// Text.
  final String text;

  /// Optional annotations.
  final List<Object?>? annotations;
}

/// A model refusal.
final class ResponseRefusal extends ResponseContentPart {
  /// Creates a refusal.
  const ResponseRefusal(this.refusal);

  /// Refusal text.
  final String refusal;
}

/// An unknown content part.
final class ResponseUnknownContent extends ResponseContentPart {
  /// Creates an unknown content part.
  const ResponseUnknownContent({
    required this.type,
    required this.json,
  });

  /// Raw type.
  final String type;

  /// Raw JSON.
  final Map<String, Object?> json;
}

/// An event from a Responses API SSE stream.
sealed class ResponseStreamEvent {
  /// Creates a stream event.
  const ResponseStreamEvent();

  /// Parses a stream event.
  factory ResponseStreamEvent.fromJson(
    Map<String, Object?> json, {
    String? event,
  }) {
    final type = readString(json, 'type') ?? event;
    if (type == 'response.output_text.delta') {
      return ResponseTextDeltaEvent(
        delta: readString(json, 'delta') ?? readString(json, 'text') ?? '',
        json: json,
      );
    }
    if (type == 'response.completed' || json['object'] == 'response') {
      return ResponseCompletedEvent(GrokResponse.fromJson(json));
    }
    if (json.containsKey('output') && json.containsKey('id')) {
      return ResponseCompletedEvent(GrokResponse.fromJson(json));
    }
    return ResponseUnknownEvent(type: type ?? 'unknown', json: json);
  }
}

/// A text delta.
final class ResponseTextDeltaEvent extends ResponseStreamEvent {
  /// Creates a text-delta event.
  const ResponseTextDeltaEvent({
    required this.delta,
    required this.json,
  });

  /// Incremental text.
  final String delta;

  /// Raw JSON.
  final Map<String, Object?> json;
}

/// A completed (or snapshot) response.
final class ResponseCompletedEvent extends ResponseStreamEvent {
  /// Creates a completed-response event.
  const ResponseCompletedEvent(this.response);

  /// Response snapshot.
  final GrokResponse response;
}

/// An unrecognized stream event.
final class ResponseUnknownEvent extends ResponseStreamEvent {
  /// Creates an unknown event.
  const ResponseUnknownEvent({
    required this.type,
    required this.json,
  });

  /// Event type.
  final String type;

  /// Raw JSON.
  final Map<String, Object?> json;
}

ResponseUsage? _usage(Map<String, Object?> json) {
  final value = readMap(json, 'usage');
  if (value == null) {
    return null;
  }
  return ResponseUsage.fromJson(value);
}
