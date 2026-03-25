import 'dart:convert';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_vault/core/constants/app_storage.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/entities/template_entity.dart';
import 'package:local_vault/core/domain/repositories/summary_repository_interface.dart';
import 'package:local_vault/core/domain/repositories/template_repository_interface.dart';
import 'package:local_vault/core/services/memory_slm_service.dart';
import 'package:local_vault/core/utils/json_utils.dart';
import 'package:path_provider/path_provider.dart';

class StorageUsageSnapshot {
  const StorageUsageSnapshot({
    required this.summaryCount,
    required this.templateCount,
    required this.backupFileCount,
    required this.summaryBytes,
    required this.templateBytes,
    required this.backupBytes,
    required this.modelBytes,
    required this.modelCacheBytes,
  });

  final int summaryCount;
  final int templateCount;
  final int backupFileCount;
  final int summaryBytes;
  final int templateBytes;
  final int backupBytes;
  final int modelBytes;
  final int modelCacheBytes;

  int get totalBytes =>
      summaryBytes + templateBytes + backupBytes + modelBytes + modelCacheBytes;
}

class BackupFileEntry {
  const BackupFileEntry({
    required this.file,
    required this.fileName,
    required this.modifiedAt,
    required this.bytes,
  });

  final File file;
  final String fileName;
  final DateTime modifiedAt;
  final int bytes;
}

class BackupExportResult {
  const BackupExportResult({
    required this.file,
    required this.summaryCount,
    required this.templateCount,
  });

  final File file;
  final int summaryCount;
  final int templateCount;
}

class BackupRestoreResult {
  const BackupRestoreResult({
    required this.summaryCount,
    required this.templateCount,
  });

  final int summaryCount;
  final int templateCount;
}

class BackupPreviewResult {
  const BackupPreviewResult({
    required this.schemaVersion,
    required this.summaryCount,
    required this.templateCount,
    this.exportedAt,
  });

  final int schemaVersion;
  final int summaryCount;
  final int templateCount;
  final DateTime? exportedAt;
}

class StorageCleanupResult {
  const StorageCleanupResult({
    required this.deletedFileCount,
    required this.releasedBytes,
  });

  final int deletedFileCount;
  final int releasedBytes;
}

class StorageManagementService {
  StorageManagementService({
    required SummaryRepositoryInterface summaryRepository,
    required TemplateRepositoryInterface templateRepository,
    required MemorySLMService slmService,
    Future<Directory> Function()? appSupportDirectoryResolver,
    String? Function(String boxName)? hiveBoxPathResolver,
    DateTime Function()? nowProvider,
  })  : _summaryRepository = summaryRepository,
        _templateRepository = templateRepository,
        _slmService = slmService,
        _appSupportDirectoryResolver =
            appSupportDirectoryResolver ?? getApplicationSupportDirectory,
        _hiveBoxPathResolver =
            hiveBoxPathResolver ?? _defaultHiveBoxPathResolver,
        _nowProvider = nowProvider ?? DateTime.now;

  static const JsonEncoder _prettyJson = JsonEncoder.withIndent('  ');

  final SummaryRepositoryInterface _summaryRepository;
  final TemplateRepositoryInterface _templateRepository;
  final MemorySLMService _slmService;
  final Future<Directory> Function() _appSupportDirectoryResolver;
  final String? Function(String boxName) _hiveBoxPathResolver;
  final DateTime Function() _nowProvider;

  Future<StorageUsageSnapshot> inspectStorage() async {
    final backups = await listBackups();
    final modelStorage = await _resolveModelStorage();

    return StorageUsageSnapshot(
      summaryCount: _summaryRepository.getAllSummaries().length,
      templateCount: _templateRepository.getAllTemplates().length,
      backupFileCount: backups.length,
      summaryBytes: await _sizeOfHiveBox(AppStorage.summaryBoxName),
      templateBytes: await _sizeOfHiveBox(AppStorage.templateBoxName),
      backupBytes: backups.fold<int>(0, (sum, file) => sum + file.bytes),
      modelBytes: modelStorage.modelBytes,
      modelCacheBytes: modelStorage.cacheBytes,
    );
  }

  Future<BackupExportResult> createBackup() async {
    final summaries = _summaryRepository.getAllSummaries();
    final templates = _templateRepository.getAllTemplates();
    final backupDirectory = await _ensureBackupDirectory();
    final now = _nowProvider();
    final fileName =
        '${AppStorage.backupFilePrefix}_${_formatTimestamp(now)}.json';
    final file = File('${backupDirectory.path}/$fileName');

    final payload = <String, dynamic>{
      'schemaVersion': 1,
      'exportedAt': now.toIso8601String(),
      'summaries':
          summaries.map((item) => item.toJson()).toList(growable: false),
      'templates':
          templates.map((item) => item.toJson()).toList(growable: false),
    };

    await file.writeAsString(_prettyJson.convert(payload));

    return BackupExportResult(
      file: file,
      summaryCount: summaries.length,
      templateCount: templates.length,
    );
  }

  Future<List<BackupFileEntry>> listBackups() async {
    final backupDirectory = await _ensureBackupDirectory();
    final entries = await backupDirectory.list().toList();
    final files = <BackupFileEntry>[];

    for (final entry in entries) {
      if (entry is! File || !entry.path.endsWith('.json')) {
        continue;
      }

      final stat = await entry.stat();
      files.add(
        BackupFileEntry(
          file: entry,
          fileName: entry.uri.pathSegments.isNotEmpty
              ? entry.uri.pathSegments.last
              : entry.path,
          modifiedAt: stat.modified,
          bytes: stat.size,
        ),
      );
    }

    files.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return files;
  }

  Future<BackupRestoreResult> restoreBackup(File file) async {
    final content = await file.readAsString();
    return restoreBackupContent(content);
  }

  Future<BackupPreviewResult> previewBackup(File file) async {
    final content = await file.readAsString();
    return previewBackupContent(content);
  }

  BackupPreviewResult previewBackupContent(String content) {
    final payload = _parseBackupContent(content);
    return BackupPreviewResult(
      schemaVersion: payload.schemaVersion,
      summaryCount: payload.summaries.length,
      templateCount: payload.templates.length,
      exportedAt: payload.exportedAt,
    );
  }

  Future<BackupRestoreResult> restoreBackupContent(String content) async {
    final payload = _parseBackupContent(content);
    final summaries = payload.summaries;
    final templates = payload.templates;

    await _summaryRepository.clearAll();
    await _templateRepository.clearAll();

    for (final summary in summaries) {
      await _summaryRepository.addSummary(summary);
    }
    for (final template in templates) {
      await _templateRepository.addTemplate(template);
    }

    return BackupRestoreResult(
      summaryCount: summaries.length,
      templateCount: templates.length,
    );
  }

  Future<void> deleteBackup(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<StorageCleanupResult> clearBackupFiles() async {
    final backups = await listBackups();
    var releasedBytes = 0;
    for (final entry in backups) {
      releasedBytes += entry.bytes;
      await entry.file.delete();
    }
    return StorageCleanupResult(
      deletedFileCount: backups.length,
      releasedBytes: releasedBytes,
    );
  }

  Future<StorageCleanupResult> clearModelCache() async {
    final slmConfig = await _slmService.resolveConfig();
    final appSupportDirectory = await _appSupportDirectoryResolver();
    final cacheDirectory = Directory(
      '${appSupportDirectory.path}/${slmConfig.model.cacheDirectoryName}',
    );
    if (!await cacheDirectory.exists()) {
      return const StorageCleanupResult(
        deletedFileCount: 0,
        releasedBytes: 0,
      );
    }

    final entities = await cacheDirectory.list(recursive: true).toList();
    final releasedBytes = await _sizeOfDirectory(cacheDirectory);
    await cacheDirectory.delete(recursive: true);
    await cacheDirectory.create(recursive: true);

    return StorageCleanupResult(
      deletedFileCount: entities.length,
      releasedBytes: releasedBytes,
    );
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
    }
    final mb = kb / 1024;
    if (mb < 1024) {
      return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB';
    }
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(gb >= 100 ? 0 : 1)} GB';
  }

  Future<Directory> _ensureBackupDirectory() async {
    final appSupportDirectory = await _appSupportDirectoryResolver();
    final backupDirectory = Directory(
      '${appSupportDirectory.path}/${AppStorage.backupDirectoryName}',
    );
    if (!await backupDirectory.exists()) {
      await backupDirectory.create(recursive: true);
    }
    return backupDirectory;
  }

  Future<int> _sizeOfHiveBox(String boxName) async {
    final path = _hiveBoxPathResolver(boxName);
    if (path == null || path.isEmpty) {
      return 0;
    }
    final file = File(path);
    if (!await file.exists()) {
      return 0;
    }
    return file.length();
  }

  Future<_ModelStorage> _resolveModelStorage() async {
    final slmConfig = await _slmService.resolveConfig();
    final appSupportDirectory = await _appSupportDirectoryResolver();
    final modelFile = File(
      '${appSupportDirectory.path}/${slmConfig.model.modelDirectoryName}/'
      '${slmConfig.model.bundledFileName}',
    );
    final cacheDirectory = Directory(
      '${appSupportDirectory.path}/${slmConfig.model.cacheDirectoryName}',
    );

    return _ModelStorage(
      modelBytes: await _sizeOfFile(modelFile),
      cacheBytes: await _sizeOfDirectory(cacheDirectory),
    );
  }

  Future<int> _sizeOfFile(File file) async {
    if (!await file.exists()) {
      return 0;
    }
    return file.length();
  }

  Future<int> _sizeOfDirectory(Directory directory) async {
    if (!await directory.exists()) {
      return 0;
    }

    var total = 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  _ParsedBackupPayload _parseBackupContent(String content) {
    final decoded = jsonDecode(content);
    final payload = JsonUtils.asMap(decoded);
    final schemaVersion = _parseSchemaVersion(payload['schemaVersion']);
    final exportedAt = _parseExportedAt(payload['exportedAt']);
    final summaries = _parseSummaries(payload['summaries']);
    final templates = _parseTemplates(payload['templates']);

    return _ParsedBackupPayload(
      schemaVersion: schemaVersion,
      exportedAt: exportedAt,
      summaries: summaries,
      templates: templates,
    );
  }

  int _parseSchemaVersion(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    throw const FormatException('Invalid backup file format');
  }

  DateTime? _parseExportedAt(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is! String) {
      throw const FormatException('Invalid backup file format');
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw const FormatException('Invalid backup file format');
    }
    return parsed;
  }

  List<SummaryEntity> _parseSummaries(Object? raw) {
    if (raw is! List) {
      throw const FormatException('Invalid backup file format');
    }
    return raw
        .map((item) => SummaryEntity.fromJson(JsonUtils.asMap(item)))
        .toList(growable: false);
  }

  List<TemplateEntity> _parseTemplates(Object? raw) {
    if (raw is! List) {
      throw const FormatException('Invalid backup file format');
    }
    return raw
        .map((item) => TemplateEntity.fromJson(JsonUtils.asMap(item)))
        .toList(growable: false);
  }

  static String _formatTimestamp(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$year$month${day}_$hour$minute$second';
  }

  static String? _defaultHiveBoxPathResolver(String boxName) {
    if (!Hive.isBoxOpen(boxName)) {
      return null;
    }
    return Hive.box(boxName).path;
  }
}

class _ModelStorage {
  const _ModelStorage({
    required this.modelBytes,
    required this.cacheBytes,
  });

  final int modelBytes;
  final int cacheBytes;
}

class _ParsedBackupPayload {
  const _ParsedBackupPayload({
    required this.schemaVersion,
    required this.exportedAt,
    required this.summaries,
    required this.templates,
  });

  final int schemaVersion;
  final DateTime? exportedAt;
  final List<SummaryEntity> summaries;
  final List<TemplateEntity> templates;
}
