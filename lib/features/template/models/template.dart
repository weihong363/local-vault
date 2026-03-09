import 'package:hive/hive.dart';

part 'template.g.dart';

@HiveType(typeId: 1)
class Template extends HiveObject {
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
  DateTime? updatedAt;

  Template({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.createdAt,
    this.updatedAt,
  });

  factory Template.create({
    required String title,
    required String content,
    List<String> tags = const [],
  }) {
    return Template(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      tags: tags,
      createdAt: DateTime.now(),
    );
  }

  Template copyWith({
    String? title,
    String? content,
    List<String>? tags,
    DateTime? updatedAt,
  }) {
    return Template(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
