import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  AppSettingsService({
    Future<SharedPreferences>? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance();

  static const String _floatingWindowEnabledKey = 'floating_window_enabled';
  static const String _slmInferenceEnabledKey = 'slm_inference_enabled';
  static const String _summaryMetadataPreviewEnabledKey =
      'summary_metadata_preview_enabled';

  final Future<SharedPreferences> _preferences;

  Future<bool> isFloatingWindowEnabled() async {
    final prefs = await _preferences;
    return prefs.getBool(_floatingWindowEnabledKey) ?? false;
  }

  Future<void> setFloatingWindowEnabled(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(_floatingWindowEnabledKey, enabled);
  }

  Future<bool> isSlmInferenceEnabled() async {
    final prefs = await _preferences;
    return prefs.getBool(_slmInferenceEnabledKey) ?? false;
  }

  Future<void> setSlmInferenceEnabled(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(_slmInferenceEnabledKey, enabled);
  }

  Future<bool> isSummaryMetadataPreviewEnabled() async {
    final prefs = await _preferences;
    return prefs.getBool(_summaryMetadataPreviewEnabledKey) ?? false;
  }

  Future<void> setSummaryMetadataPreviewEnabled(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(_summaryMetadataPreviewEnabledKey, enabled);
  }
}
