import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/core/constants/app_theme.dart';
import 'package:local_vault/features/summary/domain/providers/summary_provider.dart';
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
  static const MethodChannel _channel = MethodChannel('com.ironion.local_vault/quick_action');

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    color: isDark 
                        ? AppColors.darkTextPrimary 
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: isDark 
                ? AppColors.darkTextPrimary 
                : Theme.of(context).colorScheme.onPrimaryContainer,
            onPressed: () async {
              try {
                await _channel.invokeMethod('finishActivity');
              } catch (e) {
                debugPrint('调用 finishActivity 失败: $e');
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
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
            onPressed: () async {
              // 尝试从剪贴板读取内容
            final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
            if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
                // 有剪贴板内容，直接保存到摘要
               Navigator.pop(context);
               context.push(AppRoutes.save, extra: clipboardData.text);
              } else {
                // 剪贴板为空，打开空白保存页面
               Navigator.pop(context);
               context.push(AppRoutes.save);
              }
            },
            icon: const Icon(Icons.save_alt),
            label: const Text('快速保存'),
           style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
             Navigator.pop(context);
             context.push(AppRoutes.save);
            },
            icon: const Icon(Icons.edit),
           label: const Text('手动输入'),
           style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
             backgroundColor: Colors.grey.shade200,
            ),
          ),
          const SizedBox(height: 16),
         const Text(
           '提示：会自动读取剪贴板内容快速保存\n如果没有内容，可以手动输入',
            textAlign: TextAlign.center,
           style: TextStyle(fontSize: 12, color: Colors.grey),
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

  void _copyToClipboard(String text) async {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
    // 延迟一点后调用原生端返回之前的应用
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      try {
        await _channel.invokeMethod('finishActivity');
      } catch (e) {
        debugPrint('调用 finishActivity 失败: $e');
        // 备用方案
        if (mounted) {
          Navigator.pop(context);
        }
      }
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Text(
          template.title,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkTextPrimary : null,
          ),
        ),
        subtitle: Text(
          template.content.length > 30
              ? '${template.content.substring(0, 30)}...'
              : template.content,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextMuted : null,
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Text(
          summary.title,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkTextPrimary : null,
          ),
        ),
        subtitle: Text(
          summary.content.length > 30
              ? '${summary.content.substring(0, 30)}...'
              : summary.content,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextMuted : null,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
