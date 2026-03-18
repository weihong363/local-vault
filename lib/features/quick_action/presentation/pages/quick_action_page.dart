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
import 'package:local_vault/l10n/app_localizations.dart';

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
          final navigator = Navigator.of(context);
          try {
            await _channel.invokeMethod('finishActivity');
          } catch (e) {
            debugPrint('Failed to call finishActivity: $e');
            if (mounted) {
              navigator.pop();
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
    final loc = AppLocalizations.of(context)!;
    final title = switch (widget.actionType) {
      QuickActionType.templates => loc.chooseTemplate,
      QuickActionType.save => loc.saveSummaryQuickActionTitle,
      QuickActionType.summaries => loc.myMemories,
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
              final navigator = Navigator.of(context);
              try {
                await _channel.invokeMethod('finishActivity');
              } catch (e) {
                debugPrint('Failed to call finishActivity: $e');
                if (mounted) {
                  navigator.pop();
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
    final loc = AppLocalizations.of(context)!;
    final asyncTemplates = ref.watch(templateEntityNotifierProvider);

    return asyncTemplates.when(
      data: (templates) {
        if (templates.isEmpty) {
          return Center(child: Text(loc.noTemplatesYet));
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
      error: (error, stack) => Center(
        child: Text(loc.errorWithDetails('$error')),
      ),
    );
  }

  Widget _buildSaveContent() {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final router = GoRouter.of(context);
              // Try to load text from the clipboard first.
              final clipboardData =
                  await Clipboard.getData(Clipboard.kTextPlain);
              if (!mounted) return;
              if (clipboardData?.text != null &&
                  clipboardData!.text!.isNotEmpty) {
                // Save directly when clipboard text is available.
                navigator.pop();
                router.push(AppRoutes.save, extra: clipboardData.text);
              } else {
                // Open an empty save page when the clipboard is empty.
                navigator.pop();
                router.push(AppRoutes.save);
              }
            },
            icon: const Icon(Icons.save_alt),
            label: Text(loc.quickSave),
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
            label: Text(loc.manualInput),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Colors.grey.shade200,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loc.quickSaveClipboardTip,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSummariesContent() {
    final loc = AppLocalizations.of(context)!;
    final asyncSummaries = ref.watch(summaryEntityNotifierProvider);

    return asyncSummaries.when(
      data: (summaries) {
        if (summaries.isEmpty) {
          return Center(child: Text(loc.noSummariesYet));
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
      error: (error, stack) => Center(
        child: Text(loc.errorWithDetails('$error')),
      ),
    );
  }

  void _copyToClipboard(String text, {String? summaryId}) async {
    debugPrint('Start copying, summaryId: $summaryId');
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Copy to the clipboard first.
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    messenger.showSnackBar(
      SnackBar(content: Text(loc.copiedToClipboard)),
    );

    // Record access when a summary ID is provided.
    if (summaryId != null) {
      try {
        debugPrint('Recording access count...');
        await ref
            .read(summaryEntityNotifierProvider.notifier)
            .recordAccess(summaryId);
        debugPrint('Access count recorded');
      } catch (e) {
        debugPrint('Failed to record access count: $e');
      }
    }

    // Wait briefly, then close.
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      debugPrint('Closing activity...');
      if (widget.onFinish != null) {
        widget.onFinish!();
      } else {
        try {
          await _channel.invokeMethod('finishActivity');
        } catch (e) {
          debugPrint('Failed to call finishActivity: $e');
          // Fallback for embedded navigation.
          if (mounted) {
            navigator.pop();
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
