import 'package:flutter/material.dart';
import 'package:local_vault/core/constants/app_theme.dart';
import 'package:local_vault/features/summary/models/summary.dart';

class SummaryCard extends StatelessWidget {
  final Summary summary;
  final VoidCallback onTap;

  const SummaryCard({
    super.key,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(
            summary.title.substring(0, 1),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(summary.title),
        subtitle: Text(
          summary.content.length > 100
              ? '${summary.content.substring(0, 100)}...'
              : summary.content,
        ),
        trailing: summary.updatedAt != null
            ? Text(
                _formatDate(summary.updatedAt!),
                style: Theme.of(context).textTheme.bodySmall,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else {
      return '${diff.inDays}天前';
    }
  }
}
