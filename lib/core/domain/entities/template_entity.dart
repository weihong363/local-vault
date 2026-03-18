/// 模板实体 - 领域模型
class TemplateEntity {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TemplateEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.createdAt,
    this.updatedAt,
  });

  factory TemplateEntity.create({
    required String title,
    required String content,
    List<String> tags = const [],
  }) {
    return TemplateEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      tags: tags,
      createdAt: DateTime.now(),
    );
  }

  TemplateEntity copyWith({
    String? title,
    String? content,
    List<String>? tags,
    DateTime? updatedAt,
  }) {
    return TemplateEntity(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'content': content,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory TemplateEntity.fromJson(Map<String, dynamic> json) {
    return TemplateEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      tags: List<String>.from(json['tags'] ?? const <String>[]),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}
