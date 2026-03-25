import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_vault/core/domain/entities/template_entity.dart';
import 'package:local_vault/core/providers/template_entities_provider.dart';
import 'package:local_vault/core/widgets/common_template_card.dart';
import 'package:local_vault/l10n/app_localizations.dart';

class TemplatePage extends ConsumerWidget {
  const TemplatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final asyncTemplates = ref.watch(templateEntityNotifierProvider);

    ref.listen(templateEntityNotifierProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorWithDetails('${next.error}'))),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.templates),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showTemplateDialog(context, ref);
            },
          ),
        ],
      ),
      body: asyncTemplates.when(
        data: (templates) {
          if (templates.isEmpty) {
            return Center(child: Text(loc.noTemplatesYet));
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(templateEntityNotifierProvider.notifier).refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                return CommonTemplateCard(
                  template: templates[index],
                  onTap: () {
                    _copyToClipboard(context, templates[index].content);
                  },
                  onEdit: () {
                    _showTemplateDialog(context, ref,
                        template: templates[index]);
                  },
                  onDelete: () {
                    _confirmDeleteTemplate(
                      context,
                      ref,
                      templates[index],
                    );
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text(loc.errorWithDetails('$error'))),
      ),
    );
  }

  void _showTemplateDialog(BuildContext context, WidgetRef ref,
      {TemplateEntity? template}) {
    final loc = AppLocalizations.of(context)!;
    final isEditing = template != null;
    final titleController = TextEditingController(text: template?.title ?? '');
    final contentController =
        TextEditingController(text: template?.content ?? '');
    final tagsController =
        TextEditingController(text: template?.tags.join(', ') ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? loc.editTemplate : loc.addTemplate),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: loc.title,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: InputDecoration(
                  labelText: loc.content,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 6,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tagsController,
                decoration: InputDecoration(
                  labelText: loc.commaSeparatedTagsHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancelLabel),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final content = contentController.text.trim();
              final tags = tagsController.text
                  .split(',')
                  .map((tag) => tag.trim())
                  .where((tag) => tag.isNotEmpty)
                  .toList();

              if (title.isEmpty || content.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.titleAndContentRequired)),
                );
                return;
              }

              if (isEditing) {
                final updatedTemplate = template.copyWith(
                  title: title,
                  content: content,
                  tags: tags,
                );
                ref
                    .read(templateEntityNotifierProvider.notifier)
                    .updateTemplate(updatedTemplate);
              } else {
                final newTemplate = TemplateEntity.create(
                  title: title,
                  content: content,
                  tags: tags,
                );
                ref
                    .read(templateEntityNotifierProvider.notifier)
                    .addTemplate(newTemplate);
              }
              Navigator.pop(context);
            },
            child: Text(loc.save),
          ),
        ],
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

  Future<void> _confirmDeleteTemplate(
    BuildContext context,
    WidgetRef ref,
    TemplateEntity template,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteTemplate),
        content: Text(loc.deleteTemplateConfirm(template.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(loc.deleteLabel),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await ref
        .read(templateEntityNotifierProvider.notifier)
        .deleteTemplate(template.id);
    final deleteState = ref.read(templateEntityNotifierProvider);
    if (deleteState.hasError || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.templateDeleted)),
    );
  }
}
