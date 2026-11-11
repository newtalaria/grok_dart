/// JSON decoding helpers for xAI response bodies.
library;

/// Reads [key] from [json] as a JSON object.
Map<String, Object?>? readMap(
  Map<String, Object?> json,
  String key,
) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  return asMap(value, key);
}

/// Reads [key] from [json] as a JSON array.
List<Object?>? readList(
  Map<String, Object?> json,
  String key,
) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  return asList(value, key);
}

/// Reads [key] from [json] as a [String].
String? readString(
  Map<String, Object?> json,
  String key,
) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  throw FormatException('Expected "$key" to be a String, got $value');
}

/// Reads [key] from [json] as an [int].
int? readInt(
  Map<String, Object?> json,
  String key,
) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  return asInt(value, key);
}

/// Reads [key] from [json] as a [double].
double? readDouble(
  Map<String, Object?> json,
  String key,
) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  throw FormatException('Expected "$key" to be a number, got $value');
}

/// Reads [key] from [json] as a [bool].
bool? readBool(
  Map<String, Object?> json,
  String key,
) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is bool) {
    return value;
  }
  throw FormatException('Expected "$key" to be a bool, got $value');
}

/// Coerces [value] to a JSON object.
Map<String, Object?> asMap(Object? value, [String name = 'value']) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return {
      for (final entry in value.entries) entry.key as String: entry.value,
    };
  }
  throw FormatException('Expected $name to be a JSON object, got $value');
}

/// Coerces [value] to a JSON array.
List<Object?> asList(Object? value, [String name = 'value']) {
  if (value is List<Object?>) {
    return value;
  }
  if (value is List) {
    return List<Object?>.from(value);
  }
  throw FormatException('Expected $name to be a JSON array, got $value');
}

/// Coerces [value] to an [int].
int asInt(Object? value, [String name = 'value']) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  throw FormatException('Expected $name to be an int, got $value');
}

/// Drops null entries so request JSON matches xAI's optional-field style.
Map<String, Object?> omitNulls(Map<String, Object?> json) {
  return {
    for (final entry in json.entries)
      if (entry.value != null) entry.key: entry.value,
  };
}
