import 'dart:convert';

/// JSON and Map conversion utility class
class JsonUtils {
  JsonUtils._();

  /// Convert any object to Map<String, dynamic>
  ///
  /// Supports the following types:
  /// - Map<String, dynamic>: return directly
  /// - Map: convert to Map<String, dynamic>
  /// - null: return empty Map
  /// - Other: throw FormatException
  static Map<String, dynamic> asMap(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map((key, value) {
        return MapEntry(key.toString(), value);
      });
    }
    return <String, dynamic>{};
  }

  /// Safely parse JSON string to Map
  static Map<String, dynamic> parseJson(String jsonString) {
    try {
      final parsed = jsonDecode(jsonString);
      return asMap(parsed);
    } catch (e) {
      return <String, dynamic>{};
    }
  }
}
