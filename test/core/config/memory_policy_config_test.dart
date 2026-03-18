import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/config/memory_policy_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MemoryPolicyConfig', () {
    test('parses durations and thresholds from json', () {
      final config = MemoryPolicyConfig.fromJson(const <String, dynamic>{
        'sessionMaxAge': <String, dynamic>{
          'minutes': 90,
        },
        'candidateProtectionWindow': <String, dynamic>{
          'days': 2,
        },
        'timeThresholds': <String, dynamic>{
          'shortTerm': <String, dynamic>{
            'hours': 3,
          },
          'mediumTerm': <String, dynamic>{
            'hours': 18,
          },
        },
        'forgettingCurve': <String, dynamic>{
          'startDays': 14,
          'decayPeriodDays': 45,
          'minImportance': 0.2,
          'decayRate': 0.7,
        },
        'coreUpgrade': <String, dynamic>{
          'accessCountThreshold': 6,
          'importanceThreshold': 0.85,
        },
        'similarity': <String, dynamic>{
          'deduplicationThreshold': 0.82,
          'relatedMemoryThreshold': 0.63,
        },
        'sessionBatching': <String, dynamic>{
          'minimumMergeBatchSize': 4,
          'minimumRuleScoreForSemanticCheck': 0.35,
          'topicMatchScoreFloor': 0.88,
          'ruleWeight': 0.45,
          'semanticWeight': 0.55,
          'combinedScoreThreshold': 0.78,
          'exactTitleMatchWeight': 0.32,
          'partialTitleMatchWeight': 0.18,
          'semanticSimilarityWeight': 0.28,
          'tagOverlapWeight': 0.24,
          'sameSourceWeight': 0.12,
          'shortTermTimeWeight': 0.09,
          'mediumTermTimeWeight': 0.04,
        },
      });

      expect(config.sessionMaxAge, const Duration(minutes: 90));
      expect(config.candidateProtectionWindow, const Duration(days: 2));
      expect(config.timeThresholds.shortTerm, const Duration(hours: 3));
      expect(config.timeThresholds.mediumTerm, const Duration(hours: 18));
      expect(config.forgettingCurve.startDays, 14);
      expect(config.forgettingCurve.decayPeriodDays, 45);
      expect(config.forgettingCurve.minImportance, 0.2);
      expect(config.forgettingCurve.decayRate, 0.7);
      expect(config.coreUpgrade.accessCountThreshold, 6);
      expect(config.coreUpgrade.importanceThreshold, 0.85);
      expect(config.similarity.deduplicationThreshold, 0.82);
      expect(config.similarity.relatedMemoryThreshold, 0.63);
      expect(config.sessionBatching.minimumMergeBatchSize, 4);
      expect(config.sessionBatching.minimumRuleScoreForSemanticCheck, 0.35);
      expect(config.sessionBatching.topicMatchScoreFloor, 0.88);
      expect(config.sessionBatching.ruleWeight, 0.45);
      expect(config.sessionBatching.semanticWeight, 0.55);
      expect(config.sessionBatching.combinedScoreThreshold, 0.78);
      expect(config.sessionBatching.exactTitleMatchWeight, 0.32);
      expect(config.sessionBatching.partialTitleMatchWeight, 0.18);
      expect(config.sessionBatching.semanticSimilarityWeight, 0.28);
      expect(config.sessionBatching.tagOverlapWeight, 0.24);
      expect(config.sessionBatching.sameSourceWeight, 0.12);
      expect(config.sessionBatching.shortTermTimeWeight, 0.09);
      expect(config.sessionBatching.mediumTermTimeWeight, 0.04);
    });

    test('load merges bundled config with override file', () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'memory_policy_config_test',
      );
      final overrideFile = File('${tempDirectory.path}/override.json');
      await overrideFile.writeAsString(
        '''
{
  "sessionMaxAge": {
    "minutes": 45
  },
  "coreUpgrade": {
    "accessCountThreshold": 3
  },
  "similarity": {
    "deduplicationThreshold": 0.9
  },
  "sessionBatching": {
    "combinedScoreThreshold": 0.92
  }
}
''',
      );

      try {
        final config = await MemoryPolicyConfig.load(
          overrideFileResolver: () async => overrideFile,
        );

        expect(config.sessionMaxAge, const Duration(minutes: 45));
        expect(
          config.candidateProtectionWindow,
          const Duration(hours: 24),
        );
        expect(config.coreUpgrade.accessCountThreshold, 3);
        expect(config.coreUpgrade.importanceThreshold, 0.8);
        expect(config.similarity.deduplicationThreshold, 0.9);
        expect(config.similarity.relatedMemoryThreshold, 0.5);
        expect(config.sessionBatching.combinedScoreThreshold, 0.92);
        expect(config.sessionBatching.minimumMergeBatchSize, 3);
      } finally {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      }
    });
  });
}
