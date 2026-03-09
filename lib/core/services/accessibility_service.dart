import 'package:flutter/material.dart';
import 'package:local_vault/core/constants/app_theme.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/features/summary/models/summary.dart';
import 'package:local_vault/features/summary/presentation/widgets/summary_card.dart';
import 'package:local_vault/features/summary/presentation/widgets/empty_state.dart';
import 'package:local_vault/features/summary/presentation/pages/summary_detail_page.dart';
import 'package:local_vault/features/summary/domain/providers/summary_provider.dart';

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
    print('注入文本: $text');
  }
}
