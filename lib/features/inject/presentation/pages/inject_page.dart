import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_vault/core/constants/app_theme.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/services/share_sheet.dart';
import 'package:local_vault/l10n/app_localizations.dart';

class InjectPage extends StatelessWidget {
  const InjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.inject),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InjectItem(
            summary: SummaryEntity.create(
              title: 'Sample summary 1',
              content:
                  'This sample was saved in Local Vault and can be injected into other apps for quick reuse.',
              tags: ['sample', 'test'],
              source: 'manual',
            ),
          ),
          InjectItem(
            summary: SummaryEntity.create(
              title: 'Sample summary 2',
              content:
                  'Another example that shows how to share important information across different apps.',
              tags: ['sample', 'share'],
              source: 'manual',
            ),
          ),
        ],
      ),
    );
  }
}

class InjectItem extends StatelessWidget {
  final SummaryEntity summary;

  const InjectItem({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.content_paste,
            color: AppColors.primary,
          ),
        ),
        title: Text(summary.title),
        subtitle: Text(
          summary.content.length > 50
              ? '${summary.content.substring(0, 50)}...'
              : summary.content,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () => _copyToClipboard(context, summary.content),
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareSummary(context, summary),
            ),
          ],
        ),
        onTap: () => _copyToClipboard(context, summary.content),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    final loc = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.copiedToClipboard)),
    );
  }

  void _shareSummary(BuildContext context, SummaryEntity summary) {
    ShareSheet.share(
      context,
      summary.content,
      subject: summary.title,
    );
  }
}
