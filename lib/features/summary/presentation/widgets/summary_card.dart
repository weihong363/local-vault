import 'package:flutter/material.dart';
import 'package:local_vault/core/constants/app_theme.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';

class SummaryCard extends StatelessWidget {
  final SummaryEntity summary;
  final VoidCallback onTap;
  final int index;

  const SummaryCard({
    super.key,
    required this.summary,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getAvatarColor(index),
              radius: 24,
              child: Text(
                summary.title.isNotEmpty ? summary.title.substring(0, 1) : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    summary.title.length > 20
                        ? '${summary.title.substring(0, 20)}...'
                        : summary.title,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : null,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary.content.length > 60
                        ? '${summary.content.substring(0, 60)}...'
                        : summary.content,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextMuted : null,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (summary.updatedAt != null)
              Text(
                _formatDate(summary.updatedAt!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkTextMuted : null,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor(int index) {
    const colors = [
      Color(0xFF6750A4),
      Color(0xFF006C46),
      Color(0xFFBA1A1A),
      Color(0xFFB54309),
      Color(0xFF0061A4),
      Color(0xFF7D5260),
      Color(0xFF4F6100),
      Color(0xFF685700),
    ];
    return colors[index % colors.length];
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
