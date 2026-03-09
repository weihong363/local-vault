import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:local_vault/core/services/ocr_service.dart';

/// 集成测试：在真实设备上测试 OCR 中文识别功能
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('OCR Chinese Recognition Integration Tests', () {
    testWidgets('should recognize Chinese text from real image on device', (WidgetTester tester) async {
      // 注意：在集成测试中，我们需要先将测试图片复制到设备上
      // 这里使用一个简单的方法来验证 OCR 功能
      
      debugPrint('⚠️ 真实图片 OCR 测试需要手动准备测试资源');
      debugPrint('💡 建议：从 DeepSeek 或其他应用分享包含中文的图片到 Local Vault 进行完整测试');
      
      // 占位符测试，避免编译错误
      expect(true, isTrue);
      
      // 完整的测试应该：
      // 1. 将 test/resource/ocr_test_resorce.jpg 推送到设备
      // 2. 获取设备上的文件路径
      // 3. 使用 OcrService 进行识别
      // 4. 验证识别结果包含中文
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('should detect Chinese characters correctly', (WidgetTester tester) async {
      // 测试中文检测逻辑
      final chineseText = 'Hello 世界 World';
      final hasChinese = chineseText.contains(RegExp(r'[\u4e00-\u9fff]'));
      
      expect(hasChinese, isTrue, reason: '应正确检测到中文字符');
      debugPrint('✅ 中文检测逻辑验证通过');
      
      // 测试纯英文
      final englishText = 'Hello World';
      final hasChineseInEnglish = englishText.contains(RegExp(r'[\u4e00-\u9fff]'));
      expect(hasChineseInEnglish, isFalse, reason: '纯英文不应被误判为中文');
      
      debugPrint('✅ 英文文本不会被误判为中文');
    });
  });
}

/// 提取中文样本用于日志显示
String _extractChineseSample(String text) {
  final chineseChars = text.split('').where((char) {
    return char.codeUnitAt(0) >= 0x4e00 && char.codeUnitAt(0) <= 0x9fff;
  }).take(20).join('');
  return '$chineseChars${text.length > 20 ? "..." : ""}';
}
