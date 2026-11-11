import 'package:grok_dart/src/enums.dart';
import 'package:grok_dart/src/json.dart';

/// A tool the model may call.
sealed class GrokTool {
  /// Creates a tool.
  const GrokTool();

  /// Parses a tool from an API payload.
  factory GrokTool.fromJson(Map<String, Object?> json) {
    final type = readString(json, 'type');
    if (type == 'web_search' || type == 'web_search_preview') {
      return const WebSearchTool();
    }
    if (type == 'x_search') {
      return const XSearchTool();
    }
    return FunctionTool.fromJson(json);
  }

  /// JSON body sent to the API.
  Map<String, Object?> toJson();
}

/// A user-defined function tool.
final class FunctionTool extends GrokTool {
  /// Creates a function tool.
  const FunctionTool({
    required this.name,
    required this.parameters,
    this.description,
    this.strict,
  });

  /// Parses a function tool.
  factory FunctionTool.fromJson(Map<String, Object?> json) {
    final function = readMap(json, 'function');
    if (function != null) {
      return FunctionTool(
        name: readString(function, 'name') ?? '',
        description: readString(function, 'description'),
        parameters: readMap(function, 'parameters') ?? const {},
        strict: readBool(function, 'strict'),
      );
    }
    return FunctionTool(
      name: readString(json, 'name') ?? '',
      description: readString(json, 'description'),
      parameters: readMap(json, 'parameters') ?? const {},
      strict: readBool(json, 'strict'),
    );
  }

  /// Function name.
  final String name;

  /// What the function does.
  final String? description;

  /// JSON Schema for the function arguments. Root must be an object.
  final Map<String, Object?> parameters;

  /// Whether the model must match [parameters] strictly.
  final bool? strict;

  @override
  Map<String, Object?> toJson() {
    return omitNulls({
      'type': 'function',
      'function': omitNulls({
        'name': name,
        'description': description,
        'parameters': parameters,
        'strict': strict,
      }),
    });
  }

  /// Responses API shape (`name` at the top level, not nested).
  Map<String, Object?> toResponsesJson() {
    return omitNulls({
      'type': 'function',
      'name': name,
      'description': description,
      'parameters': parameters,
      'strict': strict,
    });
  }
}

/// Built-in web search tool (Responses API).
final class WebSearchTool extends GrokTool {
  /// Creates a web search tool.
  const WebSearchTool();

  @override
  Map<String, Object?> toJson() => const {'type': 'web_search'};
}

/// Built-in X search tool (Responses API).
final class XSearchTool extends GrokTool {
  /// Creates an X search tool.
  const XSearchTool();

  @override
  Map<String, Object?> toJson() => const {'type': 'x_search'};
}

/// Controls whether and which tools the model may call.
sealed class ToolChoice {
  /// Creates a tool choice.
  const ToolChoice();

  /// Force a specific function.
  factory ToolChoice.function(String name) = NamedToolChoice;

  /// Let the model decide.
  static const ToolChoice auto = ToolChoiceModeValue(ToolChoiceMode.auto);

  /// Require at least one tool call.
  static const ToolChoice required =
      ToolChoiceModeValue(ToolChoiceMode.required);

  /// Disable tool calling.
  static const ToolChoice none = ToolChoiceModeValue(ToolChoiceMode.none);

  /// JSON value sent to the Chat Completions API.
  Object toJson();

  /// JSON value sent to the Responses API.
  Object toResponsesJson() => toJson();
}

/// A mode-based tool choice (`auto`, `required`, or `none`).
final class ToolChoiceModeValue extends ToolChoice {
  /// Creates a mode-based tool choice.
  const ToolChoiceModeValue(this.mode);

  /// The mode.
  final ToolChoiceMode mode;

  @override
  Object toJson() => mode.wireName;
}

/// Force a named function tool.
final class NamedToolChoice extends ToolChoice {
  /// Creates a named function tool choice.
  const NamedToolChoice(this.name);

  /// Function name to force.
  final String name;

  @override
  Object toJson() {
    return {
      'type': 'function',
      'function': {'name': name},
    };
  }

  @override
  Object toResponsesJson() {
    return {
      'type': 'function',
      'name': name,
    };
  }
}

/// A tool call requested by the model in Chat Completions.
final class ToolCall {
  /// Creates a tool call.
  const ToolCall({
    required this.id,
    required this.function,
    this.type = 'function',
    this.index,
  });

  /// Parses a tool call.
  factory ToolCall.fromJson(Map<String, Object?> json) {
    return ToolCall(
      id: readString(json, 'id') ?? '',
      type: readString(json, 'type') ?? 'function',
      index: readInt(json, 'index'),
      function: FunctionCall.fromJson(
        readMap(json, 'function') ?? const {},
      ),
    );
  }

  /// Tool call id, used when returning a tool result.
  final String id;

  /// Always `"function"` today.
  final String type;

  /// Index of this call when streamed.
  final int? index;

  /// Function name and arguments.
  final FunctionCall function;

  /// JSON body.
  Map<String, Object?> toJson() {
    return omitNulls({
      'id': id,
      'type': type,
      'index': index,
      'function': function.toJson(),
    });
  }
}

/// Function name and JSON-encoded arguments.
final class FunctionCall {
  /// Creates a function call.
  const FunctionCall({
    required this.name,
    required this.arguments,
  });

  /// Parses a function call.
  factory FunctionCall.fromJson(Map<String, Object?> json) {
    return FunctionCall(
      name: readString(json, 'name') ?? '',
      arguments: readString(json, 'arguments') ?? '',
    );
  }

  /// Function name.
  final String name;

  /// JSON-encoded argument object.
  final String arguments;

  /// JSON body.
  Map<String, Object?> toJson() {
    return {
      'name': name,
      'arguments': arguments,
    };
  }
}

/// Live-search parameters shared by Chat Completions and Responses.
final class SearchParameters {
  /// Creates search parameters.
  const SearchParameters({
    this.mode,
    this.fromDate,
    this.toDate,
    this.maxSearchResults,
    this.returnCitations,
    this.sources,
  });

  /// Search mode.
  final SearchMode? mode;

  /// Inclusive start date (`YYYY-MM-DD`).
  final String? fromDate;

  /// Inclusive end date (`YYYY-MM-DD`).
  final String? toDate;

  /// Maximum number of search results.
  final int? maxSearchResults;

  /// Whether to return citations.
  final bool? returnCitations;

  /// Source names such as `web` or `x`.
  final List<String>? sources;

  /// JSON body.
  Map<String, Object?> toJson() {
    return omitNulls({
      'mode': mode?.wireName,
      'from_date': fromDate,
      'to_date': toDate,
      'max_search_results': maxSearchResults,
      'return_citations': returnCitations,
      'sources':
          sources?.map((source) => <String, Object?>{'type': source}).toList(),
    });
  }
}
