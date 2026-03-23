import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:local_vault/core/utils/json_utils.dart';
import 'package:path_provider/path_provider.dart';

class MemoryTimeThresholds {
  const MemoryTimeThresholds({
    this.shortTerm = const Duration(hours: 6),
    this.mediumTerm = const Duration(days: 1),
  });

  final Duration shortTerm;
  final Duration mediumTerm;

  factory MemoryTimeThresholds.fromJson(Map<String, dynamic> json) {
    return MemoryTimeThresholds(
      shortTerm: MemoryPolicyConfig.durationFromJson(
        json['shortTerm'],
        defaultValue: const Duration(hours: 6),
      ),
      mediumTerm: MemoryPolicyConfig.durationFromJson(
        json['mediumTerm'],
        defaultValue: const Duration(days: 1),
      ),
    );
  }
}

class ForgettingCurveConfig {
  const ForgettingCurveConfig({
    this.startDays = 30,
    this.decayPeriodDays = 60,
    this.minImportance = 0.1,
    this.decayRate = 0.9,
  });

  final int startDays;
  final int decayPeriodDays;
  final double minImportance;
  final double decayRate;

  factory ForgettingCurveConfig.fromJson(Map<String, dynamic> json) {
    return ForgettingCurveConfig(
      startDays: json['startDays'] as int? ?? 30,
      decayPeriodDays: json['decayPeriodDays'] as int? ?? 60,
      minImportance: (json['minImportance'] as num?)?.toDouble() ?? 0.1,
      decayRate: (json['decayRate'] as num?)?.toDouble() ?? 0.9,
    );
  }
}

class CoreUpgradePolicy {
  const CoreUpgradePolicy({
    this.accessCountThreshold = 10,
    this.importanceThreshold = 0.8,
  });

  final int accessCountThreshold;
  final double importanceThreshold;

  factory CoreUpgradePolicy.fromJson(Map<String, dynamic> json) {
    return CoreUpgradePolicy(
      accessCountThreshold: json['accessCountThreshold'] as int? ?? 10,
      importanceThreshold:
          (json['importanceThreshold'] as num?)?.toDouble() ?? 0.8,
    );
  }
}

class SimilarityPolicy {
  const SimilarityPolicy({
    this.deduplicationThreshold = 0.7,
    this.relatedMemoryThreshold = 0.5,
  });

  final double deduplicationThreshold;
  final double relatedMemoryThreshold;

  factory SimilarityPolicy.fromJson(Map<String, dynamic> json) {
    return SimilarityPolicy(
      deduplicationThreshold:
          (json['deduplicationThreshold'] as num?)?.toDouble() ?? 0.7,
      relatedMemoryThreshold:
          (json['relatedMemoryThreshold'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

class SessionBatchingPolicy {
  const SessionBatchingPolicy({
    this.minimumMergeBatchSize = 3,
    this.minimumRuleScoreForSemanticCheck = 0.3,
    this.topicMatchScoreFloor = 0.85,
    this.ruleWeight = 0.4,
    this.semanticWeight = 0.6,
    this.combinedScoreThreshold = 0.75,
    this.exactTitleMatchWeight = 0.3,
    this.partialTitleMatchWeight = 0.2,
    this.semanticSimilarityWeight = 0.3,
    this.tagOverlapWeight = 0.2,
    this.sameSourceWeight = 0.1,
    this.shortTermTimeWeight = 0.1,
    this.mediumTermTimeWeight = 0.05,
  });

  final int minimumMergeBatchSize;
  final double minimumRuleScoreForSemanticCheck;
  final double topicMatchScoreFloor;
  final double ruleWeight;
  final double semanticWeight;
  final double combinedScoreThreshold;
  final double exactTitleMatchWeight;
  final double partialTitleMatchWeight;
  final double semanticSimilarityWeight;
  final double tagOverlapWeight;
  final double sameSourceWeight;
  final double shortTermTimeWeight;
  final double mediumTermTimeWeight;

  factory SessionBatchingPolicy.fromJson(Map<String, dynamic> json) {
    return SessionBatchingPolicy(
      minimumMergeBatchSize: json['minimumMergeBatchSize'] as int? ?? 3,
      minimumRuleScoreForSemanticCheck:
          (json['minimumRuleScoreForSemanticCheck'] as num?)?.toDouble() ?? 0.3,
      topicMatchScoreFloor:
          (json['topicMatchScoreFloor'] as num?)?.toDouble() ?? 0.85,
      ruleWeight: (json['ruleWeight'] as num?)?.toDouble() ?? 0.4,
      semanticWeight: (json['semanticWeight'] as num?)?.toDouble() ?? 0.6,
      combinedScoreThreshold:
          (json['combinedScoreThreshold'] as num?)?.toDouble() ?? 0.75,
      exactTitleMatchWeight:
          (json['exactTitleMatchWeight'] as num?)?.toDouble() ?? 0.3,
      partialTitleMatchWeight:
          (json['partialTitleMatchWeight'] as num?)?.toDouble() ?? 0.2,
      semanticSimilarityWeight:
          (json['semanticSimilarityWeight'] as num?)?.toDouble() ?? 0.3,
      tagOverlapWeight: (json['tagOverlapWeight'] as num?)?.toDouble() ?? 0.2,
      sameSourceWeight: (json['sameSourceWeight'] as num?)?.toDouble() ?? 0.1,
      shortTermTimeWeight:
          (json['shortTermTimeWeight'] as num?)?.toDouble() ?? 0.1,
      mediumTermTimeWeight:
          (json['mediumTermTimeWeight'] as num?)?.toDouble() ?? 0.05,
    );
  }
}

class MemoryPolicyConfig {
  const MemoryPolicyConfig({
    this.sessionMaxAge = const Duration(hours: 2),
    this.candidateProtectionWindow = const Duration(hours: 24),
    this.timeThresholds = const MemoryTimeThresholds(),
    this.forgettingCurve = const ForgettingCurveConfig(),
    this.coreUpgrade = const CoreUpgradePolicy(),
    this.similarity = const SimilarityPolicy(),
    this.sessionBatching = const SessionBatchingPolicy(),
  });

  static const String bundledConfigAssetPath =
      'assets/config/memory_policy_config.json';
  static const String overrideDirectoryName = 'memory_policy';
  static const String overrideFileName = 'memory_policy_config.override.json';
  static const MemoryPolicyConfig defaults = MemoryPolicyConfig();

  final Duration sessionMaxAge;
  final Duration candidateProtectionWindow;
  final MemoryTimeThresholds timeThresholds;
  final ForgettingCurveConfig forgettingCurve;
  final CoreUpgradePolicy coreUpgrade;
  final SimilarityPolicy similarity;
  final SessionBatchingPolicy sessionBatching;

  factory MemoryPolicyConfig.fromJson(Map<String, dynamic> json) {
    return MemoryPolicyConfig(
      sessionMaxAge: durationFromJson(
        json['sessionMaxAge'],
        defaultValue: const Duration(hours: 2),
      ),
      candidateProtectionWindow: durationFromJson(
        json['candidateProtectionWindow'],
        defaultValue: const Duration(hours: 24),
      ),
      timeThresholds: MemoryTimeThresholds.fromJson(
        JsonUtils.asMap(json['timeThresholds']),
      ),
      forgettingCurve: ForgettingCurveConfig.fromJson(
        JsonUtils.asMap(json['forgettingCurve']),
      ),
      coreUpgrade: CoreUpgradePolicy.fromJson(
        JsonUtils.asMap(json['coreUpgrade']),
      ),
      similarity: SimilarityPolicy.fromJson(
        JsonUtils.asMap(json['similarity']),
      ),
      sessionBatching: SessionBatchingPolicy.fromJson(
        JsonUtils.asMap(json['sessionBatching']),
      ),
    );
  }

  static Duration durationFromJson(
    Object? raw, {
    required Duration defaultValue,
  }) {
    final value = JsonUtils.asMap(raw);
    if (value.isEmpty) {
      return defaultValue;
    }

    return Duration(
      days: value['days'] as int? ?? 0,
      hours: value['hours'] as int? ?? 0,
      minutes: value['minutes'] as int? ?? 0,
      seconds: value['seconds'] as int? ?? 0,
      milliseconds: value['milliseconds'] as int? ?? 0,
    );
  }

  static Future<MemoryPolicyConfig> load({
    Future<File> Function()? overrideFileResolver,
  }) async {
    Map<String, dynamic> merged = <String, dynamic>{};

    try {
      final bundledRaw = await rootBundle.loadString(bundledConfigAssetPath);
      merged = JsonUtils.asMap(jsonDecode(bundledRaw));
    } catch (error, stackTrace) {
      debugPrint(
          '⚠️ [MemoryPolicyConfig] Failed to read bundled config, falling back to defaults: $error');
      debugPrintStack(stackTrace: stackTrace);
      return defaults;
    }

    try {
      final resolveFile = overrideFileResolver ?? resolveOverrideFile;
      final overrideFile = await resolveFile();
      if (await overrideFile.exists()) {
        final overrideRaw = await overrideFile.readAsString();
        final overrideJson = JsonUtils.asMap(jsonDecode(overrideRaw));
        merged = _deepMerge(merged, overrideJson);
      }
    } catch (error, stackTrace) {
      debugPrint(
        '⚠️ [MemoryPolicyConfig] Failed to read override config, continuing with bundled config: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }

    return MemoryPolicyConfig.fromJson(merged);
  }

  static Future<File> resolveOverrideFile() async {
    final appSupportDirectory = await getApplicationSupportDirectory();
    final configDirectory = Directory(
      '${appSupportDirectory.path}/$overrideDirectoryName',
    );
    if (!await configDirectory.exists()) {
      await configDirectory.create(recursive: true);
    }
    return File('${configDirectory.path}/$overrideFileName');
  }

  static Map<String, dynamic> _deepMerge(
    Map<String, dynamic> base,
    Map<String, dynamic> override,
  ) {
    final merged = Map<String, dynamic>.from(base);
    override.forEach((key, value) {
      final current = merged[key];
      if (current is Map && value is Map) {
        if (_isDurationMap(current) || _isDurationMap(value)) {
          merged[key] = JsonUtils.asMap(value);
          return;
        }
        merged[key] = _deepMerge(
          JsonUtils.asMap(current),
          JsonUtils.asMap(value),
        );
      } else {
        merged[key] = value;
      }
    });
    return merged;
  }

  static bool _isDurationMap(Object? raw) {
    final value = JsonUtils.asMap(raw);
    if (value.isEmpty) {
      return false;
    }
    const durationKeys = <String>{
      'days',
      'hours',
      'minutes',
      'seconds',
      'milliseconds',
    };
    return value.keys.every(durationKeys.contains);
  }
}
