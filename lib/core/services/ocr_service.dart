import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// OCR 识别结果
class OcrResult {
  final String text;
  final List<String> imagePaths;
  final bool success;
  final String? error;

  OcrResult({
    required this.text,
    required this.imagePaths,
    this.success = true,
    this.error,
  });

  @override
  String toString() =>
      'OcrResult(text: ${text.length > 50 ? '${text.substring(0, 50)}...' : text}, success: $success)';
}

/// OCR 服务 - 单例模式
class OcrService {
  static const String imageFileReadError = 'Unable to read image file';

  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  // 使用中文和拉丁混合脚本的 TextRecognizer（最适合中英文混合）
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.chinese);
  static const MethodChannel _channel = MethodChannel('local_vault/share');

  /// 从 URI 识别图片中的文字
  Future<OcrResult> recognizeTextFromUri(String uriString) async {
    try {
      debugPrint('🔍 [OcrService] Starting image recognition: $uriString');

      // 获取文件（对于 content:// URI，会通过原生端复制到缓存）
      final file = await _getFileFromUri(uriString);
      if (file == null) {
        debugPrint('❌ [OcrService] Unable to get image file');
        return OcrResult(
          text: '',
          imagePaths: [],
          success: false,
          error: imageFileReadError,
        );
      }

      debugPrint(
          '📁 [OcrService] Image file path: ${file.path}, size: ${file.lengthSync()} bytes');

      // 使用 ML Kit 识别文字（直接使用中文识别器，也能很好地识别英文）
      final inputImage = InputImage.fromFile(file);

      debugPrint(
          '🔤 [OcrService] Using the Chinese recognizer (supports mixed Chinese and English)');
      final recognizedText = await _textRecognizer.processImage(inputImage);

      debugPrint(
          '✅ [OcrService] Recognition succeeded with ${recognizedText.blocks.length} text block(s)');

      // 提取所有识别出的文字
      final extractedText =
          recognizedText.blocks.map((block) => block.text).join('\n');

      debugPrint(
          '📝 [OcrService] Extracted text preview: ${extractedText.length > 100 ? '${extractedText.substring(0, 100)}...' : extractedText}');

      return OcrResult(
        text: extractedText,
        imagePaths: [file.path],
        success: true,
      );
    } catch (e) {
      debugPrint('❌ [OcrService] OCR recognition failed: $e');
      return OcrResult(
        text: '',
        imagePaths: [],
        success: false,
        error: e.toString(),
      );
    }
  }

  /// 从多个 URI 识别图片中的文字
  Future<OcrResult> recognizeTextFromUris(List<String> uriStrings) async {
    try {
      debugPrint(
          '🔍 [OcrService] Starting batch recognition for ${uriStrings.length} image(s)');

      final combinedSections = <String>[];
      final allPaths = <String>[];

      for (int i = 0; i < uriStrings.length; i++) {
        debugPrint(
            '📸 [OcrService] Processing image ${i + 1}/${uriStrings.length}');

        final result = await recognizeTextFromUri(uriStrings[i]);
        if (result.success) {
          final imageNumber = combinedSections.length + 1;
          final sectionText = uriStrings.length > 1
              ? '--- Image $imageNumber ---\n\n${result.text}'
              : result.text;
          combinedSections.add(sectionText);
          allPaths.addAll(result.imagePaths);
        }
      }

      final combinedText = combinedSections.join('\n\n');

      debugPrint(
          '✅ [OcrService] Batch recognition finished for ${combinedSections.length} image(s)');

      return OcrResult(
        text: combinedText,
        imagePaths: allPaths,
        success: true,
      );
    } catch (e) {
      debugPrint('❌ [OcrService] Batch OCR recognition failed: $e');
      return OcrResult(
        text: '',
        imagePaths: [],
        success: false,
        error: e.toString(),
      );
    }
  }

  /// 从 URI 获取文件
  Future<File?> _getFileFromUri(String uriString) async {
    try {
      // 处理 content:// 或 file:// URI
      if (uriString.startsWith('content://')) {
        // 对于 content:// URI，需要通过原生端读取到缓存文件
        if (Platform.isAndroid) {
          debugPrint(
              '📲 [OcrService] Preparing to read content URI via native code: $uriString');
          final cachePath =
              await _readContentUriViaMethodChannel(Uri.parse(uriString));
          if (cachePath != null && cachePath.isNotEmpty) {
            debugPrint(
                '✅ [OcrService] Native layer returned cache path: $cachePath');
            final cacheFile = File(cachePath);
            if (await cacheFile.exists()) {
              final fileSize = await cacheFile.length();
              debugPrint(
                  '📁 [OcrService] Cache file exists, size: $fileSize bytes');
              return cacheFile;
            } else {
              debugPrint('❌ [OcrService] Cache file does not exist!');
            }
          } else {
            debugPrint(
                '❌ [OcrService] Native layer returned null or an empty path');
          }
        }

        // 备用方案：尝试直接复制（已废弃）
        debugPrint('⚠️ [OcrService] The fallback path has been deprecated');
      } else if (uriString.startsWith('file://')) {
        return File(uriString.replaceFirst('file://', ''));
      }

      // 尝试直接作为文件路径
      return File(uriString);
    } catch (e) {
      debugPrint('❌ [OcrService] Failed to get file: $e');
      return null;
    }
  }

  /// 通过 MethodChannel 读取 content URI（Android）
  Future<String?> _readContentUriViaMethodChannel(Uri uri) async {
    try {
      debugPrint(
          '📲 [OcrService] Calling native code to read content URI: $uri');

      final cachePath =
          await _channel.invokeMethod<String>('readContentUriToCache', {
        'uri': uri.toString(),
      });

      if (cachePath != null && cachePath.isNotEmpty) {
        debugPrint(
            '✅ [OcrService] Native read succeeded, cache path: $cachePath');
        return cachePath;
      } else {
        debugPrint('⚠️ [OcrService] Native layer returned null');
        return null;
      }
    } on PlatformException catch (e) {
      debugPrint('❌ [OcrService] MethodChannel read failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ [OcrService] MethodChannel read failed: $e');
      return null;
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    await _textRecognizer.close();
    debugPrint('♻️ [OcrService] OCR resources released');
  }
}
