import 'package:grok_dart/src/json.dart';

/// Token usage reported by Chat Completions.
final class CompletionUsage {
  /// Creates chat-completion usage.
  const CompletionUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    this.promptTokensDetails,
    this.completionTokensDetails,
    this.numSourcesUsed,
    this.costInUsdTicks,
    this.serverSideToolUsage,
  });

  /// Parses usage from a Chat Completions payload.
  factory CompletionUsage.fromJson(Map<String, Object?> json) {
    return CompletionUsage(
      promptTokens: readInt(json, 'prompt_tokens') ?? 0,
      completionTokens: readInt(json, 'completion_tokens') ?? 0,
      totalTokens: readInt(json, 'total_tokens') ?? 0,
      promptTokensDetails: _map(
        json,
        'prompt_tokens_details',
        PromptTokensDetails.fromJson,
      ),
      completionTokensDetails: _map(
        json,
        'completion_tokens_details',
        CompletionTokensDetails.fromJson,
      ),
      numSourcesUsed: readInt(json, 'num_sources_used'),
      costInUsdTicks: readInt(json, 'cost_in_usd_ticks'),
      serverSideToolUsage: _map(
        json,
        'server_side_tool_usage_details',
        ServerSideToolUsage.fromJson,
      ),
    );
  }

  /// Prompt (input) tokens billed for the request.
  final int promptTokens;

  /// Completion (output) tokens billed for the request.
  final int completionTokens;

  /// [promptTokens] + [completionTokens].
  final int totalTokens;

  /// Breakdown of prompt tokens.
  final PromptTokensDetails? promptTokensDetails;

  /// Breakdown of completion tokens.
  final CompletionTokensDetails? completionTokensDetails;

  /// Number of live-search sources used.
  final int? numSourcesUsed;

  /// Cost in USD ticks (10_000_000_000 ticks = $1).
  final int? costInUsdTicks;

  /// Counts of server-side tool calls.
  final ServerSideToolUsage? serverSideToolUsage;
}

/// Token usage reported by the Responses API.
final class ResponseUsage {
  /// Creates Responses API usage.
  const ResponseUsage({
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
    this.inputTokensDetails,
    this.outputTokensDetails,
    this.numSourcesUsed,
    this.numServerSideToolsUsed,
    this.costInUsdTicks,
    this.costInNanoUsd,
    this.serverSideToolUsage,
  });

  /// Parses usage from a Responses payload.
  factory ResponseUsage.fromJson(Map<String, Object?> json) {
    return ResponseUsage(
      inputTokens:
          readInt(json, 'input_tokens') ?? readInt(json, 'prompt_tokens') ?? 0,
      outputTokens: readInt(json, 'output_tokens') ??
          readInt(json, 'completion_tokens') ??
          0,
      totalTokens: readInt(json, 'total_tokens') ?? 0,
      inputTokensDetails: _map(
        json,
        'input_tokens_details',
        InputTokensDetails.fromJson,
      ),
      outputTokensDetails: _map(
        json,
        'output_tokens_details',
        OutputTokensDetails.fromJson,
      ),
      numSourcesUsed: readInt(json, 'num_sources_used'),
      numServerSideToolsUsed: readInt(json, 'num_server_side_tools_used'),
      costInUsdTicks: readInt(json, 'cost_in_usd_ticks'),
      costInNanoUsd: readInt(json, 'cost_in_nano_usd'),
      serverSideToolUsage: _map(
        json,
        'server_side_tool_usage_details',
        ServerSideToolUsage.fromJson,
      ),
    );
  }

  /// Input tokens.
  final int inputTokens;

  /// Output tokens.
  final int outputTokens;

  /// [inputTokens] + [outputTokens].
  final int totalTokens;

  /// Breakdown of input tokens.
  final InputTokensDetails? inputTokensDetails;

  /// Breakdown of output tokens.
  final OutputTokensDetails? outputTokensDetails;

  /// Number of live-search sources used.
  final int? numSourcesUsed;

  /// Number of server-side tools used.
  final int? numServerSideToolsUsed;

  /// Cost in USD ticks (10_000_000_000 ticks = $1).
  final int? costInUsdTicks;

  /// Cost in nano-USD.
  final int? costInNanoUsd;

  /// Counts of server-side tool calls.
  final ServerSideToolUsage? serverSideToolUsage;
}

/// Prompt-token breakdown for Chat Completions.
final class PromptTokensDetails {
  /// Creates prompt-token details.
  const PromptTokensDetails({
    this.textTokens,
    this.audioTokens,
    this.imageTokens,
    this.cachedTokens,
  });

  /// Parses prompt-token details.
  factory PromptTokensDetails.fromJson(Map<String, Object?> json) {
    return PromptTokensDetails(
      textTokens: readInt(json, 'text_tokens'),
      audioTokens: readInt(json, 'audio_tokens'),
      imageTokens: readInt(json, 'image_tokens'),
      cachedTokens: readInt(json, 'cached_tokens'),
    );
  }

  /// Text prompt tokens.
  final int? textTokens;

  /// Audio prompt tokens.
  final int? audioTokens;

  /// Image prompt tokens.
  final int? imageTokens;

  /// Tokens served from the prompt cache.
  final int? cachedTokens;
}

/// Completion-token breakdown for Chat Completions.
final class CompletionTokensDetails {
  /// Creates completion-token details.
  const CompletionTokensDetails({
    this.reasoningTokens,
    this.audioTokens,
    this.acceptedPredictionTokens,
    this.rejectedPredictionTokens,
  });

  /// Parses completion-token details.
  factory CompletionTokensDetails.fromJson(Map<String, Object?> json) {
    return CompletionTokensDetails(
      reasoningTokens: readInt(json, 'reasoning_tokens'),
      audioTokens: readInt(json, 'audio_tokens'),
      acceptedPredictionTokens: readInt(json, 'accepted_prediction_tokens'),
      rejectedPredictionTokens: readInt(json, 'rejected_prediction_tokens'),
    );
  }

  /// Hidden reasoning tokens.
  final int? reasoningTokens;

  /// Audio completion tokens.
  final int? audioTokens;

  /// Accepted predicted tokens.
  final int? acceptedPredictionTokens;

  /// Rejected predicted tokens.
  final int? rejectedPredictionTokens;
}

/// Input-token breakdown for the Responses API.
final class InputTokensDetails {
  /// Creates input-token details.
  const InputTokensDetails({this.cachedTokens});

  /// Parses input-token details.
  factory InputTokensDetails.fromJson(Map<String, Object?> json) {
    return InputTokensDetails(
      cachedTokens: readInt(json, 'cached_tokens'),
    );
  }

  /// Tokens served from the prompt cache.
  final int? cachedTokens;
}

/// Output-token breakdown for the Responses API.
final class OutputTokensDetails {
  /// Creates output-token details.
  const OutputTokensDetails({this.reasoningTokens});

  /// Parses output-token details.
  factory OutputTokensDetails.fromJson(Map<String, Object?> json) {
    return OutputTokensDetails(
      reasoningTokens: readInt(json, 'reasoning_tokens'),
    );
  }

  /// Hidden reasoning tokens.
  final int? reasoningTokens;
}

/// Counts of server-side tool invocations.
final class ServerSideToolUsage {
  /// Creates server-side tool usage.
  const ServerSideToolUsage({
    this.webSearchCalls,
    this.xSearchCalls,
    this.xPostsFetched,
    this.xUsersFetched,
    this.codeInterpreterCalls,
    this.documentSearchCalls,
    this.fileSearchCalls,
    this.imageGenerationCalls,
    this.mcpCalls,
  });

  /// Parses server-side tool usage.
  factory ServerSideToolUsage.fromJson(Map<String, Object?> json) {
    return ServerSideToolUsage(
      webSearchCalls: readInt(json, 'web_search_calls'),
      xSearchCalls: readInt(json, 'x_search_calls'),
      xPostsFetched: readInt(json, 'x_posts_fetched'),
      xUsersFetched: readInt(json, 'x_users_fetched'),
      codeInterpreterCalls: readInt(json, 'code_interpreter_calls'),
      documentSearchCalls: readInt(json, 'document_search_calls'),
      fileSearchCalls: readInt(json, 'file_search_calls'),
      imageGenerationCalls: readInt(json, 'image_generation_calls'),
      mcpCalls: readInt(json, 'mcp_calls'),
    );
  }

  /// Web search calls.
  final int? webSearchCalls;

  /// X (Twitter) search calls.
  final int? xSearchCalls;

  /// X posts fetched.
  final int? xPostsFetched;

  /// X user profiles fetched.
  final int? xUsersFetched;

  /// Code interpreter calls.
  final int? codeInterpreterCalls;

  /// Document search calls.
  final int? documentSearchCalls;

  /// File search calls.
  final int? fileSearchCalls;

  /// Image generation calls.
  final int? imageGenerationCalls;

  /// MCP calls.
  final int? mcpCalls;
}

T? _map<T>(
  Map<String, Object?> json,
  String key,
  T Function(Map<String, Object?> json) parse,
) {
  final value = readMap(json, key);
  if (value == null) {
    return null;
  }
  return parse(value);
}
