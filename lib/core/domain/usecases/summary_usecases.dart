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
import 'package:local_vault/core/memory_runtime/interfaces/memory_runtime_interfaces.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
import 'package:local_vault/core/utils/memory_title_generator.dart';
import 'package:local_vault/core/utils/similarity_utils.dart';
import 'package:local_vault/core/utils/summary_text_utils.dart';

/// 摘要业务用例
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

  /// 添加摘要
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

  /// 使用结构化标题生成器优化标题和主题
  SummaryEntity _enhanceWithStructuredTitle(SummaryEntity summary) {
    // ✅ 关键修复：如果标题是 "Untitled"，不要传入 rawContent，避免污染
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
      // ✅ 检查是否是占位符主题（如 Untitled、未命名等）
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

      // ✅ 如果 topic 是占位符，尝试重新生成更好的标题
      String finalTitle;
      String? finalTopic;

      if (!isValidTopic) {
        // topic 是占位符，尝试基于内容提取更有意义的关键词
        final bestKeyword = _extractBestKeywordFromContent(summary.content);
        if (bestKeyword != null && bestKeyword.isNotEmpty) {
          finalTitle =
              '$bestKeyword:${titleResult.title.split(':').last.trim()}';
          finalTopic = bestKeyword;
          debugPrint(
            '♻️ [StructuredTitle] Regenerated with keyword: title="$finalTitle", topic="$finalTopic"',
          );
        } else {
          // ⚠️ 无法提取关键词，使用 SummaryTextUtils 作为最后兜底
          final fallbackTitle = SummaryTextUtils.generateTitle(summary.content);
          if (!SummaryTextUtils.isUnnamedTitleValue(fallbackTitle)) {
            finalTitle = fallbackTitle;
            finalTopic = null;
            debugPrint(
              '🔄 [StructuredTitle] Fallback to SummaryTextUtils: title="$finalTitle"',
            );
          } else {
            // 所有方法都失败，保留原标题但清除 topic
            finalTitle = titleResult.title;
            finalTopic = null;
            debugPrint(
              '⚠️ [StructuredTitle] All title generation failed, keeping original with empty topic',
            );
          }
        }
      } else {
        // topic 有效，直接使用
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

  /// 从内容中提取最佳关键词
  ///
  /// 用于当原始 topic 是占位符时的兜底策略
  String? _extractBestKeywordFromContent(String content) {
    if (content.isEmpty) return null;

    // 尝试提取技术术语、首句关键词等
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty);
    if (lines.isEmpty) return null;

    // 从第一行提取前几个有意义的词
    final firstLine = lines.first.trim();
    final words = firstLine.split(RegExp(r'[\s,.!?;:]+'));

    for (final word in words.take(5)) {
      var cleanWord = word.trim();
      // 移除开头的引号、括号
      while (cleanWord.isNotEmpty &&
          (cleanWord.codeUnitAt(0) == 34 || // "
              cleanWord.codeUnitAt(0) == 39 || // '
              cleanWord.codeUnitAt(0) == 40 || // (
              cleanWord.codeUnitAt(0) == 91)) {
        // [
        cleanWord = cleanWord.substring(1);
      }
      // 移除结尾的引号、括号
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

  /// 检查是否是常见的停用词
  bool _isStopWord(String word) {
    const stopWords = {
      // 英文停用词
      'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
      'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
      'and', 'or', 'but', 'if', 'then', 'else', 'when', 'what', 'where',
      'which', 'who', 'whom', 'whose', 'why', 'how', 'this', 'that',
      'these', 'those', 'it', 'its', 'of', 'for', 'with', 'at', 'by',
      'from', 'up', 'to', 'in', 'on', 'as', 'so', 'than', 'too',
      // 中文停用词
      '的', '了', '是', '在', '我', '有', '和', '就', '不', '人',
      '都', '一', '一个', '上', '也', '很', '到', '说', '要', '去',
      '你', '会', '着', '没有', '看', '好', '自己', '这',
    };

    return stopWords.contains(word);
  }

  /// 检查是否是有效的语义主题
  ///
  /// 过滤掉占位符文本（如 Untitled、未命名等）
  bool _isValidSemanticTopic(String topic) {
    if (topic.isEmpty) return false;

    final normalizedTopic = topic.trim().toLowerCase();

    // 英文占位符
    const invalidEnglishTopics = {
      'untitled',
      'untitled summary',
      'untitled memory',
      'untitled fact',
      'unknown',
      'unnamed',
      'default',
    };

    // 中文占位符
    const invalidChineseTopics = {
      '未命名',
      '未命名摘要',
      '未命名记忆',
      '未命名事实',
      '未知',
      '默认',
    };

    // 检查是否包含占位符
    if (invalidEnglishTopics.contains(normalizedTopic)) return false;
    if (invalidChineseTopics.contains(normalizedTopic)) return false;

    // 检查是否以占位符开头（如 "Untitled：xxx"）
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

  /// 更新摘要
  Future<void> updateSummary(SummaryEntity summary) async {
    await repository.updateSummary(summary);
    if (summary.type == MemoryType.fact) {
      await _upgradeFactToCoreIfNeeded(summary.id);
    }
    _scheduleMemoryCompaction();
  }

  /// 删除摘要
  Future<void> deleteSummary(String id) async {
    // 1. 先删除关联的晋升元数据
    await promotionRepository?.deleteMetadata(id);

    // 2. 删除核心记忆数据
    await repository.deleteSummary(id);

    // 3. 触发记忆压缩
    _scheduleMemoryCompaction();
  }

  /// 获取单个摘要
  SummaryEntity? getSummary(String id) {
    return repository.getSummary(id);
  }

  /// 获取所有摘要
  List<SummaryEntity> getAllSummaries() {
    return repository.getAllSummaries();
  }

  /// 搜索摘要
  List<SummaryEntity> searchSummaries(String query) {
    return repository.searchSummaries(query);
  }

  /// 更新排序
  Future<void> updateSortOrders(List<SummaryEntity> summaries) async {
    await repository.updateSortOrders(summaries);
  }

  /// 根据标签获取摘要
  List<SummaryEntity> getSummariesByTag(String tag) {
    return repository.getSummariesByTag(tag);
  }

  /// 根据来源获取摘要
  List<SummaryEntity> getSummariesBySource(String source) {
    return repository.getSummariesBySource(source);
  }

  /// 记录访问
  ///
  /// ✅ 新增：触发 Session → Fact 自动检测
  Future<void> recordAccess(String id) async {
    await repository.recordAccess(id);

    // ✅ 新增：Session → Fact 自动检测
    await _upgradeSessionToFactIfNeeded(id);

    // 原有的 Fact → Core 检测
    await _upgradeFactToCoreIfNeeded(id);
    _scheduleMemoryCompaction();
  }

  /// 更新重要性评分
  ///
  /// ✅ 新增：触发 Session → Fact 自动检测
  Future<void> updateImportance(String id, double importance) async {
    await repository.updateImportance(id, importance);

    // ✅ 新增：Session → Fact 自动检测
    await _upgradeSessionToFactIfNeeded(id);

    // 原有的 Fact → Core 检测
    await _upgradeFactToCoreIfNeeded(id);
    _scheduleMemoryCompaction();
  }

  /// 获取事实记忆升级为核心记忆的说明
  Future<String?> getFactUpgradeReason(String id) async {
    final summary = getSummary(id);
    if (summary == null || summary.type != MemoryType.fact) {
      return null;
    }

    final response = await slmService.generateUpgradeReason(summary);
    final reason = response.data.trim();
    return reason.isEmpty ? null : reason;
  }

  /// 手动将事实记忆升级为核心记忆
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

  /// 根据记忆类型获取
  List<SummaryEntity> getSummariesByType(MemoryType type) {
    return repository.getSummariesByType(type);
  }

  /// 添加记忆（带去重）
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

  /// 添加事实记忆，但不自动合并相似事实，改为返回合并候选供 UI 决策。
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
  /// ✅ 新增：自动触发 Session → Fact 检测
  Future<void> addSessionMemory(SummaryEntity summary) async {
    final enhancedSummary = _enhanceWithStructuredTitle(summary);
    final sessionSummaries = getSummariesByType(MemoryType.session);
    SummaryEntity? savedSession;

    final duplicate = _findExactDuplicate(sessionSummaries, enhancedSummary);
    if (duplicate != null) {
      // ✅ 从 promotion repository 获取元数据并更新
      final metadata = promotionRepository?.getMetadata(duplicate.id);
      final newSessionSpan = (metadata?.sessionSpan ?? 0) + 1;

      savedSession = duplicate.copyWith(
        lastAccessedAt: DateTime.now(),
        accessCount: duplicate.accessCount + 1,
        updatedAt: DateTime.now(),
      );
      await updateSummary(savedSession);

      // ✅ 更新 promotion repository 中的 sessionSpan
      if (metadata != null) {
        await promotionRepository?.saveMetadata(
          metadata.copyWith(sessionSpan: newSessionSpan),
        );
      } else {
        // 如果之前没有元数据，创建新的
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

    // ✅ 新增：保存后检测是否满足晋升条件
    await _upgradeSessionToFactIfNeeded(savedSession.id);

    final capability = memoryCapability;
    if (capability != null) {
      unawaited(capability.ingestSession(savedSession));
      return;
    }

    throw StateError('addSessionMemory requires a MemoryCapability');
  }

  /// 查找完全重复的内容（标准化后比较）
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

  /// 合并两个相似记忆
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

  /// 合并记忆内容，避免重复
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

  /// 应用遗忘曲线
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

  /// 清理过期会话记忆（默认 2 小时）
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

  /// 查找相似记忆
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

  /// 手动合并两个记忆
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
    // 根据合并策略处理 content
    final String mergedContent;
    if (resolution.content == SummaryMergeFieldChoice.combined &&
        merger != null) {
      // 智能合并：使用记忆运行时的压缩逻辑
      mergedContent = merger!.compressSummaryForMerge(
        primary.content,
        secondary.content,
      );
    } else if (resolution.content == SummaryMergeFieldChoice.incoming) {
      mergedContent = secondary.content;
    } else {
      // existing 或其他情况
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

    // ✅ 从 promotion repository 获取元数据
    final metadata = promotionRepository?.getMetadata(id);
    if (metadata == null) return;

    // ✅ 使用新的 PromotionScorer 计分
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

    // ✅ 检查是否符合晋升条件（≥75 分）
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
  
  /// ✅ 新增：Session → Fact 自动检测
  Future<void> _upgradeSessionToFactIfNeeded(String id) async {
    final summary = getSummary(id);
    if (summary == null) return;

    // ✅ 从 promotion repository 获取元数据
    final metadata = promotionRepository?.getMetadata(id);
    if (metadata == null) return;

    // ✅ 使用新的 PromotionScorer 计分
    final score = PromotionScorer.scoreForSessionToFact(
      sessionSpan: metadata.sessionSpan,
      userExplicitSave: metadata.userExplicitSave,
      referenceCount: metadata.referenceCount,
      accessCount: summary.accessCount,
      contentType: summary.contentType,
      hasConflict: false,
    );

    // ✅ 检查是否符合晋升条件（≥70 分）
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

  // === 记忆晋升元数据管理方法 ===

  /// 获取记忆的晋升元数据
  MemoryPromotionMetadata? getPromotionMetadata(String summaryId) {
    return promotionRepository?.getMetadata(summaryId);
  }

  /// 保存或更新记忆的晋升元数据
  Future<void> savePromotionMetadata(MemoryPromotionMetadata metadata) async {
    await promotionRepository?.saveMetadata(metadata);
  }
}


