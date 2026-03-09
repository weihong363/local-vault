import 'package:flutter/material.dart';
import 'package:local_vault/core/constants/app_theme.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/features/summary/models/summary.dart';
import 'package:local_vault/features/summary/presentation/widgets/summary_card.dart';
import 'package:local_vault/features/summary/presentation/widgets/empty_state.dart';
import 'package:local_vault/features/summary/presentation/pages/summary_detail_page.dart';
import 'package:local_vault/features/summary/domain/providers/summary_provider.dart';

class GestureWakeUpDetector extends StatelessWidget {
  final VoidCallback onGestureDetected;

  const GestureWakeUpDetector({
    super.key,
    required this.onGestureDetected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: onGestureDetected,
      child: Container(),
    );
  }
}
