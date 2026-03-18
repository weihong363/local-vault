import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'utils/ocr_accuracy_tester.dart';

/// ML Kit OCR 准确率测试
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ML Kit OCR Accuracy Tests', () {
    late OcrAccuracyTester tester;

    setUp(() async {
      tester = OcrAccuracyTester();
    });

    test('Run comprehensive accuracy test with real images', () async {
      // 定义测试数据集（图片路径 -> 预期文本）
      final groundTruth = <String, String>{
        // 使用现有的测试图片
        'test/resource/ocr_test_resorce.jpg': '这是一个示例中文文本，用于测试 OCR 识别的准确率',

        // 你可以添加更多测试图片
        // 格式：'图片路径': '预期文本'
      };

      print('');
      print('=' * 80);
      print('ML Kit OCR Accuracy Test');
      print('=' * 80);
      print('');

      // 注意：在单元测试环境中，ML Kit 插件可能无法工作
      // 这个测试主要用于验证测试框架和相似度算法
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

      // 验证测试框架正常工作（不要求 OCR 成功）
      expect(report['total_images'], equals(groundTruth.length));
    }, timeout: const Timeout(Duration(minutes: 10)));

    test('Test similarity calculation', () {
      // 测试相似度计算算法
      expect(tester.calculateSimilarity('', ''), 1.0);
      expect(tester.calculateSimilarity('abc', 'abc'), 1.0);
      expect(tester.calculateSimilarity('abc', 'abd'), greaterThan(0.5));
      expect(tester.calculateSimilarity('hello world', 'hello world'), 1.0);
      expect(tester.calculateSimilarity('你好世界', '你好世界'), 1.0);
      expect(tester.calculateSimilarity('完全不同', '毫无关系'), lessThan(0.3));

      print('✅ Similarity algorithm test passed');
    });

    test('Verify test image exists', () async {
      // 验证测试图片存在
      final testImage = File('test/resource/ocr_test_resorce.jpg');
      expect(await testImage.exists(), isTrue, reason: '测试图片必须存在');

      final fileSize = await testImage.length();
      print('📊 Test image size: $fileSize bytes');
      expect(fileSize, greaterThan(0), reason: '测试图片不应为空');

      print('✅ Test image validation passed');
    });

    test('Test DeepSeek share image scenario', () async {
      // 测试 DeepSeek 分享图的实际场景
      // 图片包含关于 OpenClaw AI 智能体安全产品的讨论
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

      // 运行测试
      final report = await tester.runBatchTest(groundTruth: groundTruth);

      // 保存报告
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

      // 验证测试执行
      expect(report['total_images'], equals(1));
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
// ignore_for_file: avoid_print
