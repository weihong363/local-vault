import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/core/constants/app_theme.dart';
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/entities/summary_merge_models.dart';
import 'package:local_vault/core/providers/summary_entities_provider.dart';
import 'package:local_vault/core/services/app_settings_service.dart';
import 'package:local_vault/core/services/ocr_service.dart';
import 'package:local_vault/core/services/summary_metadata_service.dart';
import 'package:local_vault/features/memory/presentation/pages/memory_merge_diff_page.dart';
import 'package:local_vault/l10n/app_localizations.dart';

class SavePage extends ConsumerStatefulWidget {
  final dynamic
      initialData; // Can be a String, a Map (image share), or SummaryEntity (editing).
  final SummaryEntity? editingSummary; // Summary currently being edited.

  const SavePage({super.key, this.initialData, this.editingSummary});

  @override
  ConsumerState<SavePage> createState() => _SavePageState();
}

class _SavePageState extends ConsumerState<SavePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  String _source = 'manual';
  bool _hasInitializedShareText = false;
  bool _isSaving = false; // Prevent duplicate save attempts.
  bool _isProcessingOcr = false; // OCR request is in progress.
  bool _previewEnabled = false;
  bool _isGeneratingPreview = false;
  PreparedSummaryDraft? _previewDraft;
  String? _previewError;
  Timer? _previewDebounce;
  int _previewGeneration = 0;
  String? _lastPreviewSignature;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onPreviewInputChanged);
    _contentController.addListener(_onPreviewInputChanged);
    _tagsController.addListener(_onPreviewInputChanged);
    _remarkController.addListener(_onPreviewInputChanged);
    _loadPreviewPreference();

    // Check edit mode first.
    if (widget.editingSummary != null) {
      _initEditMode();
      return;
    }

    // Wait until the first frame so ModalRoute is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Route arguments have higher priority.
      await _checkRouteArguments();

      // Do not fall back to MethodChannel here because ShareService
      // already centralizes that flow in main.dart.
      if (!_hasInitializedShareText) {
        debugPrint(
          '⚠️ [SavePage] No shared text was found in route arguments. Check ShareService if this is unexpected.',
        );
      }
    });
  }

  /// Initialize the form for editing.
  void _initEditMode() {
    final summary = widget.editingSummary!;
    debugPrint('✏️ [SavePage] Edit mode: ${summary.title}');

    _titleController.text = summary.title;
    _contentController.text = summary.content;
    _tagsController.text = summary.tags.join(', ');
    _source = summary.source;
    _hasInitializedShareText = true;
  }

  /// Check route arguments before any legacy fallback path.
  Future<bool> _checkRouteArguments() async {
    try {
      // Give ModalRoute a moment to finish setup.
      await Future.delayed(const Duration(milliseconds: 10));

      if (!mounted) return false;

      // Check constructor-provided data first (GoRouter extra).
      if (widget.initialData != null) {
        // Shared text.
        if (widget.initialData is String && widget.initialData!.isNotEmpty) {
          final text = widget.initialData as String;
          debugPrint(
            '✅ [SavePage] Shared text loaded from GoRouter extra: '
            '${text.substring(0, math.min(50, text.length))}...',
          );
          setState(() {
            _contentController.text = text;
            _source = 'share';
            _hasInitializedShareText = true;
          });
          return true;
        }

        // Shared image(s).
        if (widget.initialData is Map) {
          final data = widget.initialData as Map;
          final type = data['type'] as String?;
          final uris = data['uris'] as List<dynamic>?;

          if (type == 'image' && uris != null && uris.isNotEmpty) {
            debugPrint(
              '🖼️ [SavePage] Shared image detected. Starting OCR recognition...',
            );
            await _processImageOcr(uris.map((u) => u as String).toList());
            return true;
          }
        }
      }

      // Fall back to ModalRoute arguments for legacy flows.
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.isNotEmpty) {
        debugPrint(
          '✅ [SavePage] Shared text loaded from ModalRoute: '
          '${args.substring(0, math.min(50, args.length))}...',
        );
        setState(() {
          _contentController.text = args;
          _source = 'share';
          _hasInitializedShareText = true;
        });
        return true;
      }

      debugPrint(
        '⚠️ [SavePage] No shared text found. Both initialData and ModalRoute arguments were empty.',
      );
      return false;
    } catch (e) {
      debugPrint('❌ [SavePage] Failed to read route arguments: $e');
      return false;
    }
  }

  /// Run OCR on shared image URIs.
  Future<void> _processImageOcr(List<String> uris) async {
    final loc = AppLocalizations.of(context)!;
    if (_isProcessingOcr) return;

    setState(() {
      _isProcessingOcr = true;
      _source = 'share_ocr';
    });

    try {
      debugPrint(
        '🔍 [SavePage] Starting OCR recognition for ${uris.length} image(s)',
      );

      final ocrService = OcrService();
      OcrResult result;

      if (uris.length == 1) {
        result = await ocrService.recognizeTextFromUri(uris.first);
      } else {
        result = await ocrService.recognizeTextFromUris(uris);
      }

      if (result.success && result.text.isNotEmpty) {
        debugPrint(
          '✅ [SavePage] OCR succeeded and produced ${result.text.length} characters',
        );
        setState(() {
          _contentController.text = result.text;
          _titleController.text =
              '${loc.ocrRecognitionTitlePrefix} - ${DateTime.now().toString().substring(0, 16)}';
          _hasInitializedShareText = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(loc.ocrRecognizedCharacters('${result.text.length}')),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint('⚠️ [SavePage] OCR failed: ${result.error}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.ocrFailedMessage(
                        _localizeOcrError(loc, result.error),
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [SavePage] OCR processing error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(loc.ocrProcessingFailedMessage(e.toString())),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingOcr = false;
        });
      }
    }
  }

  String _localizeOcrError(AppLocalizations loc, String? error) {
    if (error == null || error.isEmpty) {
      return loc.unknownError;
    }
    if (error == OcrService.imageFileReadError) {
      return loc.unableToReadImageFile;
    }
    return error;
  }

  // _loadShareTextFromChannel was removed.
  // ShareService in main.dart now handles this flow centrally.

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _titleController.removeListener(_onPreviewInputChanged);
    _contentController.removeListener(_onPreviewInputChanged);
    _tagsController.removeListener(_onPreviewInputChanged);
    _remarkController.removeListener(_onPreviewInputChanged);
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _remarkController.dispose(); // Dispose the remark controller as well.
    super.dispose();
  }

  Future<void> _loadPreviewPreference() async {
    final previewEnabled =
        await sl<AppSettingsService>().isSummaryMetadataPreviewEnabled();
    if (!mounted) {
      return;
    }
    setState(() {
      _previewEnabled = previewEnabled;
    });
    if (previewEnabled) {
      _schedulePreviewRefresh();
    }
  }

  void _onPreviewInputChanged() {
    _lastPreviewSignature = null;
    if (!_previewEnabled) {
      return;
    }
    _schedulePreviewRefresh();
  }

  void _schedulePreviewRefresh() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _generatePreview(),
    );
  }

  Future<void> _togglePreview(bool value) async {
    await sl<AppSettingsService>().setSummaryMetadataPreviewEnabled(value);
    if (!mounted) {
      return;
    }

    setState(() {
      _previewEnabled = value;
      if (!value) {
        _previewDraft = null;
        _previewError = null;
        _isGeneratingPreview = false;
      }
    });

    if (value) {
      _schedulePreviewRefresh();
    } else {
      _previewDebounce?.cancel();
    }
  }

  Future<void> _generatePreview({bool force = false}) async {
    final loc = AppLocalizations.of(context)!;
    final content = _contentController.text.trim();
    final signature = _buildPreviewSignature();
    if (!force &&
        _lastPreviewSignature == signature &&
        (_previewDraft != null || _previewError != null)) {
      return;
    }

    if (content.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _previewDraft = null;
        _previewError = loc.previewEnterContent;
        _isGeneratingPreview = false;
      });
      return;
    }

    final generation = ++_previewGeneration;
    if (mounted) {
      setState(() {
        _isGeneratingPreview = true;
        _previewError = null;
      });
    }

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
      final draft = await sl<SummaryMetadataService>().preparePreview(
        title: _titleController.text.trim(),
        content: content,
        tags: tags,
        remark: _remarkController.text.trim(),
      );

      if (!mounted || generation != _previewGeneration) {
        return;
      }

      setState(() {
        _previewDraft = draft;
        _previewError = null;
        _isGeneratingPreview = false;
        _lastPreviewSignature = signature;
      });
    } catch (e) {
      if (!mounted || generation != _previewGeneration) {
        return;
      }
      setState(() {
        _previewDraft = null;
        _previewError = loc.previewGenerationFailed('$e');
        _isGeneratingPreview = false;
      });
    }
  }

  void _applyPreviewToForm() {
    final loc = AppLocalizations.of(context)!;
    final draft = _previewDraft;
    if (draft == null) {
      return;
    }

    setState(() {
      _titleController.text = draft.title;
      _tagsController.text = draft.tags.join(', ');
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.previewApplied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _buildPreviewSignature() {
    return [
      _titleController.text.trim(),
      _contentController.text.trim(),
      _remarkController.text.trim(),
      _tagsController.text.trim(),
      _previewEnabled.toString(),
    ].join('::');
  }

  Future<void> _saveSummary() async {
    final loc = AppLocalizations.of(context)!;
    // Ignore repeated taps while saving.
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      final remark = _remarkController.text.trim();
      final inputTags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      if (content.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.contentRequiredMessage),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final prepared = await sl<SummaryMetadataService>().prepareForSave(
        title: title,
        content: content,
        tags: inputTags,
        remark: remark,
      );
      final finalTitle = prepared.title;
      final fullContent = prepared.content;
      final tags = prepared.tags;

      if (title.isEmpty) {
        _titleController.text = finalTitle;
      }
      if (inputTags.isEmpty && tags.isNotEmpty) {
        _tagsController.text = tags.join(', ');
      }

      var successMessage =
          widget.editingSummary != null ? loc.summaryUpdated : loc.savedToVault;

      // Choose between edit and create flows.
      if (widget.editingSummary != null) {
        // Edit flow.
        final updatedSummary = widget.editingSummary!.copyWith(
          title: finalTitle,
          content: fullContent,
          tags: tags,
          updatedAt: DateTime.now(),
        );

        debugPrint('✏️ [SavePage] Updating summary: ${updatedSummary.title}');
        await ref
            .read(summaryEntityNotifierProvider.notifier)
            .updateSummary(updatedSummary);
        debugPrint('✅ [SavePage] Update succeeded');
      } else {
        // Create flow.
        final summary = SummaryEntity.create(
          title: finalTitle,
          content: fullContent,
          tags: tags,
          source: _source,
        );

        debugPrint('💾 [SavePage] Preparing to save summary: ${summary.title}');
        final result = await ref
            .read(summaryEntityNotifierProvider.notifier)
            .addFactSummary(summary);
        debugPrint('✅ [SavePage] Save succeeded');

        if (result.wasExactDuplicate) {
          successMessage = loc.duplicateFactMemoryUpdated;
        } else if (result.hasMergeSuggestions && mounted) {
          final candidate = await _showMergeCandidatePicker(result);
          if (!mounted) {
            return;
          }
          if (candidate != null) {
            final merged = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => MemoryMergeDiffPage(
                  primarySummary: candidate.summary,
                  secondarySummary: result.savedSummary,
                  primaryLabel: loc.existingFactMemory,
                  secondaryLabel: loc.newFactMemory,
                  similarity: candidate.similarity,
                ),
              ),
            );
            if (merged == true) {
              successMessage = loc.savedAndMergedFactMemories;
            }
          }
        }
      }

      if (mounted) {
        // Navigate to the home page instead of popping directly.
        context.go(AppRoutes.home);

        // Show a success message after navigation.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(successMessage),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [SavePage] Save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(loc.saveFailedMessage(e.toString()))),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<SummaryMergeCandidate?> _showMergeCandidatePicker(
    FactSummarySaveResult result,
  ) {
    final loc = AppLocalizations.of(context)!;
    return showDialog<SummaryMergeCandidate>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.mergeCandidatesFound),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.mergeCandidatesFoundDescription(result.savedSummary.title),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 280,
                child: SingleChildScrollView(
                  child: Column(
                    children: result.mergeCandidates
                        .map(
                          (candidate) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(candidate.summary.title),
                            subtitle: Text(
                              loc.similarityWithContent(
                                '${(candidate.similarity * 100).toStringAsFixed(1)}%',
                                candidate.summary.content,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).pop(candidate),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.laterLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editingSummary != null ? loc.editSummary : loc.saveContent,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : null,
          ),
        ),
        elevation: 0,
        actions: [
          // Show a badge when content came from a share action.
          Builder(
            builder: (context) {
              final hasShareText =
                  _source == 'share' && _contentController.text.isNotEmpty;
              if (hasShareText) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: isDark ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                            Colors.green.withValues(alpha: isDark ? 0.5 : 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.share, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        loc.sharedBadge,
                        style: TextStyle(
                          color: isDark
                              ? Colors.green.shade400
                              : Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Title field.
          TextField(
            controller: _titleController,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : null,
            ),
            decoration: InputDecoration(
              labelText: '${loc.title} *',
              hintText: loc.enterTitleHint,
              hintStyle: TextStyle(
                color: isDark ? AppColors.darkTextMuted : Colors.grey.shade400,
              ),
              labelStyle: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : null,
              ),
              prefixIcon: Icon(Icons.title,
                  color: isDark ? AppColors.primary : Colors.blue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.primary : Colors.blue.shade300,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor:
                  isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
            ),
          ),

          const SizedBox(height: 20),

          // Content field.
          TextField(
            controller: _contentController,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : null,
            ),
            decoration: InputDecoration(
              labelText: '${loc.content} *',
              hintText: loc.contentShareHint,
              hintStyle: TextStyle(
                color: isDark ? AppColors.darkTextMuted : Colors.grey.shade400,
              ),
              labelStyle: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : null,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Icon(Icons.notes,
                    color: isDark ? AppColors.primary : Colors.blue),
              ),
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.primary : Colors.blue.shade300,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor:
                  isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
            ),
            maxLines: 8,
            minLines: 5,
          ),

          const SizedBox(height: 20),

          // Remark field.
          TextField(
            controller: _remarkController,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : null,
            ),
            decoration: InputDecoration(
              labelText: loc.remarkLabel,
              hintText: loc.remarkHint,
              hintStyle: TextStyle(
                color: isDark ? AppColors.darkTextMuted : Colors.grey.shade400,
              ),
              labelStyle: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : null,
              ),
              prefixIcon: Icon(Icons.comment,
                  color: isDark ? Colors.orange.shade400 : Colors.orange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      isDark ? Colors.orange.shade400 : Colors.orange.shade300,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor:
                  isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
            ),
            maxLines: 4,
            minLines: 2,
          ),

          const SizedBox(height: 20),

          // Tags field.
          TextField(
            controller: _tagsController,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : null,
            ),
            decoration: InputDecoration(
              labelText: loc.tags,
              hintText: loc.tagsHint,
              hintStyle: TextStyle(
                color: isDark ? AppColors.darkTextMuted : Colors.grey.shade400,
              ),
              labelStyle: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : null,
              ),
              prefixIcon: Icon(Icons.local_offer,
                  color: isDark ? Colors.purple.shade400 : Colors.purple),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      isDark ? Colors.purple.shade400 : Colors.purple.shade300,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor:
                  isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
            ),
          ),

          const SizedBox(height: 16),

          SwitchListTile.adaptive(
            value: _previewEnabled,
            onChanged: _togglePreview,
            contentPadding: EdgeInsets.zero,
            title: Text(loc.previewSuggestedTitleTags),
            subtitle: Text(loc.previewSuggestedTitleTagsDescription),
          ),

          if (_previewEnabled) ...[
            const SizedBox(height: 12),
            _buildPreviewCard(isDark),
          ],

          const SizedBox(height: 32),

          // Save button.
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveSummary,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save_alt, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          widget.editingSummary != null
                              ? loc.updateSummary
                              : loc.saveToVault,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Required-field hint.
          Center(
            child: Text(
              loc.requiredFieldHint,
              style: TextStyle(
                color: isDark ? AppColors.darkTextMuted : Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(bool isDark) {
    final loc = AppLocalizations.of(context)!;
    final previewDraft = _previewDraft;
    final previewError = _previewError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceVariant.withValues(alpha: 0.85)
            : Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.35)
              : Colors.blueGrey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 18,
                color: isDark ? AppColors.primary : Colors.blueGrey.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.saveResultPreview,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _isGeneratingPreview
                    ? null
                    : () => _generatePreview(force: true),
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(loc.refresh),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            loc.previewPrimaryDescription,
            style: TextStyle(
              fontSize: 12,
              color:
                  isDark ? AppColors.darkTextMuted : Colors.blueGrey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          if (_isGeneratingPreview)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (previewError != null)
            Text(
              previewError,
              style: TextStyle(
                color: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
              ),
            )
          else if (previewDraft != null) ...[
            _buildPreviewField(
              label: loc.suggestedTitle,
              value: previewDraft.title,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            Text(
              loc.suggestedTags,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.darkTextMuted : Colors.blueGrey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: previewDraft.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: _applyPreviewToForm,
                  icon: const Icon(Icons.auto_fix_high_outlined),
                  label: Text(loc.applyToForm),
                ),
                const SizedBox(width: 12),
                Text(
                  previewDraft.usedModel
                      ? loc.generatedByBuiltInModel
                      : loc.generatedByLocalRules,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : Colors.blueGrey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewField({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextMuted : Colors.blueGrey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color:
                isDark ? AppColors.darkTextPrimary : Colors.blueGrey.shade900,
          ),
        ),
      ],
    );
  }
}
