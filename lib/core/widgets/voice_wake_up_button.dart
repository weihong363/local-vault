import 'package:flutter/material.dart';
import 'package:local_vault/core/constants/app_theme.dart';

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
