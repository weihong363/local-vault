import 'package:flutter/foundation.dart';

class AccessibilityService {
  AccessibilityService._();

  static final AccessibilityService _instance = AccessibilityService._();

  static AccessibilityService get instance => _instance;

  Future<bool> isAccessibilityServiceEnabled() async {
    return true;
  }

  Future<String?> getFocusedText() async {
    return null;
  }

  Future<void> injectText(String text) async {
    debugPrint('注入文本: $text');
  }
}
