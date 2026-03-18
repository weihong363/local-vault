import 'dart:math';

import 'package:local_vault/core/config/memory_policy_config.dart';

/// 记忆类型
enum MemoryType {
  session, // 会话记忆（临时）
  fact, // 普通事实（持久化）
  core, // 核心记忆（持久化，免受遗忘曲线影响）
}

extension MemoryTypeX on MemoryType {
  int get storageValue {
    switch (this) {
      case MemoryType.fact:
        return 0;
      case MemoryType.session:
        return 1;
      case MemoryType.core:
        return 3;
    }
  }

  static MemoryType fromStorage(dynamic rawValue) {
    if (rawValue is String) {
      switch (rawValue) {
        case 'session':
          return MemoryType.session;
        case 'fact':
          return MemoryType.fact;
        case 'core':
          return MemoryType.core;
        case 'template':
          // 兼容旧版本遗留的模板记忆，统一按 fact 读取。
          return MemoryType.fact;
      }
    }

    final intValue = switch (rawValue) {
      int value => value,
      double value => value.toInt(),
      _ => 0,
    };

    switch (intValue) {
      case 1:
        return MemoryType.session;
      case 3:
        return MemoryType.core;
      case 2:
      // 旧版 template 存储值，继续兼容读取。
      case 0:
      default:
        return MemoryType.fact;
    }
  }
}

/// 摘要实体 - 领域模型（增强版）
/// 纯 Dart 类，不依赖外部库
class SummaryEntity {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final MemoryType type;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastAccessedAt;
  final DateTime? protectedUntil;
  final String source;
  final String? topic;
  final List<double> embedding;
  final double importance;
  final int accessCount;
  final bool isAutoExtracted;
  final int sortOrder;

  SummaryEntity({
    required this.id,
    required this.title,
    required this.content,
    this.tags = const [],
    this.type = MemoryType.fact,
    required this.createdAt,
    this.updatedAt,
    this.lastAccessedAt,
    this.protectedUntil,
    this.source = 'manual',
    this.topic,
    this.embedding = const [],
    this.importance = 0.5,
    this.accessCount = 0,
    this.isAutoExtracted = false,
    this.sortOrder = 0,
  });

  factory SummaryEntity.create({
    required String title,
    required String content,
    List<String> tags = const [],
    MemoryType type = MemoryType.fact,
    String source = 'manual',
    String? topic,
    List<double> embedding = const [],
    double importance = 0.5,
    int sortOrder = 0,
  }) {
    return SummaryEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      tags: tags,
      type: type,
      createdAt: DateTime.now(),
      source: source,
      topic: topic,
      embedding: embedding,
      importance: importance,
      sortOrder: sortOrder,
    );
  }

  /// 计算时效性分数（遗忘曲线）
  double get recencyScore {
    if (type == MemoryType.core) return 1.0;
    if (lastAccessedAt == null) return 0.5;

    final daysSinceAccess = DateTime.now().difference(lastAccessedAt!).inDays;
    // 每天衰减 5%
    return pow(0.95, daysSinceAccess).toDouble();
  }

  /// 综合评分 = 重要性 * 时效性 * 访问频率
  double get combinedScore {
    if (type == MemoryType.core) return 1.0;
    final frequencyScore =
        accessCount > 0 ? 1.0 - (1.0 / (accessCount + 1)) : 0.0;
    return importance * 0.5 + recencyScore * 0.3 + frequencyScore * 0.2;
  }

  bool get shouldUpgradeToCore {
    return shouldUpgradeToCoreWithPolicy(MemoryPolicyConfig.defaults);
  }

  bool shouldUpgradeToCoreWithPolicy(MemoryPolicyConfig policyConfig) {
    if (type != MemoryType.fact) return false;
    return accessCount >= policyConfig.coreUpgrade.accessCountThreshold ||
        importance >= policyConfig.coreUpgrade.importanceThreshold;
  }

  bool get isSessionProtected {
    if (type != MemoryType.session || protectedUntil == null) return false;
    return protectedUntil!.isAfter(DateTime.now());
  }

  SummaryEntity copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    MemoryType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAccessedAt,
    DateTime? protectedUntil,
    bool clearProtectedUntil = false,
    String? source,
    String? topic,
    bool clearTopic = false,
    List<double>? embedding,
    double? importance,
    int? accessCount,
    bool? isAutoExtracted,
    int? sortOrder,
  }) {
    return SummaryEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      protectedUntil:
          clearProtectedUntil ? null : protectedUntil ?? this.protectedUntil,
      source: source ?? this.source,
      topic: clearTopic ? null : topic ?? this.topic,
      embedding: embedding ?? this.embedding,
      importance: importance ?? this.importance,
      accessCount: accessCount ?? this.accessCount,
      isAutoExtracted: isAutoExtracted ?? this.isAutoExtracted,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'tags': tags,
      'type': type.storageValue,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'protectedUntil': protectedUntil?.toIso8601String(),
      'source': source,
      'topic': topic,
      'embedding': embedding,
      'importance': importance,
      'accessCount': accessCount,
      'isAutoExtracted': isAutoExtracted,
      'sortOrder': sortOrder,
    };
  }

  factory SummaryEntity.fromJson(Map<String, dynamic> json) {
    return SummaryEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      type: MemoryTypeX.fromStorage(json['type']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'] as String)
          : null,
      protectedUntil: json['protectedUntil'] != null
          ? DateTime.parse(json['protectedUntil'] as String)
          : null,
      source: json['source'] as String? ?? 'manual',
      topic: json['topic'] as String?,
      embedding: List<double>.from(json['embedding'] ?? []),
      importance: switch (json['importance']) {
        int value => value.toDouble(),
        double value => value,
        _ => 0.5,
      },
      accessCount: switch (json['accessCount']) {
        int value => value,
        double value => value.toInt(),
        _ => 0,
      },
      isAutoExtracted: json['isAutoExtracted'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}
