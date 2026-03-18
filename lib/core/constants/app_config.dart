
class AppConfig {
  AppConfig._();

  static const bool debugMode = true;
  static const bool enableLogging = true;
  static const bool enableAnalytics = false;
  static const bool enableBackup = true;
  static const bool enableEncryption = true;
  static const int maxSummaryCount = 10000;
  static const int maxSummarySize = 1024 * 1024;
  static const int maxTagCount = 10;
  static const int maxTagLength = 20;
  static const int searchDebounceDelay = 300;
  static const int clipboardCheckInterval = 1000;
}
