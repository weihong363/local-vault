import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_vault/features/summary/models/summary.dart';
import 'package:local_vault/features/template/models/template.dart';

class StorageInitializer {
  static Future<void> initialize() async {
    if (kIsWeb) {
      await Hive.initFlutter();
    } else {
      await Hive.initFlutter('vault');
    }
    
    Hive.registerAdapter(SummaryAdapter());
    Hive.registerAdapter(TemplateAdapter());
  }
}
