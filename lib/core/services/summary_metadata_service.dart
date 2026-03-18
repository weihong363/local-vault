import 'package:flutter/foundation.dart';
import 'package:local_vault/core/services/app_settings_service.dart';
import 'package:local_vault/core/services/memory_slm_config.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
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
    required MemorySLMService slmService,
    required AppSettingsService settingsService,
  })  : _slmService = slmService,
        _settingsService = settingsService;

  final MemorySLMService _slmService;
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
    final useSlm = await _settingsService.isSlmSummaryMetadataEnabled();

    if (useSlm) {
      return _prepareWithSlm(
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
            title != SummaryTextUtils.unnamedTitle &&
            title.isNotEmpty
        ? title
        : derivedTitle;
    final resolvedTags = preserveManualMetadata && tags.isNotEmpty
        ? tags
        : SummaryTextUtils.sanitizeTags(
            derivedTags,
            fallbackTitle: resolvedTitle,
          );

    return PreparedSummaryDraft(
      title: resolvedTitle,
      content: fullContent,
      tags: resolvedTags,
      usedModel: false,
    );
  }

  Future<PreparedSummaryDraft> _prepareWithSlm({
    required String title,
    required List<String> tags,
    required String fullContent,
    required bool preserveManualMetadata,
  }) async {
    if (preserveManualMetadata &&
        title.isNotEmpty &&
        title != SummaryTextUtils.unnamedTitle &&
        tags.isNotEmpty) {
      return PreparedSummaryDraft(
        title: title,
        content: fullContent,
        tags: tags,
        usedModel: false,
      );
    }

    final response = await _slmService.generateSummaryMetadata(
      title: title == SummaryTextUtils.unnamedTitle ? '' : title,
      content: fullContent,
      tags: tags,
    );
    final fallbackTitle = await _resolveSlmFallbackTitle();

    final modelTitle = SummaryTextUtils.compressTitle(response.data.title);
    final resolvedTitle = preserveManualMetadata &&
            title.isNotEmpty &&
            title != SummaryTextUtils.unnamedTitle
        ? title
        : (modelTitle.isNotEmpty && modelTitle != SummaryTextUtils.unnamedTitle
            ? modelTitle
            : fallbackTitle);
    final resolvedTags = preserveManualMetadata && tags.isNotEmpty
        ? tags
        : SummaryTextUtils.sanitizeTags(
            response.data.tags,
            fallbackTitle:
                resolvedTitle == fallbackTitle ? null : resolvedTitle,
          );

    if (response.errorCode != null) {
      debugPrint(
        'ℹ️ [SummaryMetadataService] 大模型标题/标签生成未命中，使用最小回退结果：'
        '${response.errorCode}',
      );
    }

    return PreparedSummaryDraft(
      title: resolvedTitle,
      content: fullContent,
      tags: resolvedTags,
      usedModel: response.fallbackUsed == MemorySlmFallbackMode.none ||
          response.fallbackUsed == MemorySlmFallbackMode.cache,
    );
  }

  Future<String> _resolveSlmFallbackTitle() async {
    try {
      final config = await _slmService.resolveConfig();
      return config.fallbacks.summaryMetadataTitle;
    } catch (_) {
      return MemorySlmConfig.fallback.fallbacks.summaryMetadataTitle;
    }
  }

  String _mergeContentWithRemark(String content, String? remark) {
    final trimmedRemark = remark?.trim() ?? '';
    if (trimmedRemark.isEmpty) {
      return content;
    }
    return '$content\n\n---备注---\n$trimmedRemark';
  }
}
