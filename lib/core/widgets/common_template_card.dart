import 'package:flutter/material.dart';
import 'package:local_vault/core/constants/app_theme.dart';
import 'package:local_vault/core/domain/entities/template_entity.dart';

/// 通用模板卡片组件
/// 用于模板选择界面和模板管理界面
class CommonTemplateCard extends StatelessWidget {
  final TemplateEntity template;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const CommonTemplateCard({
    super.key,
    required this.template,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          template.title,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : null,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              template.content,
              style: TextStyle(
                color: isDark ? AppColors.darkTextMuted : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (template.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: template.tags.map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: const TextStyle(fontSize: 12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceVariant
                          : Colors.grey.shade200,
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
        trailing: showActions && (onEdit != null || onDelete != null)
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: onEdit,
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                    ),
                ],
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
