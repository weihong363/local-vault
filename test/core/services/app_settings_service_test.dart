import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/services/app_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppSettingsService', () {
    test('SLM inference preference defaults to disabled', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final service = AppSettingsService();

      expect(await service.isSlmInferenceEnabled(), isFalse);
    });

    test('SLM inference preference persists updates', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final service = AppSettingsService();

      await service.setSlmInferenceEnabled(true);
      expect(await service.isSlmInferenceEnabled(), isTrue);

      await service.setSlmInferenceEnabled(false);
      expect(await service.isSlmInferenceEnabled(), isFalse);
    });
  });
}
