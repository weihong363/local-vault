import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_vault/core/constants/app_theme.dart';
import 'package:local_vault/core/constants/app_routes.dart';

class FloatingSaveButton extends StatelessWidget {
  const FloatingSaveButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        context.push(AppRoutes.save);
      },
      icon: const Icon(Icons.add),
      label: const Text('保存'),
      backgroundColor: AppColors.primary,
    );
  }
}
