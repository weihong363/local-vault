import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:local_vault/core/config/memory_policy_config.dart';
import 'package:local_vault/core/domain/entities/memory_promotion_metadata.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/entities/summary_merge_models.dart';
import 'package:local_vault/core/domain/repositories/memory_promotion_repository_interface.dart';
import 'package:local_vault/core/domain/repositories/summary_repository_interface.dart';
import 'package:local_vault/core/memory_promotion/memory_promotion.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';
import 'package:local_vault/core/memory_runtime/interfaces/memory_runtime_interfaces.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
import 'package:local_vault/core/utils/memory_title_generator.dart';
import 'package:local_vault/core/utils/similarity_utils.dart';
import 'package:local_vault/core/utils/summary_text_utils.dart';

/// Summary business use cases
class SummaryUseCases {
  SummaryUseCases(
    this.repository,
    this.slmService, {
    this.policyConfig = MemoryPolicyConfig.defaults,
    this.memoryCapability,
    this.promotionRepository,
    this.merger,
  });

  final SummaryRepositoryInterface repository;
  final MemorySLMService slmService;
  final MemoryPolicyConfig policyConfig;
  final MemoryCapability? memoryCapability;
  final MemoryPromotionRepositoryInterface? promotionRepository;
  final MemoryMerger? merger;

  /// Add summary
  Future<void> addSummary(SummaryEntity summary) async {
    debugPrint(
      '💾 [SummaryUseCases.addSummary] Before enhance: title="${summary.title}", topic="${summary.topic}"',
    );

    final enhancedSummary = _enhanceWithStructuredTitle(summary);
    await repository.addSummary(enhancedSummary);
    if (enhancedSummary.type == MemoryType.fact) {
      await _upgradeFactToCoreIfNeeded(enhancedSummary.id);
    }
    _scheduleMemoryCompaction();
  }

  /// Optimize title and topic using structured title generator
  SummaryEntity _enhanceWithStructuredTitle(SummaryEntity summary) {
    // ✅ Key fix: If title is "Untitled", do not pass rawContent to avoid pollution
    final rawContent = SummaryTextUtils.isUnnamedTitleValue(summary.title)
        ? summary.content
        : '${summary.title} ${summary.content}'.trim();

    debugPrint(
      '🔍 [_enhanceWithStructuredTitle] Input: title="${summary.title}", content length=${summary.content.length}, rawContent length=$rawContent',
    );

    if (rawContent.isEmpty) {
      debugPrint(
          '⚠️ [_enhanceWithStructuredTitle] Raw content is empty, returning original summary');
      return summary;
    }

    final titleResult =
        StructuredMemoryTitleGenerator.generateTitle(rawContent);
    debugPrint(
      '📊 [_enhanceWithStructuredTitle] Generated: title="${titleResult.title}", topic="${titleResult.structuredData.topic}", confidence=${titleResult.confidence}',
    );

    if (titleResult.confidence >= 0.5 && titleResult.title.isNotEmpty) {
      // ✅ Check if topic is a placeholder (e.g., Untitled, unnamed, etc.)
      final extractedTopic = titleResult.structuredData.topic ?? '';
      final isValidTopic = _isValidSemanticTopic(extractedTopic);

      debugPrint(
        '📝 [StructuredTitle] Generated title: ${titleResult.title} '
        '(confidence: ${(titleResult.confidence * 100).toStringAsFixed(1)}%)',
      );
      debugPrint(
        '🏷️ [StructuredTitle] Extracted topic: "$extractedTopic" '
        '(valid: $isValidTopic)',
      );

      // ✅ If topic is a placeholder, try to regenerate a better title
      String finalTitle;
      String? finalTopic;

      if (!isValidTopic) {
        // Topic is a placeholder, try to extract more meaningful keywords from content
        final bestKeyword = _extractBestKeywordFromContent(summary.content);
        if (bestKeyword != null && bestKeyword.isNotEmpty) {
          finalTitle =
              '$bestKeyword:${titleResult.title.split(':').last.trim()}';
          finalTopic = bestKeyword;
          debugPrint(
            '♻️ [StructuredTitle] Regenerated with keyword: title="$finalTitle", topic="$finalTopic"',
          );
        } else {
          // ⚠️ Cannot extract keyword, use SummaryTextUtils as final fallback
          final fallbackTitle = SummaryTextUtils.generateTitle(summary.content);
          if (!SummaryTextUtils.isUnnamedTitleValue(fallbackTitle)) {
            finalTitle = fallbackTitle;
            finalTopic = null;
            debugPrint(
              '🔄 [StructuredTitle] Fallback to SummaryTextUtils: title="$finalTitle"',
            );
          } else {
            // All methods failed, keep original title but clear topic
            finalTitle = titleResult.title;
            finalTopic = null;
            debugPrint(
              '⚠️ [StructuredTitle] All title generation failed, keeping original with empty topic',
            );
          }
        }
      } else {
        // Topic is valid, use directly
        finalTitle = titleResult.title;
        finalTopic = extractedTopic;
      }

      final enhanced = summary.copyWith(
        title: finalTitle,
        topic: finalTopic,
        updatedAt: DateTime.now(),
      );

      debugPrint(
        '✅ [_enhanceWithStructuredTitle] Enhanced summary: title="${enhanced.title}", topic="${enhanced.topic}"',
      );
      return enhanced;
    }

    debugPrint(
      '⚠️ [_enhanceWithStructuredTitle] Low confidence or empty title, keeping original: confidence=${titleResult.confidence}, title="${titleResult.title}"',
    );
    return summary;
  }

  /// Extract best keyword from content
  ///
  /// Fallback strategy when original topic is a placeholder
  String? _extractBestKeywordFromContent(String content) {
    if (content.isEmpty) return null;

    // Try to extract technical terms, keywords from first line, etc.
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty);
    if (lines.isEmpty) return null;

    // Extract first few meaningful words from the first line
    final firstLine = lines.first.trim();
    final words = firstLine.split(RegExp(r'[\s,.!?;:]+'));

    for (final word in words.take(5)) {
      var cleanWord = word.trim();
      // Remove leading quotes and brackets
      while (cleanWord.isNotEmpty &&
          (cleanWord.codeUnitAt(0) == 34 || // "
              cleanWord.codeUnitAt(0) == 39 || // '
              cleanWord.codeUnitAt(0) == 40 || // (
              cleanWord.codeUnitAt(0) == 91)) {
        // [
        cleanWord = cleanWord.substring(1);
      }
      // Remove trailing quotes and brackets
      while (cleanWord.isNotEmpty &&
          (cleanWord.codeUnitAt(cleanWord.length - 1) == 34 || // "
              cleanWord.codeUnitAt(cleanWord.length - 1) == 39 || // '
              cleanWord.codeUnitAt(cleanWord.length - 1) == 41 || // )
              cleanWord.codeUnitAt(cleanWord.length - 1) == 93)) {
        // ]
        cleanWord = cleanWord.substring(0, cleanWord.length - 1);
      }

      if (cleanWord.isNotEmpty &&
          cleanWord.length > 2 &&
          !_isStopWord(cleanWord.toLowerCase())) {
        return cleanWord;
      }
    }

    return null;
  }

  /// Check if it's a common stop word
  bool _isStopWord(String word) {
    const stopWords = {
      // English stop words
      'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
      'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
      'and', 'or', 'but', 'if', 'then', 'else', 'when', 'what', 'where',
      'which', 'who', 'whom', 'whose', 'why', 'how', 'this', 'that',
      'these', 'those', 'it', 'its', 'of', 'for', 'with', 'at', 'by',
      'from', 'up', 'to', 'in', 'on', 'as', 'so', 'than', 'too',
      // Chinese stop words
      '的', '了', '是', '在', '我', '有', '和', '就', '不', '人',
      '都', '一', '一个', '上', '也', '很', '到', '说', '要', '去',
      '你', '会', '着', '没有', '看', '好', '自己', '这',
    };

    return stopWords.contains(word);
  }

  /// Check if it's a valid semantic topic
  ///
  /// Filter out placeholder text (e.g., Untitled, unnamed, etc.)
  bool _isValidSemanticTopic(String topic) {
    if (topic.isEmpty) return false;

    final normalizedTopic = topic.trim().toLowerCase();

    // English placeholders
    const invalidEnglishTopics = {
      'untitled',
      'untitled summary',
      'untitled memory',
      'untitled fact',
      'unknown',
      'unnamed',
      'default',
    };

    // Chinese placeholders
    const invalidChineseTopics = {
      '未命名',
      '未命名摘要',
      '未命名记忆',
      '未命名事实',
      '未知',
      '默认',
    };

    // Check if contains placeholder
    if (invalidEnglishTopics.contains(normalizedTopic)) return false;
    if (invalidChineseTopics.contains(normalizedTopic)) return false;

    // Check if starts with placeholder (e.g., "Untitled:xxx")
    for (final invalid in invalidEnglishTopics) {
      if (normalizedTopic.startsWith('$invalid:') ||
          normalizedTopic.startsWith('$invalid：')) {
        return false;
      }
    }

    for (final invalid in invalidChineseTopics) {
      if (normalizedTopic.startsWith('$invalid:') ||
          normalizedTopic.startsWith('$invalid：')) {
        return false;
      }
    }

    return true;
  }

  /// Update summary
  Future<void> updateSummary(SummaryEntity summary) async {
    await repository.updateSummary(summary);
    if (summary.type == MemoryType.fact) {
      await _upgradeFactToCoreIfNeeded(summary.id);
    }
    _scheduleMemoryCompaction();
  }

  /// Delete summary
  Future<void> deleteSummary(String id) async {
    // 1. First delete associated promotion metadata
    await promotionRepository?.deleteMetadata(id);

    // 2. Delete core memory data
    await repository.deleteSummary(id);

    // 3. Trigger memory compaction
    _scheduleMemoryCompaction();
  }

  /// Get single summary
  SummaryEntity? getSummary(String id) {
    return repository.getSummary(id);
  }

  /// Get all summaries
  List<SummaryEntity> getAllSummaries() {
    return repository.getAllSummaries();
  }

  /// Search summaries
  List<SummaryEntity> searchSummaries(String query) {
    return repository.searchSummaries(query);
  }

  /// Search across runtime state, summary records and memory chunks.
  Future<List<MemorySearchHit>> searchMemory(
    String query, {
    int maxItems = 20,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return const <MemorySearchHit>[];
    }

    final hits = <MemorySearchHit>[];
    final capability = memoryCapability;
    final loweredQuery = normalizedQuery.toLowerCase();
    final queryKeywords = loweredQuery
        .split(RegExp(r'\s+'))
        .where((keyword) => keyword.isNotEmpty)
        .toList(growable: false);

    // Phase 1: exact/fuzzy state key/value hits.
    if (capability != null) {
      final retrieval = await capability.retrieve(
        MemoryRetrievalRequest(
          query: normalizedQuery,
          topic: normalizedQuery,
          keywords: queryKeywords,
          maxItems: maxItems,
          maxStateItems: maxItems,
        ),
      );
      for (final state in retrieval.states) {
        final score = _scoreStateSearchHit(state, loweredQuery, queryKeywords);
        if (score <= 0.0) {
          continue;
        }
        hits.add(
          MemorySearchHit(
            payloadRef: state.storageKey,
            source: MemorySearchSource.state,
            reason: _buildStateReason(state, loweredQuery, queryKeywords, score),
            score: score,
            state: state,
          ),
        );
      }

      // Phase 3 fallback: semantic chunk candidates from runtime memory units.
      for (final unit in retrieval.memoryUnits) {
        final score = _scoreMemoryUnitSearchHit(unit, loweredQuery, queryKeywords);
        if (score <= 0.0) {
          continue;
        }
        hits.add(
          MemorySearchHit(
            payloadRef: unit.id,
            source: MemorySearchSource.chunk,
            reason: _buildChunkReason(unit, queryKeywords, score),
            score: score,
            memoryUnit: unit,
          ),
        );
      }
    }

    // Phase 2: summary fallback (ranked below state hits).
    for (final summary in repository.searchSummaries(normalizedQuery)) {
      final score = _scoreSummarySearchHit(summary, loweredQuery, queryKeywords);
      hits.add(
        MemorySearchHit(
          payloadRef: summary.id,
          source: MemorySearchSource.summary,
          reason: _buildSummaryReason(summary, loweredQuery, queryKeywords),
          score: score,
          summary: summary,
        ),
      );
    }

    final deduped = <String, MemorySearchHit>{};
    for (final hit in hits) {
      final existing = deduped[hit.payloadRef];
      if (existing == null || hit.score > existing.score) {
        deduped[hit.payloadRef] = hit;
      }
    }

    final ordered = deduped.values.toList(growable: false)
      ..sort((a, b) {
        final sourcePriority = _sourceWeight(b.source).compareTo(
          _sourceWeight(a.source),
        );
        if (sourcePriority != 0) {
          return sourcePriority;
        }
        return b.score.compareTo(a.score);
      });

    return ordered.take(maxItems).toList(growable: false);
  }

  int _sourceWeight(MemorySearchSource source) {
    return switch (source) {
      MemorySearchSource.state => 3,
      MemorySearchSource.summary => 2,
      MemorySearchSource.chunk => 1,
    };
  }

  double _scoreStateSearchHit(
    StateRecord state,
    String query,
    List<String> queryKeywords,
  ) {
    final key = state.key.toLowerCase();
    final summary = state.summary.toLowerCase();
    final topic = state.topic.toLowerCase();
    final keywordOverlap = SimilarityUtils.tokenOverlapCoefficient(
      queryKeywords.join(' '),
      state.keywords.join(' ').toLowerCase(),
    );

    final exactMatch = key == query || topic == query || summary.contains(query);
    final fuzzyMatch = key.contains(query) ||
        topic.contains(query) ||
        queryKeywords.any(summary.contains);

    return (exactMatch ? 0.65 : 0.0) +
        (fuzzyMatch ? 0.2 : 0.0) +
        (keywordOverlap * 0.15);
  }

  double _scoreSummarySearchHit(
    SummaryEntity summary,
    String query,
    List<String> queryKeywords,
  ) {
    final textSimilarity = SimilarityUtils.calculateMemorySimilarity(
      query,
      queryKeywords.join(' '),
      summary.title.toLowerCase(),
      summary.content.toLowerCase(),
    );
    final keywordOverlap = SimilarityUtils.tokenOverlapCoefficient(
      queryKeywords.join(' '),
      summary.tags.join(' ').toLowerCase(),
    );
    return (textSimilarity * 0.75) + (keywordOverlap * 0.25);
  }

  double _scoreMemoryUnitSearchHit(
    MemoryUnit unit,
    String query,
    List<String> queryKeywords,
  ) {
    final keywordOverlap = SimilarityUtils.tokenOverlapCoefficient(
      queryKeywords.join(' '),
      unit.keywords.join(' ').toLowerCase(),
    );
    final textSimilarity = SimilarityUtils.calculateMemorySimilarity(
      query,
      queryKeywords.join(' '),
      unit.topic.toLowerCase(),
      unit.summary.toLowerCase(),
    );
    return (textSimilarity * 0.6) + (keywordOverlap * 0.2) + (unit.confidence * 0.2);
  }

  String _buildStateReason(
    StateRecord state,
    String query,
    List<String> queryKeywords,
    double score,
  ) {
    if (state.key.toLowerCase() == query) {
      return 'exact key match';
    }
    if (state.summary.toLowerCase().contains(query)) {
      return 'matched state value';
    }
    final overlap = state.keywords
        .where((keyword) => queryKeywords.contains(keyword.toLowerCase()))
        .length;
    if (overlap > 0) {
      return 'keyword overlap ($overlap)';
    }
    return 'fuzzy state match (${score.toStringAsFixed(2)})';
  }

  String _buildSummaryReason(
    SummaryEntity summary,
    String query,
    List<String> queryKeywords,
  ) {
    if (summary.title.toLowerCase().contains(query)) {
      return 'matched summary title';
    }
    final overlap = summary.tags
        .where((tag) => queryKeywords.contains(tag.toLowerCase()))
        .length;
    if (overlap > 0) {
      return 'tag overlap ($overlap)';
    }
    return 'semantic summary fallback';
  }

  String _buildChunkReason(
    MemoryUnit unit,
    List<String> queryKeywords,
    double score,
  ) {
    final overlap = unit.keywords
        .where((keyword) => queryKeywords.contains(keyword.toLowerCase()))
        .length;
    if (overlap > 0) {
      return 'chunk keyword overlap ($overlap)';
    }
    return 'semantic chunk fallback (${score.toStringAsFixed(2)})';
  }

  /// Update sort order
  Future<void> updateSortOrders(List<SummaryEntity> summaries) async {
    await repository.updateSortOrders(summaries);
  }

  /// Get summaries by tag
  List<SummaryEntity> getSummariesByTag(String tag) {
    return repository.getSummariesByTag(tag);
  }

  /// Get summaries by source
  List<SummaryEntity> getSummariesBySource(String source) {
    return repository.getSummariesBySource(source);
  }

  /// Record access
  ///
  /// ✅ NEW: Trigger Session → Fact auto-detection
  Future<void> recordAccess(String id) async {
    await repository.recordAccess(id);

    // ✅ NEW: Session → Fact auto-detection
    await _upgradeSessionToFactIfNeeded(id);

    // Existing Fact → Core detection
    await _upgradeFactToCoreIfNeeded(id);
    _scheduleMemoryCompaction();
  }

  /// Update importance score
  ///
  /// ✅ NEW: Trigger Session → Fact auto-detection
  Future<void> updateImportance(String id, double importance) async {
    await repository.updateImportance(id, importance);

    // ✅ NEW: Session → Fact auto-detection
    await _upgradeSessionToFactIfNeeded(id);

    // Existing Fact → Core detection
    await _upgradeFactToCoreIfNeeded(id);
    _scheduleMemoryCompaction();
  }

  /// Get description for upgrading fact memory to core memory
  Future<String?> getFactUpgradeReason(String id) async {
    final summary = getSummary(id);
    if (summary == null || summary.type != MemoryType.fact) {
      return null;
    }

    final response = await slmService.generateUpgradeReason(summary);
    final reason = response.data.trim();
    return reason.isEmpty ? null : reason;
  }

  /// Manually upgrade fact memory to core memory
  Future<SummaryEntity?> upgradeFactToCore(String id) async {
    final summary = getSummary(id);
    if (summary == null || summary.type != MemoryType.fact) {
      return null;
    }

    final updated = summary.copyWith(
      type: MemoryType.core,
      importance: max(
        summary.importance,
        policyConfig.coreUpgrade.importanceThreshold,
      ),
      updatedAt: DateTime.now(),
    );
    await repository.updateSummary(updated);
    _scheduleMemoryCompaction();
    return updated;
  }

  /// Get summaries by memory type
  List<SummaryEntity> getSummariesByType(MemoryType type) {
    return repository.getSummariesByType(type);
  }

  /// Add memory (with deduplication)
  Future<void> addWithDeduplication(
    SummaryEntity summary, {
    double? similarityThreshold,
  }) async {
    final enhancedSummary = _enhanceWithStructuredTitle(summary);
    final effectiveSimilarityThreshold =
        similarityThreshold ?? policyConfig.similarity.deduplicationThreshold;
    final existingSummaries = getAllSummaries();

    final duplicate = _findExactDuplicate(existingSummaries, enhancedSummary);
    if (duplicate != null) {
      debugPrint(
          '🔄 [Deduplication] Exact duplicate detected: ${enhancedSummary.title}');
      await updateSummary(
        duplicate.copyWith(
          lastAccessedAt: DateTime.now(),
          accessCount: duplicate.accessCount + 1,
          updatedAt: DateTime.now(),
        ),
      );
      return;
    }

    double bestSimilarity = 0.0;
    for (final existing in existingSummaries) {
      final similarity = SimilarityUtils.calculateMemorySimilarity(
        enhancedSummary.title,
        enhancedSummary.content,
        existing.title,
        existing.content,
      );

      bestSimilarity = max(bestSimilarity, similarity);
      if (similarity >= effectiveSimilarityThreshold) {
        debugPrint(
          '🔗 [Deduplication] High-similarity merge: ${enhancedSummary.title} -> ${existing.title} '
          '(similarity: ${(similarity * 100).toStringAsFixed(1)}%)',
        );
        final merged = _mergeMemories(existing, enhancedSummary);
        await updateSummary(merged);
        return;
      }
    }

    debugPrint(
      '✅ [Deduplication] Added unique content: ${enhancedSummary.title} '
      '(highest similarity: ${(bestSimilarity * 100).toStringAsFixed(1)}%)',
    );
    await addSummary(enhancedSummary);
  }

  /// Add fact summary, but do not automatically merge similar facts, instead return merge candidates for UI decision.
  Future<FactSummarySaveResult> addFactSummary(
    SummaryEntity summary, {
    double? similarityThreshold,
  }) async {
    final enhancedSummary = _enhanceWithStructuredTitle(summary);
    final factSummary = enhancedSummary.type == MemoryType.fact
        ? enhancedSummary
        : enhancedSummary.copyWith(type: MemoryType.fact);
    final duplicate =
        _findExactDuplicate(getSummariesByType(MemoryType.fact), factSummary);

    if (duplicate != null) {
      final updated = duplicate.copyWith(
        lastAccessedAt: DateTime.now(),
        accessCount: duplicate.accessCount + 1,
        updatedAt: DateTime.now(),
      );
      await updateSummary(updated);
      return FactSummarySaveResult(
        savedSummary: updated,
        wasExactDuplicate: true,
      );
    }

    await addSummary(factSummary);
    final savedSummary = getSummary(factSummary.id) ?? factSummary;
    if (savedSummary.type != MemoryType.fact) {
      return FactSummarySaveResult(savedSummary: savedSummary);
    }

    return FactSummarySaveResult(
      savedSummary: savedSummary,
      mergeCandidates: findMergeCandidates(
        savedSummary,
        threshold: similarityThreshold,
        allowedTypes: const <MemoryType>{MemoryType.fact},
      ),
    );
  }

  /// Adds a session memory and schedules background processing.
  /// Delegates ingestion to the MemoryCapability runtime.
  ///
  /// ✅ NEW: Automatically trigger Session → Fact detection
  Future<void> addSessionMemory(SummaryEntity summary) async {
    final enhancedSummary = _enhanceWithStructuredTitle(summary);
    final sessionSummaries = getSummariesByType(MemoryType.session);
    SummaryEntity? savedSession;

    final duplicate = _findExactDuplicate(sessionSummaries, enhancedSummary);
    if (duplicate != null) {
      // ✅ Get metadata from promotion repository and update
      final metadata = promotionRepository?.getMetadata(duplicate.id);
      final newSessionSpan = (metadata?.sessionSpan ?? 0) + 1;

      savedSession = duplicate.copyWith(
        lastAccessedAt: DateTime.now(),
        accessCount: duplicate.accessCount + 1,
        updatedAt: DateTime.now(),
      );
      await updateSummary(savedSession);

      // ✅ Update sessionSpan in promotion repository
      if (metadata != null) {
        await promotionRepository?.saveMetadata(
          metadata.copyWith(sessionSpan: newSessionSpan),
        );
      } else {
        // If no metadata existed before, create new one
        await promotionRepository?.saveMetadata(
          MemoryPromotionMetadata(
            summaryId: duplicate.id,
            sessionSpan: newSessionSpan,
            summaryTitle: duplicate.title,
          ),
        );
      }
    } else {
      savedSession = enhancedSummary.copyWith(type: MemoryType.session);
      await addSummary(savedSession);
    }

    // ✅ NEW: After saving, check if promotion conditions are met
    await _upgradeSessionToFactIfNeeded(savedSession.id);

    final capability = memoryCapability;
    if (capability != null) {
      unawaited(capability.ingestSession(savedSession));
      return;
    }

    throw StateError('addSessionMemory requires a MemoryCapability');
  }

  /// Find exact duplicate content (compare after normalization)
  SummaryEntity? _findExactDuplicate(
    List<SummaryEntity> existing,
    SummaryEntity incoming,
  ) {
    final incomingContent = _normalizeContent(incoming.content);
    final incomingTitle = _normalizeTitle(incoming.title);

    for (final item in existing) {
      final normalizedContent = _normalizeContent(item.content);
      final normalizedTitle = _normalizeTitle(item.title);

      if (normalizedTitle == incomingTitle &&
          normalizedContent == incomingContent) {
        return item;
      }
    }
    return null;
  }

  String _normalizeTitle(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\u4E00-\u9FFF ]'), '')
        .trim();
  }

  String _normalizeContent(String content) {
    return content.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Merge two similar memories
  SummaryEntity _mergeMemories(SummaryEntity existing, SummaryEntity newOne) {
    final mergedTags = {...existing.tags, ...newOne.tags}.toList();
    final mergedContent = _mergeContent(existing.content, newOne.content);

    return existing.copyWith(
      content: mergedContent,
      tags: mergedTags,
      updatedAt: DateTime.now(),
      importance: (existing.importance + newOne.importance) / 2,
      accessCount: existing.accessCount + newOne.accessCount,
      lastAccessedAt: DateTime.now(),
    );
  }

  /// Merge memory content, avoiding duplication
  String _mergeContent(String content1, String content2) {
    if (content1.contains(content2)) {
      return content1;
    }
    if (content2.contains(content1)) {
      return content2;
    }

    final normalized1 = _normalizeContent(content1);
    final normalized2 = _normalizeContent(content2);

    if (normalized1.contains(normalized2) ||
        normalized2.contains(normalized1)) {
      return normalized1.length > normalized2.length ? content1 : content2;
    }

    return '$content1\n\n$content2';
  }

  /// Apply forgetting curve
  Future<void> applyForgettingCurve() async {
    final allSummaries = getAllSummaries();
    final now = DateTime.now();
    final curve = policyConfig.forgettingCurve;

    for (final summary in allSummaries) {
      if (summary.type == MemoryType.core) {
        continue;
      }

      if (summary.type == MemoryType.fact) {
        await _upgradeFactToCoreIfNeeded(summary.id);
      }
      final current = getSummary(summary.id);
      if (current == null || current.type != MemoryType.fact) {
        continue;
      }

      final daysOld = now.difference(current.createdAt).inDays;
      if (daysOld <= curve.startDays) {
        continue;
      }

      final decayFactor = max(
        curve.minImportance,
        1.0 -
            ((daysOld - curve.startDays) / curve.decayPeriodDays) *
                curve.decayRate,
      );
      final newImportance = (current.importance * decayFactor)
          .clamp(
            curve.minImportance,
            1.0,
          )
          .toDouble();

      if (newImportance != current.importance) {
        await repository.updateSummary(
          current.copyWith(
            importance: newImportance,
            updatedAt: DateTime.now(),
          ),
        );
      }
    }
  }

  /// Clean up expired session memories (default 2 hours)
  Future<void> cleanupSessionMemories({
    Duration? maxAge,
  }) async {
    final capability = memoryCapability;
    if (capability != null) {
      unawaited(capability.compact());
    }

    final sessionMemories = getSummariesByType(MemoryType.session);
    final now = DateTime.now();
    final effectiveMaxAge = maxAge ?? policyConfig.sessionMaxAge;

    for (final session in sessionMemories) {
      if (session.isSessionProtected) {
        continue;
      }

      final referenceTime =
          session.lastAccessedAt ?? session.updatedAt ?? session.createdAt;
      if (now.difference(referenceTime) > effectiveMaxAge) {
        await deleteSummary(session.id);
      }
    }
  }

  void _scheduleMemoryCompaction() {
    final capability = memoryCapability;
    if (capability == null) {
      return;
    }
    unawaited(capability.compact());
  }

  /// Find similar memories
  List<SummaryEntity> findSimilarMemories(
    SummaryEntity target, {
    double? threshold,
  }) {
    return findMergeCandidates(
      target,
      threshold: threshold,
      allowedTypes: const <MemoryType>{
        MemoryType.fact,
        MemoryType.session,
        MemoryType.core,
      },
    ).map((candidate) => candidate.summary).toList(growable: false);
  }

  List<SummaryMergeCandidate> findMergeCandidates(
    SummaryEntity target, {
    double? threshold,
    Set<MemoryType> allowedTypes = const <MemoryType>{MemoryType.fact},
  }) {
    final effectiveThreshold =
        threshold ?? policyConfig.similarity.relatedMemoryThreshold;
    final candidates = <SummaryMergeCandidate>[];

    for (final summary in getAllSummaries()) {
      if (summary.id == target.id || !allowedTypes.contains(summary.type)) {
        continue;
      }

      final similarity = SimilarityUtils.calculateMemorySimilarity(
        target.title,
        target.content,
        summary.title,
        summary.content,
      );

      if (similarity >= effectiveThreshold) {
        candidates.add(
          SummaryMergeCandidate(
            summary: summary,
            similarity: similarity,
          ),
        );
      }
    }

    candidates.sort((a, b) => b.similarity.compareTo(a.similarity));
    return candidates;
  }

  /// Manually merge two memories
  Future<void> mergeMemories(String id1, String id2) async {
    await mergeMemoriesWithResolution(
      primaryId: id1,
      secondaryId: id2,
      resolution: const SummaryMergeResolution(),
    );
  }

  Future<void> mergeMemoriesWithResolution({
    required String primaryId,
    required String secondaryId,
    SummaryMergeResolution resolution = const SummaryMergeResolution(),
  }) async {
    final primarySummary = getSummary(primaryId);
    final secondarySummary = getSummary(secondaryId);

    if (primarySummary == null || secondarySummary == null) {
      throw ArgumentError('Requested memory could not be found');
    }
    if (primarySummary.type != MemoryType.fact ||
        secondarySummary.type != MemoryType.fact) {
      throw StateError('Manual merge currently supports fact memories only');
    }

    final merged = buildMergedSummary(
      primarySummary,
      secondarySummary,
      resolution: resolution,
    );
    await updateSummary(merged);
    await deleteSummary(secondarySummary.id);
  }

  SummaryEntity buildMergedSummary(
    SummaryEntity primary,
    SummaryEntity secondary, {
    SummaryMergeResolution resolution = const SummaryMergeResolution(),
  }) {
    // Handle content according to merge strategy
    final String mergedContent;
    if (resolution.content == SummaryMergeFieldChoice.combined &&
        merger != null) {
      // Smart merge: use memory runtime compaction logic
      mergedContent = merger!.compressSummaryForMerge(
        primary.content,
        secondary.content,
      );
    } else if (resolution.content == SummaryMergeFieldChoice.incoming) {
      mergedContent = secondary.content;
    } else {
      // existing or other cases
      mergedContent = primary.content;
    }

    return primary.copyWith(
      title: resolution.title == SummaryMergeFieldChoice.incoming
          ? secondary.title
          : resolution.title == SummaryMergeFieldChoice.existing
              ? primary.title
              : resolution.title == SummaryMergeFieldChoice.combined
                  ? '${primary.title} ${secondary.title}'
                  : primary.title,
      content: mergedContent,
      tags: resolution.tags == SummaryMergeFieldChoice.incoming
          ? secondary.tags
          : resolution.tags == SummaryMergeFieldChoice.existing
              ? primary.tags
              : resolution.tags == SummaryMergeFieldChoice.combined
                  ? {...primary.tags, ...secondary.tags}.toList()
                  : primary.tags,
      createdAt: primary.createdAt.isBefore(secondary.createdAt)
          ? primary.createdAt
          : secondary.createdAt,
      updatedAt: DateTime.now(),
      lastAccessedAt: primary.lastAccessedAt
                  ?.isAfter(secondary.lastAccessedAt ?? DateTime(1970)) ??
              false
          ? primary.lastAccessedAt
          : secondary.lastAccessedAt,
      topic: primary.topic ?? secondary.topic,
      importance: (primary.importance + secondary.importance) / 2,
      accessCount: primary.accessCount + secondary.accessCount,
    );
  }

  Future<void> _upgradeFactToCoreIfNeeded(String id) async {
    final summary = getSummary(id);
    if (summary == null) return;

    // ✅ Get metadata from promotion repository
    final metadata = promotionRepository?.getMetadata(id);
    if (metadata == null) return;

    // ✅ Score using new PromotionScorer
    final score = PromotionScorer.scoreForFactToCore(
      sessionSpan: metadata.sessionSpan,
      stabilityScore: metadata.stabilityScore,
      hasImpactOnOutput: metadata.usageInRecommendations >= 5,
      contentType: summary.contentType,
      userConfirmedLongTerm: metadata.userConfirmedLongTerm,
      hasRecentConflict: metadata.lastConflictAt != null &&
          DateTime.now().difference(metadata.lastConflictAt!).inDays < 30,
      usageInRecommendations: metadata.usageInRecommendations,
    );

    // ✅ Check if promotion conditions are met (≥75 points)
    if (score < 75) return;

    debugPrint(
        '⬆️ [Promotion] Fact eligible for promotion to Core: ${summary.title}');
    debugPrint('📊 [Promotion] Score: $score');
    debugPrint('   - sessionSpan: ${metadata.sessionSpan}');
    debugPrint('   - stabilityScore: ${metadata.stabilityScore}');
    debugPrint(
        '   - usageInRecommendations: ${metadata.usageInRecommendations}');
    debugPrint('   - userConfirmedLongTerm: ${metadata.userConfirmedLongTerm}');

    await repository.updateSummary(
      summary.copyWith(
        type: MemoryType.core,
        state: MemoryState.core,
        updatedAt: DateTime.now(),
      ),
    );

    debugPrint('✅ [Promotion] Promoted: Fact → Core');
  }

  /// ✅ NEW: Session → Fact auto-detection
  Future<void> _upgradeSessionToFactIfNeeded(String id) async {
    final summary = getSummary(id);
    if (summary == null) return;

    // ✅ Get metadata from promotion repository
    final metadata = promotionRepository?.getMetadata(id);
    if (metadata == null) return;

    // ✅ Score using new PromotionScorer
    final score = PromotionScorer.scoreForSessionToFact(
      sessionSpan: metadata.sessionSpan,
      userExplicitSave: metadata.userExplicitSave,
      referenceCount: metadata.referenceCount,
      accessCount: summary.accessCount,
      contentType: summary.contentType,
      hasConflict: false,
    );

    // ✅ Check if promotion conditions are met (≥70 points)
    if (score < 70) return;

    debugPrint(
        '⬆️ [Promotion] Session eligible for promotion to Fact: ${summary.title}');
    debugPrint('📊 [Promotion] Score: $score');
    debugPrint('   - sessionSpan: ${metadata.sessionSpan}');
    debugPrint('   - userExplicitSave: ${metadata.userExplicitSave}');
    debugPrint('   - referenceCount: ${metadata.referenceCount}');
    debugPrint('   - accessCount: ${summary.accessCount}');
    debugPrint('   - contentType: ${summary.contentType.name}');

    await repository.updateSummary(
      summary.copyWith(
        type: MemoryType.fact,
        state: MemoryState.fact,
        updatedAt: DateTime.now(),
      ),
    );

    debugPrint('✅ [Promotion] Promoted: Session → Fact');
  }

  // === Memory Promotion Metadata Management Methods ===

  /// Get promotion metadata for memory
  MemoryPromotionMetadata? getPromotionMetadata(String summaryId) {
    return promotionRepository?.getMetadata(summaryId);
  }

  /// Save or update promotion metadata for memory
  Future<void> savePromotionMetadata(MemoryPromotionMetadata metadata) async {
    await promotionRepository?.saveMetadata(metadata);
  }
}
