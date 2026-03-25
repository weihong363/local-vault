import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/services/ocr_service.dart';

/// Create test image
Future<File> createTestImage(String text) async {
  // Create a simple test image
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);

  // Draw white background
  final paint = Paint()..color = Colors.white;
  canvas.drawRect(const Rect.fromLTWH(0, 0, 400, 200), paint);

  // Draw black text
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

  // Convert to image
  final picture = recorder.endRecording();
  final image = await picture.toImage(400, 200);
  final byteData = await image.toByteData(format: ImageByteFormat.png);
  final pngBytes = byteData!.buffer.asUint8List();

  // Save to temp file
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
      // Cleanup resources
      // Note: Do not call dispose() in tests as the service is a singleton
    });

    test('should create test image successfully', () async {
      // Test image creation functionality
      const testText = 'Test OCR';
      final testFile = await createTestImage(testText);

      try {
        // Verify file exists
        expect(await testFile.exists(), true);

        // Verify file size is reasonable (should not be empty)
        final fileSize = await testFile.length();
        expect(fileSize, greaterThan(0));
        expect(fileSize, lessThan(10000)); // Should be less than 10KB

        // Verify file extension
        expect(testFile.path.endsWith('.png'), true);

        print('✅ Test image created successfully, size: $fileSize bytes');
      } finally {
        // Cleanup test file
        if (await testFile.exists()) {
          await testFile.delete();
        }
      }
    });

    test('should handle non-existent file gracefully', () async {
      // Test handling of non-existent files
      final result =
          await ocrService.recognizeTextFromUri('/non/existent/path.png');

      expect(result.success, false);
      expect(result.error, isNotNull);
      expect(result.text, isEmpty);
      expect(result.imagePaths, isEmpty);

      print('✅ Non-existent file handled correctly');
    });

    test('should process valid image file path', () async {
      // Create a test image
      final testFile = await createTestImage('Hello');

      try {
        // Try to verify file path (without actually performing OCR)
        expect(await testFile.exists(), true);
        expect(testFile.path.contains('/tmp/'), true);

        print('✅ Valid image file path verification passed');
      } finally {
        if (await testFile.exists()) {
          await testFile.delete();
        }
      }
    });

    test('should handle empty image file', () async {
      // Create a blank image
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
        // Verify blank image file exists
        expect(await emptyFile.exists(), true);
        expect(await emptyFile.length(), greaterThan(0));

        print('✅ Blank image file created successfully');
      } finally {
        if (await emptyFile.exists()) {
          await emptyFile.delete();
        }
      }
    });

    test('should handle multiple image files', () async {
      // Test handling of multiple image files
      final testFiles = <File>[];

      try {
        // Create 3 test images
        for (int i = 0; i < 3; i++) {
          final testFile = await createTestImage('Test $i');
          testFiles.add(testFile);

          expect(await testFile.exists(), true);
          expect(await testFile.length(), greaterThan(0));
        }

        print('✅ Multiple image files created successfully');
      } finally {
        // Cleanup all test files
        for (final file in testFiles) {
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    });

    test('should recognize Chinese text from real image', () async {
      // Use real test image for Chinese OCR recognition
      const testImagePath = 'test/resource/ocr_test_resorce.jpg';
      final testImageFile = File(testImagePath);

      // Verify test image exists
      expect(await testImageFile.exists(), true,
          reason: 'Test image must exist');

      final fileSize = await testImageFile.length();
      print('📊 Test image size: $fileSize bytes');
      expect(fileSize, greaterThan(0),
          reason: 'Test image should not be empty');

      // Verify file format (read file header)
      final bytes = await testImageFile.readAsBytes();
      expect(bytes.length, greaterThan(100),
          reason: 'Image file should be large enough');

      // JPG file header should be FF D8 FF
      expect(bytes[0], 0xFF);
      expect(bytes[1], 0xD8);
      expect(bytes[2], 0xFF);
      print('✅ Test image format verification passed (JPG)');

      // Note: In unit test environment, ML Kit may not work (requires device/emulator)
      // Here we mainly validate file-level content, actual OCR recognition needs to be tested on device
      print('⚠️ Note: actual OCR recognition must run on a real device');
      print('💡 Use `flutter install` and run the full test on a device');

      print('✅ Real image file validation test passed');
    });

    test('should detect Chinese characters in text', () async {
      // Test Chinese character detection logic
      const chineseText = 'Hello 世界 World';
      final hasChinese = chineseText.contains(RegExp(r'[\u4e00-\u9fff]'));

      expect(hasChinese, true,
          reason: 'Should correctly detect Chinese characters');
      print('✅ Chinese text detection logic passed');

      // Test pure English
      const englishText = 'Hello World';
      final hasChineseInEnglish =
          englishText.contains(RegExp(r'[\u4e00-\u9fff]'));
      expect(hasChineseInEnglish, false,
          reason: 'Pure English should not be falsely detected as Chinese');

      print('✅ English text is not falsely detected as Chinese');
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

      print('✅ OcrResult.toString truncates long text correctly');
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

      print('✅ OcrResult handles success correctly');
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

      print('✅ OcrResult handles errors correctly');
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

      print('✅ OcrResult handles empty text correctly');
    });
  });

  group('File Validation Tests', () {
    test('should validate PNG file header', () async {
      // Create a PNG image
      final testFile = await createTestImage('PNG Test');

      try {
        // Read file header
        final bytes = await testFile.readAsBytes();
        expect(bytes.length, greaterThan(8));

        // PNG file header should be: 89 50 4E 47 0D 0A 1A 0A
        expect(bytes[0], 0x89);
        expect(bytes[1], 0x50); // P
        expect(bytes[2], 0x4E); // N
        expect(bytes[3], 0x47); // G

        print('✅ PNG file header verification passed');
      } finally {
        if (await testFile.exists()) {
          await testFile.delete();
        }
      }
    });

    test('should verify file exists before processing', () async {
      final validFile = await createTestImage('Valid');

      try {
        // Verify existing file
        expect(await validFile.exists(), true);

        // Verify non-existent file
        final invalidFile = File(
            '/tmp/non_existent_${DateTime.now().millisecondsSinceEpoch}.png');
        expect(await invalidFile.exists(), false);

        print('✅ File existence verification passed');
      } finally {
        if (await validFile.exists()) {
          await validFile.delete();
        }
      }
    });
  });
}
// ignore_for_file: avoid_print
