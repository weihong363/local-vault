class AppStorage {
  AppStorage._();

  static const String _storagePath = 'local_vault';
  static const String _databaseName = 'local_vault.db';
  static const int _databaseVersion = 1;
  static const int _tableVersion = 1;
  static const String _hiveDirectoryName = 'vault';
  static const String _summaryBoxName = 'summaries_v3';
  static const String _templateBoxName = 'templates_v2';
  static const String _memoryStateBoxName = 'memory_states_v1';
  static const String _memoryUnitBoxName = 'memory_units_v1';
  static const String _memoryArchiveBoxName = 'memory_archive_v1';
  static const String _memoryPromotionBoxName = 'memory_promotion_v1';
  static const String _backupDirectoryName = 'backups';
  static const String _backupFilePrefix = 'local_vault_backup';

  static String get storagePath => _storagePath;
  static String get databaseName => _databaseName;
  static int get databaseVersion => _databaseVersion;
  static int get tableVersion => _tableVersion;

  static String get hiveDirectoryName => _hiveDirectoryName;

  static String get summaryBoxName => _summaryBoxName;

  static String get templateBoxName => _templateBoxName;

  static String get memoryStateBoxName => _memoryStateBoxName;

  static String get memoryUnitBoxName => _memoryUnitBoxName;

  static String get memoryArchiveBoxName => _memoryArchiveBoxName;

  static String get memoryPromotionBoxName => _memoryPromotionBoxName;

  static String get backupDirectoryName => _backupDirectoryName;

  static String get backupFilePrefix => _backupFilePrefix;
}
