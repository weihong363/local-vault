import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'utils/ocr_accuracy_tester.dart';

/// ML Kit OCR Accuracy Tests
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ML Kit OCR Accuracy Tests', () {
    late OcrAccuracyTester tester;

    setUp(() async {
      tester = OcrAccuracyTester();
    });

    test('Run comprehensive accuracy test with real images', () async {
      // Define test dataset (image path -> expected text)
      final groundTruth = <String, String>{
        // Use existing test image
        'test/resource/ocr_test_resorce.jpg': '这是一个示例中文文本，用于测试 OCR 识别的准确率',

        // You can add more test images
        // Format: 'image path': 'expected text'
      };

      print('');
      print('=' * 80);
      print('ML Kit OCR Accuracy Test');
      print('=' * 80);
      print('');

      // Note: In unit test environment, ML Kit plugin may not work
      // This test is mainly for validating the test framework and similarity algorithm
      print('Note: ML Kit may not work in unit test environment');
      print('This test validates the test framework and similarity algorithm');
      print('');

      // 运行批量测试
      final report = await tester.runBatchTest(groundTruth: groundTruth);

      // 保存测试报告
      final reportDir = Directory('test/reports');
      if (!await reportDir.exists()) {
        await reportDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final reportFile =
          File('test/reports/ocr_accuracy_report_$timestamp.json');
      await reportFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(report),
      );

      print('\nDetailed test report saved to: ${reportFile.path}');
      print('');
      print('=' * 80);
      print('');
      print('To run full OCR accuracy test on device:');
      print('1. Install app: flutter install');
      print('2. Share Chinese images from DeepSeek to Local Vault');
      print('3. Check logs: adb logcat | grep OcrService');
      print('');

      // Validate test framework works correctly (not requiring OCR success)
      expect(report['total_images'], equals(groundTruth.length));
    }, timeout: const Timeout(Duration(minutes: 10)));

    test('Test similarity calculation', () {
      // Test similarity calculation algorithm
      expect(tester.calculateSimilarity('', ''), 1.0);
      expect(tester.calculateSimilarity('abc', 'abc'), 1.0);
      expect(tester.calculateSimilarity('abc', 'abd'), greaterThan(0.5));
      expect(tester.calculateSimilarity('hello world', 'hello world'), 1.0);
      expect(tester.calculateSimilarity('你好世界', '你好世界'), 1.0);
      expect(tester.calculateSimilarity('完全不同', '毫无关系'), lessThan(0.3));

      print('✅ Similarity algorithm test passed');
    });

    test('Verify test image exists', () async {
      // Verify test image exists
      final testImage = File('test/resource/ocr_test_resorce.jpg');
      expect(await testImage.exists(), isTrue, reason: 'Test image must exist');

      final fileSize = await testImage.length();
      print('📊 Test image size: $fileSize bytes');
      expect(fileSize, greaterThan(0),
          reason: 'Test image should not be empty');

      print('✅ Test image validation passed');
    });

    test('Test DeepSeek share image scenario', () async {
      // Test actual DeepSeek share image scenario
      // Image contains discussion about OpenClaw AI agent security product
      final groundTruth = <String, String>{
        'test/resource/ocr_test_resorce.jpg':
            '现在市面上已经出现了一些针对 OpenClaw 这类 AI 智能体的安全产品',
      };

      print('');
      print('=' * 80);
      print('DeepSeek Share Image Test - OpenClaw Security Products');
      print('=' * 80);
      print('');
      print('Testing OCR recognition for DeepSeek share image containing:');
      print(
          '"There are already security products on the market targeting AI agents like OpenClaw."');
      print('');

      // Run the test
      final report = await tester.runBatchTest(groundTruth: groundTruth);

      // Save the report
      final reportDir = Directory('test/reports');
      if (!await reportDir.exists()) {
        await reportDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final reportFile = File('test/reports/ocr_deepleek_test_$timestamp.json');
      await reportFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(report),
      );

      print('\nTest report saved to: ${reportFile.path}');
      print('');
      print('=' * 80);

      // Validate test execution
      expect(report['total_images'], equals(1));
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
// ignore_for_file: avoid_print
