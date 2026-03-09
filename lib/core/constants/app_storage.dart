
class AppStorage {
  AppStorage._();

  static const String _storagePath = 'local_vault';
  static const String _databaseName = 'local_vault.db';
  static const int _databaseVersion = 1;
  static const int _tableVersion = 1;

  static String get storagePath => _storagePath;
  static String get databaseName => _databaseName;
  static int get databaseVersion => _databaseVersion;
  static int get tableVersion => _tableVersion;
}
