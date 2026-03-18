import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_vault/core/constants/app_theme.dart';
import 'package:local_vault/core/services/share_sheet.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';

class InjectPage extends StatelessWidget {
  const InjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('内容注入'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InjectItem(
            summary: SummaryEntity.create(
              title: '示例摘要 1',
              content: '这是通过本地记忆库保存的示例内容，可以在其他应用中快速注入使用。',
              tags: ['示例', '测试'],
              source: 'manual',
            ),
          ),
          InjectItem(
            summary: SummaryEntity.create(
              title: '示例摘要 2',
              content: '另一个示例内容，展示如何在不同应用之间共享重要信息。',
              tags: ['示例', '分享'],
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
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
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
