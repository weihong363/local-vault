import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:local_vault/core/constants/app_storage.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/entities/template_entity.dart';

class DatabaseInspectorPage extends StatefulWidget {
  const DatabaseInspectorPage({super.key});

  @override
  State<DatabaseInspectorPage> createState() => _DatabaseInspectorPageState();
}

class _DatabaseInspectorPageState extends State<DatabaseInspectorPage> {
  static final String _summaryBoxName = AppStorage.summaryBoxName;
  static final String _templateBoxName = AppStorage.templateBoxName;
  static const JsonEncoder _jsonEncoder = JsonEncoder.withIndent('  ');

  late final Future<void> _initFuture = _ensureBoxesOpen();

  Future<void> _ensureBoxesOpen() async {
    if (!Hive.isBoxOpen(_summaryBoxName)) {
      await Hive.openBox(_summaryBoxName);
    }
    if (!Hive.isBoxOpen(_templateBoxName)) {
      await Hive.openBox(_templateBoxName);
    }
  }

  Box get _summaryBox => Hive.box(_summaryBoxName);

  Box get _templateBox => Hive.box(_templateBoxName);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('数据库查询')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('数据库打开失败: ${snapshot.error}'),
              ),
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('数据库查询'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: '刷新',
                  onPressed: () {
                    setState(() {});
                  },
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: '摘要库'),
                  Tab(text: '模板库'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildSummaryTab(),
                _buildTemplateTab(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab() {
    return ValueListenableBuilder(
      valueListenable: _summaryBox.listenable(),
      builder: (context, Box box, _) {
        final records = box.keys
            .map((key) => _inspectSummaryRecord(key, box.get(key)))
            .toList()
            .reversed
            .toList(growable: false);

        return _buildRecordList(
          boxName: _summaryBoxName,
          records: records,
          emptyText: '摘要库暂无记录',
          extraSummary: [
            '候选异常: ${records.where((record) => record.issues.isNotEmpty).length}',
            '旧模板遗留: ${records.where((record) => record.hasLegacyTemplateType).length}',
          ],
        );
      },
    );
  }

  Widget _buildTemplateTab() {
    return ValueListenableBuilder(
      valueListenable: _templateBox.listenable(),
      builder: (context, Box box, _) {
        final records = box.keys
            .map((key) => _inspectTemplateRecord(key, box.get(key)))
            .toList()
            .reversed
            .toList(growable: false);

        return _buildRecordList(
          boxName: _templateBoxName,
          records: records,
          emptyText: '模板库暂无记录',
          extraSummary: [
            '候选异常: ${records.where((record) => record.issues.isNotEmpty).length}',
            '默认模板: ${records.where((record) => record.isDefaultTemplate).length}',
          ],
        );
      },
    );
  }

  Widget _buildRecordList({
    required String boxName,
    required List<_RecordInspection> records,
    required String emptyText,
    required List<String> extraSummary,
  }) {
    if (records.isEmpty) {
      return Center(child: Text(emptyText));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMetricChip('Box: $boxName'),
            _buildMetricChip('记录数: ${records.length}'),
            for (final item in extraSummary) _buildMetricChip(item),
          ],
        ),
        const SizedBox(height: 16),
        for (final record in records) _buildRecordCard(record),
      ],
    );
  }

  Widget _buildMetricChip(String label) {
    return Chip(
      label: Text(label),
    );
  }

  Widget _buildRecordCard(_RecordInspection record) {
    final theme = Theme.of(context);
    final issueColor = record.issues.isEmpty ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          record.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(record.subtitle),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(Icons.storage, size: 16, color: issueColor),
                  label: Text('Key: ${record.keyLabel}'),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  avatar: Icon(
                    record.issues.isEmpty ? Icons.check_circle : Icons.warning,
                    size: 16,
                    color: issueColor,
                  ),
                  label: Text(
                    record.issues.isEmpty
                        ? '未发现明显异常'
                        : '异常提示 ${record.issues.length}',
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (record.issues.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: record.issues
                    .map((issue) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(issue),
                        ))
                    .toList(growable: false),
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              record.prettyJson,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _copyText(record.prettyJson),
              icon: const Icon(Icons.copy),
              label: const Text('复制 JSON'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }

  _RecordInspection _inspectSummaryRecord(dynamic key, dynamic value) {
    final issues = <String>[];
    final map = _safeMap(value);

    if (map == null) {
      issues.add('记录不是 Map 结构，可能是损坏数据');
      return _RecordInspection(
        keyLabel: '$key',
        title: '无法解析的摘要记录',
        subtitle: '原始类型: ${value.runtimeType}',
        issues: issues,
        prettyJson: _encodeRaw(value),
      );
    }

    final rawType = map['type'];
    final hasLegacyTemplateType = rawType == 2 || rawType == 'template';
    if (hasLegacyTemplateType) {
      issues.add('发现旧版 template 类型记录，当前会按 fact 兼容读取');
    }
    if ((map['id'] as String?)?.isEmpty ?? true) {
      issues.add('缺少 id');
    }
    if ((map['title'] as String?)?.trim().isEmpty ?? true) {
      issues.add('标题为空');
    }
    if ((map['content'] as String?)?.trim().isEmpty ?? true) {
      issues.add('内容为空');
    }

    final accessCount = _parseInt(map['accessCount']);
    if (accessCount == null) {
      issues.add('accessCount 不是有效数字');
    } else if (accessCount < 0) {
      issues.add('accessCount 小于 0');
    }

    DateTime? createdAt;
    try {
      createdAt = DateTime.parse(map['createdAt'] as String);
    } catch (_) {
      issues.add('createdAt 无法解析');
    }

    try {
      SummaryEntity.fromJson(map);
    } catch (error) {
      issues.add('SummaryEntity 反序列化失败: $error');
    }

    final typeLabel = _summaryTypeLabel(rawType);
    final createdLabel = createdAt == null
        ? '时间未知'
        : DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt);

    return _RecordInspection(
      keyLabel: '$key',
      title: (map['title'] as String?)?.trim().isNotEmpty == true
          ? map['title'] as String
          : '(无标题摘要)',
      subtitle: '类型: $typeLabel  访问: ${accessCount ?? '-'}  创建: $createdLabel',
      issues: issues,
      prettyJson: _encodeRaw(map),
      hasLegacyTemplateType: hasLegacyTemplateType,
    );
  }

  _RecordInspection _inspectTemplateRecord(dynamic key, dynamic value) {
    final issues = <String>[];
    final map = _safeMap(value);

    if (map == null) {
      issues.add('记录不是 Map 结构，可能是损坏数据');
      return _RecordInspection(
        keyLabel: '$key',
        title: '无法解析的模板记录',
        subtitle: '原始类型: ${value.runtimeType}',
        issues: issues,
        prettyJson: _encodeRaw(value),
      );
    }

    final id = map['id'] as String?;
    final isDefaultTemplate = id?.startsWith('default_') ?? false;

    if (id?.isEmpty ?? true) {
      issues.add('缺少 id');
    }
    if ((map['title'] as String?)?.trim().isEmpty ?? true) {
      issues.add('标题为空');
    }
    if ((map['content'] as String?)?.trim().isEmpty ?? true) {
      issues.add('内容为空');
    }

    try {
      TemplateEntity(
        id: map['id'] as String,
        title: map['title'] as String,
        content: map['content'] as String,
        tags: _parseTags(map['tags']),
        createdAt: _parseDate(map['createdAt']),
        updatedAt:
            map['updatedAt'] == null ? null : _parseDate(map['updatedAt']),
      );
    } catch (error) {
      issues.add('TemplateEntity 反序列化失败: $error');
    }

    final createdAt = _tryParseDate(map['createdAt']);
    final createdLabel = createdAt == null
        ? '时间未知'
        : DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt);

    return _RecordInspection(
      keyLabel: '$key',
      title: (map['title'] as String?)?.trim().isNotEmpty == true
          ? map['title'] as String
          : '(无标题模板)',
      subtitle: '${isDefaultTemplate ? "默认模板" : "自定义模板"}  创建: $createdLabel',
      issues: issues,
      prettyJson: _encodeRaw(map),
      isDefaultTemplate: isDefaultTemplate,
    );
  }

  Map<String, dynamic>? _safeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  String _encodeRaw(dynamic value) {
    try {
      return _jsonEncoder.convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  String _summaryTypeLabel(dynamic rawType) {
    try {
      return MemoryTypeX.fromStorage(rawType).name;
    } catch (_) {
      return 'unknown($rawType)';
    }
  }

  DateTime? _tryParseDate(dynamic value) {
    try {
      return _parseDate(value);
    } catch (_) {
      return null;
    }
  }

  DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    throw ArgumentError('invalid date: $value');
  }

  List<String> _parseTags(dynamic raw) {
    if (raw == null) {
      return const [];
    }
    if (raw is List) {
      return raw.map((item) => item.toString()).toList(growable: false);
    }
    if (raw is String) {
      return raw
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }
}

class _RecordInspection {
  const _RecordInspection({
    required this.keyLabel,
    required this.title,
    required this.subtitle,
    required this.issues,
    required this.prettyJson,
    this.hasLegacyTemplateType = false,
    this.isDefaultTemplate = false,
  });

  final String keyLabel;
  final String title;
  final String subtitle;
  final List<String> issues;
  final String prettyJson;
  final bool hasLegacyTemplateType;
  final bool isDefaultTemplate;
}
