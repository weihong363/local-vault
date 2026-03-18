import 'package:flutter/material.dart';
import 'package:local_vault/core/constants/app_theme.dart';

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: trailing != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailing != null) Text(trailing!),
                Icon(Icons.chevron_right,
                    size: 16, color: AppColors.textMuted(context)),
              ],
            )
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: AppColors.surfaceVariant(context),
    );
  }
}
