import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

part 'summary.g.dart';

@HiveType(typeId: 0)
class Summary {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final List<String> tags;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime? updatedAt;

  @HiveField(6)
  final String source;

  @HiveField(7)
  final List<double> embedding;

  @HiveField(8)
  final int sortOrder;

  Summary({
    required this.id,
    required this.title,
    required this.content,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
    this.source = 'manual',
    this.embedding = const [],
    this.sortOrder = 0,
  });

  factory Summary.create({
    required String title,
    required String content,
    List<String> tags = const [],
    String source = 'manual',
    List<double> embedding = const [],
    int sortOrder = 0,
  }) {
    return Summary(
      id: const Uuid().v4(),
      title: title,
      content: content,
      tags: tags,
      createdAt: DateTime.now(),
      source: source,
      embedding: embedding,
      sortOrder: sortOrder,
    );
  }

  Summary copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? source,
    List<double>? embedding,
    int? sortOrder,
  }) {
    return Summary(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      embedding: embedding ?? this.embedding,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'source': source,
      'embedding': embedding,
      'sortOrder': sortOrder,
    };
  }

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      source: json['source'] as String? ?? 'manual',
      embedding: List<double>.from(json['embedding'] ?? []),
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}
