import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_vault/core/constants/app_storage.dart';
import 'package:local_vault/features/summary/models/summary.dart';

class StorageInitializer {
  static Future<void> initialize() async {
    if (kIsWeb) {
      await Hive.initFlutter();
    } else {
      await Hive.initFlutter(AppStorage.hiveDirectoryName);
    }

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SummaryAdapter());
    }
  }
}
