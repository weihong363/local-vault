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
  String toString() => 'OcrResult(text: ${text.length > 50 ? '${text.substring(0, 50)}...' : text}, success: $success)';
}

/// OCR 服务 - 单例模式
class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  // 使用中文和拉丁混合脚本的 TextRecognizer（最适合中英文混合）
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);
  static const MethodChannel _channel = MethodChannel('local_vault/share');

  /// 从 URI 识别图片中的文字
  Future<OcrResult> recognizeTextFromUri(String uriString) async {
    try {
      debugPrint('🔍 [OcrService] 开始识别图片：$uriString');
      
      // 获取文件（对于 content:// URI，会通过原生端复制到缓存）
      final file = await _getFileFromUri(uriString);
      if (file == null) {
        debugPrint('❌ [OcrService] 无法获取图片文件');
        return OcrResult(
          text: '',
          imagePaths: [],
          success: false,
          error: '无法获取图片文件',
        );
      }

      debugPrint('📁 [OcrService] 图片文件路径：${file.path}, 大小：${file.lengthSync()} 字节');

      // 使用 ML Kit 识别文字（直接使用中文识别器，也能很好地识别英文）
      final inputImage = InputImage.fromFile(file);
      
      debugPrint('🔤 [OcrService] 使用中文识别器（支持中英文混合）');
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      debugPrint('✅ [OcrService] 识别成功，找到 ${recognizedText.blocks.length} 个文本块');
      
      // 提取所有识别出的文字
      final extractedText = recognizedText.blocks
          .map((block) => block.text)
          .join('\n');
      
      debugPrint('📝 [OcrService] 识别到的文本内容：${extractedText.length > 100 ? extractedText.substring(0, 100) + '...' : extractedText}');
      
      return OcrResult(
        text: extractedText,
        imagePaths: [file.path],
        success: true,
      );
    } catch (e) {
      debugPrint('❌ [OcrService] OCR 识别失败：$e');
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
      debugPrint('🔍 [OcrService] 开始批量识别 ${uriStrings.length} 张图片');
      
      final allTexts = <String>[];
      final allPaths = <String>[];
      
      for (int i = 0; i < uriStrings.length; i++) {
        debugPrint('📸 [OcrService] 正在处理第 ${i + 1}/${uriStrings.length} 张图片');
        
        final result = await recognizeTextFromUri(uriStrings[i]);
        if (result.success) {
          allTexts.add(result.text);
          allPaths.addAll(result.imagePaths);
        }
      }
      
      final combinedText = allTexts.join('\n\n--- 图片 ${allTexts.length} ---\n\n');
      
      debugPrint('✅ [OcrService] 批量识别完成，共 ${allTexts.length} 张图片');
      
      return OcrResult(
        text: combinedText,
        imagePaths: allPaths,
        success: true,
      );
    } catch (e) {
      debugPrint('❌ [OcrService] 批量 OCR 识别失败：$e');
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
          debugPrint('📲 [OcrService] 准备通过原生端读取 content URI: $uriString');
          final cachePath = await _readContentUriViaMethodChannel(Uri.parse(uriString));
          if (cachePath != null && cachePath.isNotEmpty) {
            debugPrint('✅ [OcrService] 原生端返回缓存路径：$cachePath');
            final cacheFile = File(cachePath);
            if (await cacheFile.exists()) {
              final fileSize = await cacheFile.length();
              debugPrint('📁 [OcrService] 缓存文件存在，大小：$fileSize 字节');
              return cacheFile;
            } else {
              debugPrint('❌ [OcrService] 缓存文件不存在！');
            }
          } else {
            debugPrint('❌ [OcrService] 原生端返回 null 或空路径');
          }
        }
        
        // 备用方案：尝试直接复制（已废弃）
        debugPrint('⚠️ [OcrService] 备用方案已废弃');
      } else if (uriString.startsWith('file://')) {
        return File(uriString.replaceFirst('file://', ''));
      }
      
      // 尝试直接作为文件路径
      return File(uriString);
    } catch (e) {
      debugPrint('❌ [OcrService] 获取文件失败：$e');
      return null;
    }
  }

  /// 读取 content:// URI 的内容
  /// 注意：此方法已废弃，主要使用 _readContentUriViaMethodChannel 通过原生端读取
  Future<Uint8List?> _readContentUri(Uri uri) async {
    try {
      debugPrint('⚠️ [OcrService] _readContentUri 已废弃，请使用原生端读取方式');
      return null;
    } catch (e) {
      debugPrint('❌ [OcrService] 读取 URI 失败：$e');
      return null;
    }
  }
  
  /// 通过 MethodChannel 读取 content URI（Android）
  Future<String?> _readContentUriViaMethodChannel(Uri uri) async {
    try {
      debugPrint('📲 [OcrService] 调用原生端读取 content URI: $uri');
      
      final cachePath = await _channel.invokeMethod<String>('readContentUriToCache', {
        'uri': uri.toString(),
      });
      
      if (cachePath != null && cachePath.isNotEmpty) {
        debugPrint('✅ [OcrService] 原生端读取成功，缓存路径：$cachePath');
        return cachePath;
      } else {
        debugPrint('⚠️ [OcrService] 原生端返回 null');
        return null;
      }
    } on PlatformException catch (e) {
      debugPrint('❌ [OcrService] 通过 MethodChannel 读取失败：${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ [OcrService] 通过 MethodChannel 读取失败：$e');
      return null;
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    await _textRecognizer.close();
    debugPrint('♻️ [OcrService] 已释放 OCR 资源');
  }
}
