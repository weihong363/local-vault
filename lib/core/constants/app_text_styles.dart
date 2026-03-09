import 'package:flutter/material.dart';
import 'package:local_vault/core/constants/app_theme.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/features/summary/models/summary.dart';
import 'package:local_vault/features/summary/presentation/widgets/summary_card.dart';
import 'package:local_vault/features/summary/presentation/widgets/empty_state.dart';
import 'package:local_vault/features/summary/presentation/pages/summary_detail_page.dart';
import 'package:local_vault/features/summary/domain/providers/summary_provider.dart';

class AppTextStyles {
  AppTextStyles._();

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
}
