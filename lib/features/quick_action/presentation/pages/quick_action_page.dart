import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/core/constants/app_theme.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/entities/template_entity.dart';
import 'package:local_vault/core/providers/summary_entities_provider.dart';
import 'package:local_vault/core/providers/template_entities_provider.dart';
import 'package:local_vault/core/widgets/common_template_card.dart';
import 'package:local_vault/features/quick_action/models/quick_action_type.dart';

class QuickActionPage extends ConsumerStatefulWidget {
  final QuickActionType actionType;
  final VoidCallback? onFinish;

  const QuickActionPage({
    super.key,
    required this.actionType,
    this.onFinish,
  });

  @override
  ConsumerState<QuickActionPage> createState() => _QuickActionPageState();
}

class _QuickActionPageState extends ConsumerState<QuickActionPage> {
  static const MethodChannel _channel =
      MethodChannel('com.ironion.localvault/quick_action');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () async {
          try {
            await _channel.invokeMethod('finishActivity');
          } catch (e) {
            debugPrint('调用 finishActivity 失败: $e');
            if (mounted) {
              Navigator.pop(context);
            }
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return Container(
                  constraints:
                      const BoxConstraints(maxWidth: 400, maxHeight: 500),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      Expanded(child: _buildContent()),
                    ],
                  ),
                );
              },
            ),
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
    final asyncTemplates = ref.watch(templateEntityNotifierProvider);

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
              final clipboardData =
                  await Clipboard.getData(Clipboard.kTextPlain);
              if (clipboardData?.text != null &&
                  clipboardData!.text!.isNotEmpty) {
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
    final asyncSummaries = ref.watch(summaryEntityNotifierProvider);

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
                _copyToClipboard(summaries[index].content,
                    summaryId: summaries[index].id);
              },
              index: index,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('错误: $error')),
    );
  }

  void _copyToClipboard(String text, {String? summaryId}) async {
    debugPrint('开始复制，summaryId: $summaryId');

    // 首先复制到剪贴板
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );

    // 如果是摘要，记录访问次数
    if (summaryId != null) {
      try {
        debugPrint('正在记录访问次数...');
        await ref
            .read(summaryEntityNotifierProvider.notifier)
            .recordAccess(summaryId);
        debugPrint('访问次数记录完成');
      } catch (e) {
        debugPrint('记录访问次数失败: $e');
      }
    }

    // 稍延迟一小会儿，然后关闭
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      debugPrint('正在关闭 Activity...');
      if (widget.onFinish != null) {
        widget.onFinish!();
      } else {
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
}

class _QuickTemplateCard extends StatelessWidget {
  final TemplateEntity template;
  final VoidCallback onTap;

  const _QuickTemplateCard({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CommonTemplateCard(
      template: template,
      onTap: onTap,
      showActions: false,
    );
  }
}

class _QuickSummaryCard extends StatelessWidget {
  final SummaryEntity summary;
  final VoidCallback onTap;
  final int index;

  const _QuickSummaryCard({
    required this.summary,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  summary.title.length > 20
                      ? '${summary.title.substring(0, 20)}...'
                      : summary.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextPrimary : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  summary.content.length > 50
                      ? '${summary.content.substring(0, 50)}...'
                      : summary.content,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
