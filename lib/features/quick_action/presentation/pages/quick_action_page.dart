import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/features/summary/domain/providers/summary_provider.dart';
import 'package:local_vault/features/summary/presentation/widgets/summary_card.dart';
import 'package:local_vault/features/template/domain/providers/template_provider.dart';
import 'package:local_vault/features/template/models/template.dart';
import 'package:go_router/go_router.dart';

enum QuickActionType {
  templates,
  save,
  summaries,
}

class QuickActionPage extends ConsumerStatefulWidget {
  final QuickActionType actionType;

  const QuickActionPage({
    super.key,
    required this.actionType,
  });

  @override
  ConsumerState<QuickActionPage> createState() => _QuickActionPageState();
}

class _QuickActionPageState extends ConsumerState<QuickActionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final title = switch (widget.actionType) {
      QuickActionType.templates => '选择模板',
      QuickActionType.save => '保存摘要',
      QuickActionType.summaries => '我的摘要',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.actionType) {
      case QuickActionType.templates:
        return _buildTemplatesContent();
      case QuickActionType.save:
        return _buildSaveContent();
      case QuickActionType.summaries:
        return _buildSummariesContent();
    }
  }

  Widget _buildTemplatesContent() {
    final asyncTemplates = ref.watch(templateNotifierProvider);

    return asyncTemplates.when(
      data: (templates) {
        if (templates.isEmpty) {
          return const Center(child: Text('暂无模板'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            return _QuickTemplateCard(
              template: templates[index],
              onTap: () {
                _copyToClipboard(templates[index].content);
                Navigator.pop(context);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('错误: $error')),
    );
  }

  Widget _buildSaveContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.save);
            },
            icon: const Icon(Icons.add),
            label: const Text('打开保存页面'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '提示：可以先复制 AI 回复的内容，然后在此页面快速保存',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummariesContent() {
    final asyncSummaries = ref.watch(summaryNotifierProvider);

    return asyncSummaries.when(
      data: (summaries) {
        if (summaries.isEmpty) {
          return const Center(child: Text('暂无摘要'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: summaries.length,
          itemBuilder: (context, index) {
            return _QuickSummaryCard(
              summary: summaries[index],
              onTap: () {
                _copyToClipboard(summaries[index].content);
                Navigator.pop(context);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('错误: $error')),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }
}

class _QuickTemplateCard extends StatelessWidget {
  final Template template;
  final VoidCallback onTap;

  const _QuickTemplateCard({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Text(template.title, style: const TextStyle(fontSize: 14)),
        subtitle: Text(
          template.content.length > 30
              ? '${template.content.substring(0, 30)}...'
              : template.content,
          style: const TextStyle(fontSize: 12),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _QuickSummaryCard extends StatelessWidget {
  final dynamic summary;
  final VoidCallback onTap;

  const _QuickSummaryCard({
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Text(summary.title, style: const TextStyle(fontSize: 14)),
        subtitle: Text(
          summary.content.length > 30
              ? '${summary.content.substring(0, 30)}...'
              : summary.content,
          style: const TextStyle(fontSize: 12),
        ),
        onTap: onTap,
      ),
    );
  }
}
