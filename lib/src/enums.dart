/// Role of a chat message.
enum ChatRole {
  /// System instructions.
  system,

  /// End-user input.
  user,

  /// Model output.
  assistant,

  /// Tool/function result (Chat Completions).
  tool,

  /// Developer instructions (OpenAI-compatible alias of system).
  developer,

  /// An unrecognized role from the API.
  unknown;

  /// Wire value sent to the API.
  String get wireName {
    return switch (this) {
      ChatRole.system => 'system',
      ChatRole.user => 'user',
      ChatRole.assistant => 'assistant',
      ChatRole.tool => 'tool',
      ChatRole.developer => 'developer',
      ChatRole.unknown => 'unknown',
    };
  }

  /// Parses an API role string.
  static ChatRole parse(String value) {
    for (final role in ChatRole.values) {
      if (role.wireName == value) {
        return role;
      }
    }
    return ChatRole.unknown;
  }
}

/// Why a chat completion stopped generating.
enum FinishReason {
  /// A natural stop or a user-supplied stop sequence.
  stop,

  /// Hit the max token limit.
  length,

  /// The model requested a tool call.
  toolCalls,

  /// Content was filtered.
  contentFilter,

  /// The model ended its turn (streaming).
  endTurn,

  /// An unrecognized finish reason from the API.
  unknown;

  /// Parses an API finish-reason string.
  static FinishReason? parse(String? value) {
    if (value == null) {
      return null;
    }
    for (final reason in FinishReason.values) {
      if (reason.wireName == value) {
        return reason;
      }
    }
    return FinishReason.unknown;
  }

  /// Wire value, if this reason is sent in requests.
  String get wireName {
    return switch (this) {
      FinishReason.stop => 'stop',
      FinishReason.length => 'length',
      FinishReason.toolCalls => 'tool_calls',
      FinishReason.contentFilter => 'content_filter',
      FinishReason.endTurn => 'end_turn',
      FinishReason.unknown => 'unknown',
    };
  }
}

/// Image detail level for vision inputs.
enum ImageDetail {
  /// Let the model choose.
  auto,

  /// Low-resolution / cheaper understanding.
  low,

  /// High-resolution understanding.
  high;

  /// Wire value sent to the API.
  String get wireName {
    return switch (this) {
      ImageDetail.auto => 'auto',
      ImageDetail.low => 'low',
      ImageDetail.high => 'high',
    };
  }

  /// Parses an API detail string.
  static ImageDetail? parse(String? value) {
    if (value == null) {
      return null;
    }
    for (final detail in ImageDetail.values) {
      if (detail.wireName == value) {
        return detail;
      }
    }
    return ImageDetail.auto;
  }
}

/// Reasoning effort for Grok reasoning models.
enum ReasoningEffort {
  /// Minimal reasoning.
  low,

  /// Balanced reasoning.
  medium,

  /// Deep reasoning (typical default).
  high,

  /// Maximum reasoning depth.
  xhigh;

  /// Wire value sent to the API.
  String get wireName {
    return switch (this) {
      ReasoningEffort.low => 'low',
      ReasoningEffort.medium => 'medium',
      ReasoningEffort.high => 'high',
      ReasoningEffort.xhigh => 'xhigh',
    };
  }

  /// Parses an API effort string.
  static ReasoningEffort? parse(String? value) {
    if (value == null) {
      return null;
    }
    for (final effort in ReasoningEffort.values) {
      if (effort.wireName == value) {
        return effort;
      }
    }
    return null;
  }
}

/// Processing tier for a request.
enum ServiceTier {
  /// Standard processing.
  defaultTier,

  /// Higher scheduling priority.
  priority,

  /// Fast deployment when available.
  fast;

  /// Wire value sent to the API.
  String get wireName {
    return switch (this) {
      ServiceTier.defaultTier => 'default',
      ServiceTier.priority => 'priority',
      ServiceTier.fast => 'fast',
    };
  }

  /// Parses an API service-tier string.
  static ServiceTier? parse(String? value) {
    if (value == null) {
      return null;
    }
    for (final tier in ServiceTier.values) {
      if (tier.wireName == value) {
        return tier;
      }
    }
    return null;
  }
}

/// Live-search mode for `search_parameters`.
enum SearchMode {
  /// Do not search external sources.
  off,

  /// Search enabled sources.
  on,

  /// Let the model decide.
  auto;

  /// Wire value sent to the API.
  String get wireName {
    return switch (this) {
      SearchMode.off => 'off',
      SearchMode.on => 'on',
      SearchMode.auto => 'auto',
    };
  }
}

/// Status of a Responses API object.
enum ResponseStatus {
  /// Generation finished.
  completed,

  /// Still running.
  inProgress,

  /// Stopped before completion (for example max tokens).
  incomplete,

  /// Failed.
  failed,

  /// An unrecognized status from the API.
  unknown;

  /// Parses an API status string.
  static ResponseStatus parse(String? value) {
    if (value == null) {
      return ResponseStatus.unknown;
    }
    for (final status in ResponseStatus.values) {
      if (status.wireName == value) {
        return status;
      }
    }
    return ResponseStatus.unknown;
  }

  /// Wire value.
  String get wireName {
    return switch (this) {
      ResponseStatus.completed => 'completed',
      ResponseStatus.inProgress => 'in_progress',
      ResponseStatus.incomplete => 'incomplete',
      ResponseStatus.failed => 'failed',
      ResponseStatus.unknown => 'unknown',
    };
  }
}

/// How the model should choose tools.
enum ToolChoiceMode {
  /// The model decides.
  auto,

  /// The model must call at least one tool.
  required,

  /// Disable tool calling.
  none;

  /// Wire value sent to the API.
  String get wireName {
    return switch (this) {
      ToolChoiceMode.auto => 'auto',
      ToolChoiceMode.required => 'required',
      ToolChoiceMode.none => 'none',
    };
  }
}
