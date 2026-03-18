import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/entities/template_entity.dart';
import 'package:local_vault/core/domain/repositories/summary_repository_interface.dart';
import 'package:local_vault/core/domain/repositories/template_repository_interface.dart';
import 'package:local_vault/core/services/memory_slm_config.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
import 'package:local_vault/core/services/storage_management_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(const <String, Object>{});

  group('StorageManagementService', () {
    late _InMemorySummaryRepository summaryRepository;
    late _InMemoryTemplateRepository templateRepository;
    late Directory tempDirectory;
    late StorageManagementService service;

    setUp(() async {
      summaryRepository = _InMemorySummaryRepository();
      templateRepository = _InMemoryTemplateRepository();
      tempDirectory = await Directory.systemTemp.createTemp(
        'storage_management_service_test',
      );
      service = StorageManagementService(
        summaryRepository: summaryRepository,
        templateRepository: templateRepository,
        slmService: _FakeMemorySlmService(),
        appSupportDirectoryResolver: () async => tempDirectory,
        hiveBoxPathResolver: (boxName) {
          return '${tempDirectory.path}/$boxName.hive';
        },
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('createBackup writes backup file and lists it', () async {
      await summaryRepository.addSummary(
        SummaryEntity.create(
          title: '会议纪要',
          content: '确认发布节奏',
        ),
      );
      await templateRepository.addTemplate(
        TemplateEntity.create(
          title: '快速摘要',
          content: '请总结：{{content}}',
        ),
      );

      final result = await service.createBackup();
      final backups = await service.listBackups();

      expect(await result.file.exists(), isTrue);
      expect(result.summaryCount, 1);
      expect(result.templateCount, 1);
      expect(backups, hasLength(1));
      expect(backups.single.file.path, result.file.path);
    });

    test('restoreBackupContent replaces existing summaries and templates',
        () async {
      await summaryRepository.addSummary(
        SummaryEntity.create(
          title: '旧数据',
          content: '需要被覆盖',
        ),
      );
      await templateRepository.addTemplate(
        TemplateEntity.create(
          title: '旧模板',
          content: '需要被覆盖',
        ),
      );

      const backupContent = '''
{
  "schemaVersion": 1,
  "exportedAt": "2026-03-18T10:00:00.000Z",
  "summaries": [
    {
      "id": "summary_1",
      "title": "恢复后的摘要",
      "content": "新的内容",
      "tags": ["恢复"],
      "type": 0,
      "createdAt": "2026-03-18T10:00:00.000Z",
      "source": "manual",
      "embedding": [],
      "importance": 0.5,
      "accessCount": 0,
      "isAutoExtracted": false,
      "sortOrder": 0
    }
  ],
  "templates": [
    {
      "id": "template_1",
      "title": "恢复后的模板",
      "content": "模板内容",
      "tags": ["恢复"],
      "createdAt": "2026-03-18T10:00:00.000Z",
      "updatedAt": null
    }
  ]
}
''';

      final result = await service.restoreBackupContent(backupContent);

      expect(result.summaryCount, 1);
      expect(result.templateCount, 1);
      expect(summaryRepository.getAllSummaries(), hasLength(1));
      expect(summaryRepository.getAllSummaries().single.title, '恢复后的摘要');
      expect(templateRepository.getAllTemplates(), hasLength(1));
      expect(templateRepository.getAllTemplates().single.title, '恢复后的模板');
    });

    test('previewBackupContent returns counts before restore', () async {
      const backupContent = '''
{
  "schemaVersion": 1,
  "exportedAt": "2026-03-18T10:00:00.000Z",
  "summaries": [
    {
      "id": "summary_1",
      "title": "恢复后的摘要",
      "content": "新的内容",
      "tags": [],
      "type": 0,
      "createdAt": "2026-03-18T10:00:00.000Z",
      "source": "manual",
      "embedding": [],
      "importance": 0.5,
      "accessCount": 0,
      "isAutoExtracted": false,
      "sortOrder": 0
    }
  ],
  "templates": []
}
''';

      final preview = service.previewBackupContent(backupContent);

      expect(preview.schemaVersion, 1);
      expect(preview.summaryCount, 1);
      expect(preview.templateCount, 0);
      expect(preview.exportedAt, DateTime.parse('2026-03-18T10:00:00.000Z'));
    });

    test('restoreBackupContent throws FormatException for invalid backup',
        () async {
      const invalidBackupContent = '''
{
  "schemaVersion": 1,
  "exportedAt": "2026-03-18T10:00:00.000Z",
  "summaries": "not-a-list",
  "templates": []
}
''';

      expect(
        () => service.restoreBackupContent(invalidBackupContent),
        throwsA(isA<FormatException>()),
      );
    });

    test('inspectStorage reports box, backup, model and cache sizes', () async {
      await summaryRepository.addSummary(
        SummaryEntity.create(title: 'A', content: 'B'),
      );
      await templateRepository.addTemplate(
        TemplateEntity.create(title: 'T', content: 'C'),
      );

      await File('${tempDirectory.path}/summaries_v3.hive')
          .writeAsBytes(List<int>.filled(120, 1));
      await File('${tempDirectory.path}/templates_v2.hive')
          .writeAsBytes(List<int>.filled(80, 1));

      final backupResult = await service.createBackup();
      final modelDirectory = Directory('${tempDirectory.path}/models');
      await modelDirectory.create(recursive: true);
      await File(
        '${modelDirectory.path}/qwen2.5-0.5b-instruct-q4_k_m.gguf',
      ).writeAsBytes(List<int>.filled(200, 1));
      final cacheDirectory = Directory('${tempDirectory.path}/mediapipe_cache');
      await cacheDirectory.create(recursive: true);
      await File('${cacheDirectory.path}/cache.bin')
          .writeAsBytes(List<int>.filled(50, 1));

      final usage = await service.inspectStorage();

      expect(usage.summaryCount, 1);
      expect(usage.templateCount, 1);
      expect(usage.summaryBytes, 120);
      expect(usage.templateBytes, 80);
      expect(usage.modelBytes, 200);
      expect(usage.modelCacheBytes, 50);
      expect(usage.backupFileCount, 1);
      expect(usage.backupBytes,
          greaterThanOrEqualTo(backupResult.file.lengthSync()));
    });

    test('clearBackupFiles removes generated backups', () async {
      await service.createBackup();
      final result = await service.clearBackupFiles();

      expect(result.deletedFileCount, 1);
      expect(await service.listBackups(), isEmpty);
    });
  });
}

class _FakeMemorySlmService extends MemorySLMService {
  @override
  Future<MemorySlmConfig> resolveConfig() async => MemorySlmConfig.fallback;
}

class _InMemorySummaryRepository implements SummaryRepositoryInterface {
  final Map<String, SummaryEntity> _items = <String, SummaryEntity>{};

  @override
  Future<void> addSummary(SummaryEntity summary) async {
    _items[summary.id] = summary;
  }

  @override
  Future<void> clearAll() async {
    _items.clear();
  }

  @override
  Future<void> deleteSummary(String id) async {
    _items.remove(id);
  }

  @override
  SummaryEntity? getSummary(String id) => _items[id];

  @override
  List<SummaryEntity> getAllSummaries() => _items.values.toList();

  @override
  List<SummaryEntity> getSummariesBySource(String source) {
    return _items.values.where((summary) => summary.source == source).toList();
  }

  @override
  List<SummaryEntity> getSummariesByTag(String tag) {
    return _items.values
        .where((summary) => summary.tags.contains(tag))
        .toList();
  }

  @override
  List<SummaryEntity> getSummariesByType(MemoryType type) {
    return _items.values.where((summary) => summary.type == type).toList();
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> recordAccess(String id) async {}

  @override
  List<SummaryEntity> searchSummaries(String query) => _items.values.toList();

  @override
  int get totalCount => _items.length;

  @override
  Future<void> updateImportance(String id, double importance) async {}

  @override
  Future<void> updateSortOrders(List<SummaryEntity> summaries) async {}

  @override
  Future<void> updateSummary(SummaryEntity summary) async {
    _items[summary.id] = summary;
  }
}

class _InMemoryTemplateRepository implements TemplateRepositoryInterface {
  final Map<String, TemplateEntity> _items = <String, TemplateEntity>{};

  @override
  Future<void> addTemplate(TemplateEntity template) async {
    _items[template.id] = template;
  }

  @override
  Future<void> clearAll() async {
    _items.clear();
  }

  @override
  Future<void> deleteTemplate(String id) async {
    _items.remove(id);
  }

  @override
  List<TemplateEntity> getAllTemplates() => _items.values.toList();

  @override
  TemplateEntity? getTemplate(String id) => _items[id];

  @override
  Future<void> init() async {}

  @override
  List<TemplateEntity> searchTemplates(String query) => _items.values.toList();

  @override
  Future<void> updateTemplate(TemplateEntity template) async {
    _items[template.id] = template;
  }
}
