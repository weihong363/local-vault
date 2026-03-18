import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:local_vault/core/constants/app_storage.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/entities/template_entity.dart';
import 'package:local_vault/l10n/app_localizations.dart';

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
    final loc = AppLocalizations.of(context)!;
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
            appBar: AppBar(title: Text(loc.databaseInspector)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(loc.failedToOpenDatabase('${snapshot.error}')),
              ),
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(loc.databaseInspector),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: loc.refresh,
                  onPressed: () {
                    setState(() {});
                  },
                ),
              ],
              bottom: TabBar(
                tabs: [
                  Tab(text: loc.summariesTab),
                  Tab(text: loc.templatesTab),
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
    final loc = AppLocalizations.of(context)!;
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
          emptyText: loc.noSummaryRecordsInBox,
          extraSummary: [
            loc.recordsWithIssues(
              '${records.where((record) => record.issues.isNotEmpty).length}',
            ),
            loc.legacyTemplateTypes(
              '${records.where((record) => record.hasLegacyTemplateType).length}',
            ),
          ],
        );
      },
    );
  }

  Widget _buildTemplateTab() {
    final loc = AppLocalizations.of(context)!;
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
          emptyText: loc.noTemplateRecordsInBox,
          extraSummary: [
            loc.recordsWithIssues(
              '${records.where((record) => record.issues.isNotEmpty).length}',
            ),
            loc.defaultTemplatesCount(
              '${records.where((record) => record.isDefaultTemplate).length}',
            ),
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
    final loc = AppLocalizations.of(context)!;
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
            _buildMetricChip(loc.boxMetricLabel(boxName)),
            _buildMetricChip(loc.recordsMetricLabel('${records.length}')),
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
    final loc = AppLocalizations.of(context)!;
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
                  label: Text(loc.keyMetricLabel(record.keyLabel)),
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
                        ? loc.noObviousIssuesDetected
                        : loc.issuesMetricLabel('${record.issues.length}'),
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
              label: Text(loc.copyJson),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyText(String text) async {
    final loc = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.copiedToClipboard)),
    );
  }

  _RecordInspection _inspectSummaryRecord(dynamic key, dynamic value) {
    final loc = AppLocalizations.of(context)!;
    final issues = <String>[];
    final map = _safeMap(value);

    if (map == null) {
      issues.add(loc.recordNotMapCorrupted);
      return _RecordInspection(
        keyLabel: '$key',
        title: loc.unparseableSummaryRecord,
        subtitle: loc.rawTypeLabel('${value.runtimeType}'),
        issues: issues,
        prettyJson: _encodeRaw(value),
      );
    }

    final rawType = map['type'];
    final hasLegacyTemplateType = rawType == 2 || rawType == 'template';
    if (hasLegacyTemplateType) {
      issues.add(loc.legacyTemplateRecordDetected);
    }
    if ((map['id'] as String?)?.isEmpty ?? true) {
      issues.add(loc.missingId);
    }
    if ((map['title'] as String?)?.trim().isEmpty ?? true) {
      issues.add(loc.titleIsEmpty);
    }
    if ((map['content'] as String?)?.trim().isEmpty ?? true) {
      issues.add(loc.contentIsEmpty);
    }

    final accessCount = _parseInt(map['accessCount']);
    if (accessCount == null) {
      issues.add(loc.accessCountInvalid);
    } else if (accessCount < 0) {
      issues.add(loc.accessCountBelowZero);
    }

    DateTime? createdAt;
    try {
      createdAt = DateTime.parse(map['createdAt'] as String);
    } catch (_) {
      issues.add(loc.createdAtCouldNotBeParsed);
    }

    try {
      SummaryEntity.fromJson(map);
    } catch (error) {
      issues.add(loc.summaryDeserializationFailed('$error'));
    }

    final typeLabel = _summaryTypeLabel(rawType);
    final createdLabel = createdAt == null
        ? loc.unknownTime
        : DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt);

    return _RecordInspection(
      keyLabel: '$key',
      title: (map['title'] as String?)?.trim().isNotEmpty == true
          ? map['title'] as String
          : loc.untitledSummary,
      subtitle: loc.summaryRecordSubtitle(
        typeLabel,
        '${accessCount ?? '-'}',
        createdLabel,
      ),
      issues: issues,
      prettyJson: _encodeRaw(map),
      hasLegacyTemplateType: hasLegacyTemplateType,
    );
  }

  _RecordInspection _inspectTemplateRecord(dynamic key, dynamic value) {
    final loc = AppLocalizations.of(context)!;
    final issues = <String>[];
    final map = _safeMap(value);

    if (map == null) {
      issues.add(loc.recordNotMapCorrupted);
      return _RecordInspection(
        keyLabel: '$key',
        title: loc.unparseableTemplateRecord,
        subtitle: loc.rawTypeLabel('${value.runtimeType}'),
        issues: issues,
        prettyJson: _encodeRaw(value),
      );
    }

    final id = map['id'] as String?;
    final isDefaultTemplate = id?.startsWith('default_') ?? false;

    if (id?.isEmpty ?? true) {
      issues.add(loc.missingId);
    }
    if ((map['title'] as String?)?.trim().isEmpty ?? true) {
      issues.add(loc.titleIsEmpty);
    }
    if ((map['content'] as String?)?.trim().isEmpty ?? true) {
      issues.add(loc.contentIsEmpty);
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
      issues.add(loc.templateDeserializationFailed('$error'));
    }

    final createdAt = _tryParseDate(map['createdAt']);
    final createdLabel = createdAt == null
        ? loc.unknownTime
        : DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt);

    return _RecordInspection(
      keyLabel: '$key',
      title: (map['title'] as String?)?.trim().isNotEmpty == true
          ? map['title'] as String
          : loc.untitledTemplate,
      subtitle: loc.templateRecordSubtitle(
        isDefaultTemplate ? loc.defaultTemplateLabel : loc.customTemplateLabel,
        createdLabel,
      ),
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
    final loc = AppLocalizations.of(context)!;
    try {
      final type = MemoryTypeX.fromStorage(rawType);
      switch (type) {
        case MemoryType.fact:
          return loc.factMemoryLabel;
        case MemoryType.core:
          return loc.coreMemoryLabel;
        case MemoryType.session:
          return loc.sessionMemoryLabel;
      }
    } catch (_) {
      return '${loc.unknownValue}($rawType)';
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
