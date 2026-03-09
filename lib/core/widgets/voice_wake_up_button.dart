import 'package:flutter/material.dart';
import 'package:local_vault/core/constants/app_theme.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/features/summary/models/summary.dart';
import 'package:local_vault/features/summary/presentation/widgets/summary_card.dart';
import 'package:local_vault/features/summary/presentation/widgets/empty_state.dart';
import 'package:local_vault/features/summary/presentation/pages/summary_detail_page.dart';
import 'package:local_vault/features/summary/domain/providers/summary_provider.dart';

class VoiceWakeUpButton extends StatelessWidget {
  final VoidCallback onVoiceDetected;

  const VoiceWakeUpButton({
    super.key,
    required this.onVoiceDetected,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onVoiceDetected,
      backgroundColor: AppColors.secondary,
      child: const Icon(Icons.mic),
    );
  }
}
