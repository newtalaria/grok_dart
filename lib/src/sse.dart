/// A single Server-Sent Event.
final class SseEvent {
  /// Creates an SSE event.
  const SseEvent({required this.data, this.event});

  /// Optional event name from the `event:` field.
  final String? event;

  /// Payload from one or more `data:` fields.
  final String data;

  /// Whether this event is the OpenAI-style stream terminator.
  bool get isDone => data.trim() == '[DONE]';
}

/// Incremental SSE parser for `text/event-stream` bodies.
final class SseParser {
  final StringBuffer _carry = StringBuffer();
  final StringBuffer _data = StringBuffer();
  String? _event;
  bool _hasData = false;

  /// Feeds [chunk] and yields complete events.
  Iterable<SseEvent> add(String chunk) sync* {
    _carry.write(chunk);
    var buffer = _carry.toString();
    while (true) {
      final newline = buffer.indexOf('\n');
      if (newline < 0) {
        _carry
          ..clear()
          ..write(buffer);
        return;
      }
      var line = buffer.substring(0, newline);
      buffer = buffer.substring(newline + 1);
      if (line.endsWith('\r')) {
        line = line.substring(0, line.length - 1);
      }
      final event = _consumeLine(line);
      if (event != null) {
        yield event;
      }
    }
  }

  /// Flushes a trailing event if the stream ended without a blank line.
  SseEvent? flush() {
    if (!_hasData && _event == null) {
      return null;
    }
    return _emit();
  }

  SseEvent? _consumeLine(String line) {
    if (line.isEmpty) {
      if (!_hasData && _event == null) {
        return null;
      }
      return _emit();
    }
    if (line.startsWith(':')) {
      return null;
    }
    final colon = line.indexOf(':');
    final field = colon < 0 ? line : line.substring(0, colon);
    var value = colon < 0 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) {
      value = value.substring(1);
    }
    switch (field) {
      case 'event':
        _event = value;
      case 'data':
        if (_hasData) {
          _data.write('\n');
        }
        _data.write(value);
        _hasData = true;
      default:
        break;
    }
    return null;
  }

  SseEvent _emit() {
    final event = SseEvent(
      event: _event,
      data: _data.toString(),
    );
    _event = null;
    _data.clear();
    _hasData = false;
    return event;
  }
}
