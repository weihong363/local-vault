import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_vault/infrastructure/repositories/hive_state_repository.dart';
import 'package:local_vault/core/memory_runtime/repositories/state_repository.dart';

void main() {
  late Directory tempDir;
  late HiveStateRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_state_repo_test');
    Hive.init(tempDir.path);
    repository = HiveStateRepository();
    await repository.init();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('idempotent overwrite keeps stable state value', () async {
    const key = 'task::followup';
    final value = <String, dynamic>{
      'namespace': 'task',
      'key': 'followup',
      'summary': 'Remember to send report',
      'topic': 'work',
      'keywords': ['report', 'followup'],
      'importance': 0.7,
      'version': 1,
      'updatedAt': '2026-04-08T00:00:00.000Z',
    };

    await repository.applyUpdates([StateUpdate.overwrite(key, value)]);
    await repository.applyUpdates([StateUpdate.overwrite(key, value)]);

    expect(repository.get(key), equals(value));
  });

  test('dedup no-op does not write when partial values are unchanged', () async {
    const key = 'task::stable';
    final value = <String, dynamic>{
      'namespace': 'task',
      'key': 'stable',
      'summary': 'No change summary',
      'topic': 'work',
      'keywords': ['stable'],
      'importance': 0.6,
      'version': 1,
      'updatedAt': '2026-04-08T00:00:00.000Z',
    };

    await repository.set(key, value);
    final before = repository.get(key);

    await repository.applyUpdates([
      StateUpdate.dedup(key, {'summary': 'No change summary'}),
    ]);

    final after = repository.get(key);
    expect(after, equals(before));
  });

  test('defer update intentionally skips writes', () async {
    const key = 'task::defer';
    final value = <String, dynamic>{
      'namespace': 'task',
      'key': 'defer',
      'summary': 'Existing summary',
      'topic': 'work',
      'keywords': ['defer'],
      'importance': 0.5,
      'version': 1,
      'updatedAt': '2026-04-08T00:00:00.000Z',
    };

    await repository.set(key, value);
    await repository.applyUpdates([StateUpdate.defer(key)]);

    expect(repository.get(key), equals(value));
  });
}
