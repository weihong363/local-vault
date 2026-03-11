import 'dart:math';

/// 记忆类型
enum MemoryType {
  fact,        // 用户事实（持久化）
  session,     // 会话记忆（临时）
  template,    // 模板记忆
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
  final String source;
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
    this.source = 'manual',
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
      embedding: embedding,
      importance: importance,
      sortOrder: sortOrder,
    );
  }

  /// 计算时效性分数（遗忘曲线）
  double get recencyScore {
    if (lastAccessedAt == null) return 0.5;
    
    final daysSinceAccess = DateTime.now().difference(lastAccessedAt!).inDays;
    // 每天衰减 5%
    return pow(0.95, daysSinceAccess).toDouble();
  }

  /// 综合评分 = 重要性 * 时效性 * 访问频率
  double get combinedScore {
    final frequencyScore = accessCount > 0 ? 1.0 - (1.0 / (accessCount + 1)) : 0.0;
    return importance * 0.5 + recencyScore * 0.3 + frequencyScore * 0.2;
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
    String? source,
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
      source: source ?? this.source,
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
      'type': type.index,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'source': source,
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
      type: MemoryType.values[json['type'] as int? ?? 0],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'] as String)
          : null,
      source: json['source'] as String? ?? 'manual',
      embedding: List<double>.from(json['embedding'] ?? []),
      importance: json['importance'] as double? ?? 0.5,
      accessCount: json['accessCount'] as int? ?? 0,
      isAutoExtracted: json['isAutoExtracted'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}
