import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/config/memory_policy_config.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';

void main() {
  group('SummaryEntity core upgrade policy', () {
    test('default getter uses centralized default thresholds', () {
      final summary = SummaryEntity.create(
        title: '默认阈值测试',
        content: '记录核心升级行为',
      ).copyWith(
        accessCount: 10,
      );

      expect(summary.shouldUpgradeToCore, isTrue);
    });

    test('custom policy overrides access count and importance thresholds', () {
      final summary = SummaryEntity.create(
        title: '自定义阈值测试',
        content: '验证可配置升级策略',
      ).copyWith(
        accessCount: 3,
        importance: 0.6,
      );

      expect(
        summary.shouldUpgradeToCoreWithPolicy(
          const MemoryPolicyConfig(
            coreUpgrade: CoreUpgradePolicy(
              accessCountThreshold: 5,
              importanceThreshold: 0.7,
            ),
          ),
        ),
        isFalse,
      );

      expect(
        summary.shouldUpgradeToCoreWithPolicy(
          const MemoryPolicyConfig(
            coreUpgrade: CoreUpgradePolicy(
              accessCountThreshold: 3,
              importanceThreshold: 0.9,
            ),
          ),
        ),
        isTrue,
      );
    });
  });
}
