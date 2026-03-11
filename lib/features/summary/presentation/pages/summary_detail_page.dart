import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:local_vault/core/constants/app_theme.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/providers/summary_entities_provider.dart';

class SummaryDetailPage extends ConsumerStatefulWidget {
  final SummaryEntity summary;

  const SummaryDetailPage({super.key, required this.summary});

  @override
  ConsumerState<SummaryDetailPage> createState() => _SummaryDetailPageState();
}

class _SummaryDetailPageState extends ConsumerState<SummaryDetailPage> {
  bool _isExpanded = false;
  static const int _maxPreviewLength = 500;

  @override
  void initState() {
    super.initState();
    _recordAccess();
  }

  Future<void> _recordAccess() async {
    await ref.read(summaryEntityNotifierProvider.notifier).recordAccess(widget.summary.id);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.summary.title,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : null,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push(
                AppRoutes.save,
                extra: widget.summary,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copyToClipboard(context, widget.summary.content),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareSummary(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.summary.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : null,
                    ),
              ),
              const SizedBox(height: 16),
              _buildContent(context, isDark),
              const SizedBox(height: 24),
              if (widget.summary.tags.isNotEmpty) ...[
                Text(
                  '标签:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : null,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: widget.summary.tags.map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextPrimary : null,
                        ),
                      ),
                      backgroundColor: AppColors.surfaceVariant(context),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    final content = widget.summary.content;
    final shouldShowExpandButton = content.length > _maxPreviewLength;

    if (!shouldShowExpandButton || _isExpanded) {
      return Text(
        content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isDark ? AppColors.darkTextPrimary : null,
            ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${content.substring(0, _maxPreviewLength)}...',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark ? AppColors.darkTextPrimary : null,
              ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            setState(() {
              _isExpanded = true;
            });
          },
          child: const Text('展开全部'),
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }

  void _shareSummary(BuildContext context) {
    Share.share(
      widget.summary.content,
      subject: widget.summary.title,
    );
  }
}
