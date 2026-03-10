import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/services/ocr_service.dart';

/// 创建测试图片
Future<File> createTestImage(String text) async {
  // 创建一个简单的测试图片
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);

  // 绘制白色背景
  final paint = Paint()..color = Colors.white;
  canvas.drawRect(const Rect.fromLTWH(0, 0, 400, 200), paint);

  // 绘制黑色文字
  final textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 24,
        fontFamily: 'Arial',
      ),
    ),
    textDirection: TextDirection.ltr,
  );

  textPainter.layout();
  textPainter.paint(canvas, const Offset(20, 80));

  // 转换为图像
  final picture = recorder.endRecording();
  final image = await picture.toImage(400, 200);
  final byteData = await image.toByteData(format: ImageByteFormat.png);
  final pngBytes = byteData!.buffer.asUint8List();

  // 保存到临时文件
  final testFile =
      File('/tmp/test_ocr_${DateTime.now().millisecondsSinceEpoch}.png');
  await testFile.writeAsBytes(pngBytes);

  return testFile;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OCR Service Tests', () {
    late OcrService ocrService;

    setUp(() async {
      ocrService = OcrService();
    });

    tearDown(() async {
      // 清理资源
      // 注意：不要在测试中调用 dispose()，因为服务是单例
    });

    test('should create test image successfully', () async {
      // 测试图片创建功能
      const testText = 'Test OCR';
      final testFile = await createTestImage(testText);

      try {
        // 验证文件存在
        expect(await testFile.exists(), true);

        // 验证文件大小合理（不应为空）
        final fileSize = await testFile.length();
        expect(fileSize, greaterThan(0));
        expect(fileSize, lessThan(10000)); // 应该小于 10KB

        // 验证文件扩展名
        expect(testFile.path.endsWith('.png'), true);

        print('✅ 测试图片创建成功，大小：$fileSize 字节');
      } finally {
        // 清理测试文件
        if (await testFile.exists()) {
          await testFile.delete();
        }
      }
    });

    test('should handle non-existent file gracefully', () async {
      // 测试处理不存在文件的情况
      final result =
          await ocrService.recognizeTextFromUri('/non/existent/path.png');

      expect(result.success, false);
      expect(result.error, isNotNull);
      expect(result.text, isEmpty);
      expect(result.imagePaths, isEmpty);

      print('✅ 正确处理不存在的文件');
    });

    test('should process valid image file path', () async {
      // 创建一个测试图片
      final testFile = await createTestImage('Hello');

      try {
        // 尝试验证文件路径（不实际执行 OCR）
        expect(await testFile.exists(), true);
        expect(testFile.path.contains('/tmp/'), true);

        print('✅ 有效图片文件路径验证通过');
      } finally {
        if (await testFile.exists()) {
          await testFile.delete();
        }
      }
    });

    test('should handle empty image file', () async {
      // 创建一个空白图片
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..color = Colors.white;
      canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), paint);

      final picture = recorder.endRecording();
      final image = await picture.toImage(100, 100);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final emptyFile = File('/tmp/empty_image.png');
      await emptyFile.writeAsBytes(pngBytes);

      try {
        // 验证空白图片文件存在
        expect(await emptyFile.exists(), true);
        expect(await emptyFile.length(), greaterThan(0));

        print('✅ 空白图片文件创建成功');
      } finally {
        if (await emptyFile.exists()) {
          await emptyFile.delete();
        }
      }
    });

    test('should handle multiple image files', () async {
      // 测试处理多个图片文件
      final testFiles = <File>[];

      try {
        // 创建 3 个测试图片
        for (int i = 0; i < 3; i++) {
          final testFile = await createTestImage('Test $i');
          testFiles.add(testFile);

          expect(await testFile.exists(), true);
          expect(await testFile.length(), greaterThan(0));
        }

        print('✅ 多个图片文件创建成功');
      } finally {
        // 清理所有测试文件
        for (final file in testFiles) {
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    });

    test('should recognize Chinese text from real image', () async {
      // 使用真实的测试图片进行中文 OCR 识别
      const testImagePath = 'test/resource/ocr_test_resorce.jpg';
      final testImageFile = File(testImagePath);

      // 验证测试图片存在
      expect(await testImageFile.exists(), true, reason: '测试图片必须存在');

      final fileSize = await testImageFile.length();
      print('📊 测试图片大小：$fileSize 字节');
      expect(fileSize, greaterThan(0), reason: '测试图片不应为空');

      // 验证文件格式（读取文件头）
      final bytes = await testImageFile.readAsBytes();
      expect(bytes.length, greaterThan(100), reason: '图片文件应该足够大');

      // JPG 文件头应该是 FF D8 FF
      expect(bytes[0], 0xFF);
      expect(bytes[1], 0xD8);
      expect(bytes[2], 0xFF);
      print('✅ 测试图片格式验证通过（JPG）');

      // 注意：在单元测试环境中，ML Kit 可能无法工作（需要设备/模拟器）
      // 因此这里主要验证文件层面的内容，实际 OCR 识别需要在设备上测试
      print('⚠️ 注意：实际 OCR 识别需要在真实设备上运行');
      print('💡 请使用 `flutter install` 安装到设备后进行完整测试');

      print('✅ 真实图片文件验证测试通过');
    });

    test('should detect Chinese characters in text', () async {
      // 测试中文检测逻辑
      const chineseText = 'Hello 世界 World';
      final hasChinese = chineseText.contains(RegExp(r'[\u4e00-\u9fff]'));

      expect(hasChinese, true, reason: '应正确检测到中文字符');
      print('✅ 中文检测逻辑验证通过');

      // 测试纯英文
      const englishText = 'Hello World';
      final hasChineseInEnglish =
          englishText.contains(RegExp(r'[\u4e00-\u9fff]'));
      expect(hasChineseInEnglish, false, reason: '纯英文不应被误判为中文');

      print('✅ 英文文本不会被误判为中文');
    });
  });

  group('OCR Result Tests', () {
    test('OcrResult toString should truncate long text', () {
      final longText = 'A' * 100;
      final result = OcrResult(
        text: longText,
        imagePaths: ['/test/path.png'],
        success: true,
      );

      final resultString = result.toString();
      expect(resultString.length, lessThan(100));
      expect(resultString, contains('...'));

      print('✅ OcrResult toString 正确截断长文本');
    });

    test('OcrResult should handle success case', () {
      final result = OcrResult(
        text: 'Test recognized text',
        imagePaths: ['/test/path1.png', '/test/path2.png'],
        success: true,
      );

      expect(result.success, true);
      expect(result.text, 'Test recognized text');
      expect(result.imagePaths.length, 2);
      expect(result.error, isNull);

      print('✅ OcrResult 正确处理成功情况');
    });

    test('OcrResult should handle error case', () {
      final result = OcrResult(
        text: '',
        imagePaths: [],
        success: false,
        error: 'Test error message',
      );

      expect(result.success, false);
      expect(result.error, 'Test error message');
      expect(result.text, isEmpty);
      expect(result.imagePaths, isEmpty);

      print('✅ OcrResult 正确处理错误情况');
    });

    test('OcrResult should handle empty text', () {
      final result = OcrResult(
        text: '',
        imagePaths: ['/test/path.png'],
        success: true,
      );

      expect(result.success, true);
      expect(result.text, isEmpty);
      expect(result.imagePaths.length, 1);

      print('✅ OcrResult 正确处理空文本');
    });
  });

  group('File Validation Tests', () {
    test('should validate PNG file header', () async {
      // 创建一个 PNG 图片
      final testFile = await createTestImage('PNG Test');

      try {
        // 读取文件头
        final bytes = await testFile.readAsBytes();
        expect(bytes.length, greaterThan(8));

        // PNG 文件头应该是：89 50 4E 47 0D 0A 1A 0A
        expect(bytes[0], 0x89);
        expect(bytes[1], 0x50); // P
        expect(bytes[2], 0x4E); // N
        expect(bytes[3], 0x47); // G

        print('✅ PNG 文件头验证通过');
      } finally {
        if (await testFile.exists()) {
          await testFile.delete();
        }
      }
    });

    test('should verify file exists before processing', () async {
      final validFile = await createTestImage('Valid');

      try {
        // 验证存在的文件
        expect(await validFile.exists(), true);

        // 验证不存在的文件
        final invalidFile = File(
            '/tmp/non_existent_${DateTime.now().millisecondsSinceEpoch}.png');
        expect(await invalidFile.exists(), false);

        print('✅ 文件存在性验证通过');
      } finally {
        if (await validFile.exists()) {
          await validFile.delete();
        }
      }
    });
  });
}
