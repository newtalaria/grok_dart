import 'package:grok_dart/src/content.dart';
import 'package:grok_dart/src/enums.dart';
import 'package:grok_dart/src/json.dart';
import 'package:grok_dart/src/tools.dart';

/// A Chat Completions message.
final class ChatMessage {
  /// Creates a chat message.
  const ChatMessage({
    required this.role,
    this.content,
    this.name,
    this.toolCallId,
    this.toolCalls,
    this.reasoningContent,
    this.refusal,
  });

  /// System instructions.
  factory ChatMessage.system(String content, {String? name}) {
    return ChatMessage(
      role: ChatRole.system,
      content: content,
      name: name,
    );
  }

  /// Developer instructions.
  factory ChatMessage.developer(String content, {String? name}) {
    return ChatMessage(
      role: ChatRole.developer,
      content: content,
      name: name,
    );
  }

  /// User text, optionally with image parts.
  factory ChatMessage.user(
    String text, {
    List<ContentPart>? images,
    String? name,
  }) {
    if (images == null || images.isEmpty) {
      return ChatMessage(
        role: ChatRole.user,
        content: text,
        name: name,
      );
    }
    return ChatMessage(
      role: ChatRole.user,
      content: <ContentPart>[
        ...images,
        TextContentPart(text),
      ],
      name: name,
    );
  }

  /// A multimodal user message.
  factory ChatMessage.userParts(
    List<ContentPart> parts, {
    String? name,
  }) {
    return ChatMessage(
      role: ChatRole.user,
      content: parts,
      name: name,
    );
  }

  /// Assistant text and/or tool calls.
  factory ChatMessage.assistant({
    String? content,
    List<ToolCall>? toolCalls,
    String? reasoningContent,
    String? refusal,
  }) {
    return ChatMessage(
      role: ChatRole.assistant,
      content: content,
      toolCalls: toolCalls,
      reasoningContent: reasoningContent,
      refusal: refusal,
    );
  }

  /// Result of a previous tool call.
  factory ChatMessage.tool({
    required String toolCallId,
    required String content,
  }) {
    return ChatMessage(
      role: ChatRole.tool,
      content: content,
      toolCallId: toolCallId,
    );
  }

  /// Parses a chat message from the API.
  factory ChatMessage.fromJson(Map<String, Object?> json) {
    return ChatMessage(
      role: ChatRole.parse(readString(json, 'role') ?? 'assistant'),
      content: _parseContent(json['content']),
      name: readString(json, 'name'),
      toolCallId: readString(json, 'tool_call_id'),
      toolCalls: readList(json, 'tool_calls')
          ?.whereType<Map<dynamic, dynamic>>()
          .map((item) => ToolCall.fromJson(asMap(item, 'tool_call')))
          .toList(),
      reasoningContent: readString(json, 'reasoning_content'),
      refusal: readString(json, 'refusal'),
    );
  }

  /// Message role.
  final ChatRole role;

  /// Text, or a [List] of [ContentPart]s, or null when using tool calls.
  final Object? content;

  /// Optional speaker name.
  final String? name;

  /// Id of the tool call this message answers.
  final String? toolCallId;

  /// Tool calls requested by the assistant.
  final List<ToolCall>? toolCalls;

  /// Reasoning trace, when returned.
  final String? reasoningContent;

  /// Refusal text, when the model declined to answer.
  final String? refusal;

  /// Text content when [content] is a string.
  String? get text {
    final value = content;
    if (value is String) {
      return value;
    }
    if (value is List<ContentPart>) {
      final buffer = StringBuffer();
      for (final part in value) {
        if (part is TextContentPart) {
          buffer.write(part.text);
        }
      }
      final text = buffer.toString();
      return text.isEmpty ? null : text;
    }
    return null;
  }

  /// JSON body.
  Map<String, Object?> toJson() {
    return omitNulls({
      'role': role.wireName,
      'content': _contentJson(),
      'name': name,
      'tool_call_id': toolCallId,
      'tool_calls': toolCalls?.map((call) => call.toJson()).toList(),
      'reasoning_content': reasoningContent,
      'refusal': refusal,
    });
  }

  Object? _contentJson() {
    final value = content;
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    if (value is List<ContentPart>) {
      return value.map((part) => part.toJson()).toList();
    }
    if (value is List) {
      return value.map((item) {
        if (item is ContentPart) {
          return item.toJson();
        }
        return item;
      }).toList();
    }
    return value;
  }
}

Object? _parseContent(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  if (value is List) {
    return [
      for (final item in value)
        if (item is Map)
          ContentPart.fromJson(asMap(item, 'content part'))
        else if (item is String)
          TextContentPart(item),
    ];
  }
  return value;
}
