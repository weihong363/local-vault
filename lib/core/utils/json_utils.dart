import 'dart:convert';

/// JSON 和 Map 转换工具类
class JsonUtils {
  JsonUtils._();

  /// 将任意对象转换为 Map<String, dynamic>
  ///
  /// 支持以下类型:
  /// - Map<String, dynamic>: 直接返回
  /// - Map: 转换为 Map<String, dynamic>
  /// - null: 返回空 Map
  /// - 其他: 抛出 FormatException
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

  /// 安全地将 JSON 字符串解析为 Map
  static Map<String, dynamic> parseJson(String jsonString) {
    try {
      final parsed = jsonDecode(jsonString);
      return asMap(parsed);
    } catch (e) {
      return <String, dynamic>{};
    }
  }
}
