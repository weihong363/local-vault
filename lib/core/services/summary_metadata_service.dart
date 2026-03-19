import 'package:flutter/foundation.dart';
import 'package:local_vault/core/services/app_settings_service.dart';
import 'package:local_vault/core/utils/summary_text_utils.dart';

class PreparedSummaryDraft {
  const PreparedSummaryDraft({
    required this.title,
    required this.content,
    required this.tags,
    required this.usedModel,
  });

  final String title;
  final String content;
  final List<String> tags;
  final bool usedModel;
}

class SummaryMetadataService {
  SummaryMetadataService({
    required AppSettingsService settingsService,
  }) : _settingsService = settingsService;

  final AppSettingsService _settingsService;

  Future<PreparedSummaryDraft> prepareForSave({
    required String content,
    String title = '',
    List<String> tags = const [],
    String? remark,
  }) async {
    return _prepareDraft(
      content: content,
      title: title,
      tags: tags,
      remark: remark,
      preserveManualMetadata: true,
    );
  }

  Future<PreparedSummaryDraft> preparePreview({
    required String content,
    String title = '',
    List<String> tags = const [],
    String? remark,
  }) async {
    return _prepareDraft(
      content: content,
      title: title,
      tags: tags,
      remark: remark,
      preserveManualMetadata: false,
    );
  }

  Future<PreparedSummaryDraft> _prepareDraft({
    required String content,
    required String title,
    required List<String> tags,
    required String? remark,
    required bool preserveManualMetadata,
  }) async {
    final normalizedContent = content.trim();
    final mergedContent = _mergeContentWithRemark(normalizedContent, remark);
    final normalizedTitle = SummaryTextUtils.compressTitle(title);
    final normalizedTags = SummaryTextUtils.sanitizeTags(tags);
    final slmInferenceEnabled = await _settingsService.isSlmInferenceEnabled();

    if (slmInferenceEnabled) {
      return _prepareWithSlmInferenceEntry(
        title: normalizedTitle,
        tags: normalizedTags,
        fullContent: mergedContent,
        preserveManualMetadata: preserveManualMetadata,
      );
    }

    return _prepareWithRules(
      title: normalizedTitle,
      tags: normalizedTags,
      fullContent: mergedContent,
      preserveManualMetadata: preserveManualMetadata,
    );
  }

  PreparedSummaryDraft _prepareWithRules({
    required String title,
    required List<String> tags,
    required String fullContent,
    required bool preserveManualMetadata,
  }) {
    final derivedTitle = SummaryTextUtils.generateTitle(fullContent);
    final derivedTags =
        SummaryTextUtils.generateTags(derivedTitle, fullContent);
    final resolvedTitle = preserveManualMetadata &&
            !SummaryTextUtils.isUnnamedTitleValue(title) &&
            title.isNotEmpty
        ? title
        : derivedTitle;
    final resolvedTags = preserveManualMetadata && tags.isNotEmpty
        ? tags
        : SummaryTextUtils.sanitizeTags(
            derivedTags,
            fallbackTitle: SummaryTextUtils.isUnnamedTitleValue(resolvedTitle)
                ? null
                : resolvedTitle,
          );

    return PreparedSummaryDraft(
      title: resolvedTitle,
      content: fullContent,
      tags: resolvedTags,
      usedModel: false,
    );
  }

  Future<PreparedSummaryDraft> _prepareWithSlmInferenceEntry({
    required String title,
    required List<String> tags,
    required String fullContent,
    required bool preserveManualMetadata,
  }) async {
    debugPrint(
      'ℹ️ [SummaryMetadataService] SLM inference is enabled, but no summary-metadata inference provider is currently integrated; continuing with rule-based results.',
    );

    return _prepareWithRules(
      title: title,
      tags: tags,
      fullContent: fullContent,
      preserveManualMetadata: preserveManualMetadata,
    );
  }

  String _mergeContentWithRemark(String content, String? remark) {
    final trimmedRemark = remark?.trim() ?? '';
    if (trimmedRemark.isEmpty) {
      return content;
    }
    return '$content\n\n---Remark---\n$trimmedRemark';
  }
}
