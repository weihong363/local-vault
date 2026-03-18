import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:local_vault/core/services/ocr_service.dart';

class OcrAccuracyResult {
  final String imageName;
  final String expectedText;
  final String actualText;
  final double accuracy;
  final bool containsChinese;
  final String? error;

  OcrAccuracyResult({
    required this.imageName,
    required this.expectedText,
    required this.actualText,
    required this.accuracy,
    this.containsChinese = false,
    this.error,
  });
}

class OcrAccuracyTester {
  final OcrService ocrService = OcrService();

  double calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final s1Normalized = s1.trim().toLowerCase();
    final s2Normalized = s2.trim().toLowerCase();

    if (s1Normalized == s2Normalized) return 1.0;

    final len1 = s1Normalized.length;
    final len2 = s2Normalized.length;

    List<List<int>> dp = List.generate(
      len1 + 1,
      (i) => List.filled(len2 + 1, 0),
    );

    for (int i = 0; i <= len1; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      dp[0][j] = j;
    }

    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1Normalized[i - 1] == s2Normalized[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    final editDistance = dp[len1][len2];
    final maxLen = len1 > len2 ? len1 : len2;
    return 1.0 - (editDistance / maxLen);
  }

  Future<OcrAccuracyResult> testImage({
    required String imagePath,
    required String expectedText,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('File not found: $imagePath');
        return OcrAccuracyResult(
          imageName: imagePath,
          expectedText: expectedText,
          actualText: '',
          accuracy: 0.0,
          error: 'File not found',
        );
      }

      debugPrint('Testing: $imagePath');
      final result = await ocrService.recognizeTextFromUri(file.path);

      if (!result.success) {
        debugPrint('OCR failed: ${result.error}');
        return OcrAccuracyResult(
          imageName: imagePath,
          expectedText: expectedText,
          actualText: '',
          accuracy: 0.0,
          error: result.error,
        );
      }

      final accuracy = calculateSimilarity(result.text, expectedText);
      final hasChinese = result.text.contains(RegExp(r'[\u4e00-\u9fff]'));

      debugPrint('Accuracy: ${(accuracy * 100).toStringAsFixed(1)}%');

      return OcrAccuracyResult(
        imageName: imagePath,
        expectedText: expectedText,
        actualText: result.text,
        accuracy: accuracy,
        containsChinese: hasChinese,
      );
    } catch (e) {
      debugPrint('Test exception: $e');
      return OcrAccuracyResult(
        imageName: imagePath,
        expectedText: expectedText,
        actualText: '',
        accuracy: 0.0,
        error: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> runBatchTest({
    required Map<String, String> groundTruth,
  }) async {
    final results = <OcrAccuracyResult>[];
    var totalAccuracy = 0.0;
    var successCount = 0;
    var chineseCount = 0;
    var englishCount = 0;
    var chineseAccuracy = 0.0;
    var englishAccuracy = 0.0;

    print('');
    print('Starting batch test with ${groundTruth.length} images');
    print('=' * 60);

    for (int i = 0; i < groundTruth.length; i++) {
      final entry = groundTruth.entries.elementAt(i);
      print('\nTest ${i + 1}/${groundTruth.length}: ${entry.key}');

      final result = await testImage(
        imagePath: entry.key,
        expectedText: entry.value,
      );

      results.add(result);
      totalAccuracy += result.accuracy;

      if (result.accuracy >= 0.8) {
        successCount++;
      }

      if (result.containsChinese) {
        chineseCount++;
        chineseAccuracy += result.accuracy;
      } else {
        englishCount++;
        englishAccuracy += result.accuracy;
      }

      final emoji = result.accuracy >= 0.8
          ? 'PASS'
          : (result.accuracy >= 0.5 ? 'WARN' : 'FAIL');
      print(
          '[$emoji] Accuracy: ${(result.accuracy * 100).toStringAsFixed(1)}%');

      if (result.error != null) {
        print('Error: ${result.error}');
      } else {
        print('Expected: "${result.expectedText}"');
        print('Actual:   "${result.actualText}"');
      }
    }

    final avgAccuracy =
        results.isNotEmpty ? totalAccuracy / results.length : 0.0;
    final successRate =
        results.isNotEmpty ? successCount / results.length : 0.0;
    final finalChineseAccuracy =
        chineseCount > 0 ? chineseAccuracy / chineseCount : 0.0;
    final finalEnglishAccuracy =
        englishCount > 0 ? englishAccuracy / englishCount : 0.0;

    final report = {
      'total_images': groundTruth.length,
      'success_count': successCount,
      'average_accuracy': avgAccuracy,
      'success_rate': successRate,
      'chinese_count': chineseCount,
      'english_count': englishCount,
      'chinese_accuracy': finalChineseAccuracy,
      'english_accuracy': finalEnglishAccuracy,
      'results': results
          .map((r) => {
                'image': r.imageName,
                'expected': r.expectedText,
                'actual': r.actualText,
                'accuracy': r.accuracy,
                'contains_chinese': r.containsChinese,
                'error': r.error,
              })
          .toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    print('\n${'=' * 60}');
    _printReport(report);

    return report;
  }

  void _printReport(Map<String, dynamic> report) {
    print('OCR Accuracy Test Report');
    print('-' * 60);
    print('Total images: ${report['total_images']}');
    print('Success count: ${report['success_count']} (accuracy >= 80%)');
    final avgAcc = (report['average_accuracy'] as double) * 100;
    final succRate = (report['success_rate'] as double) * 100;
    print('Average accuracy: ${avgAcc.toStringAsFixed(2)}%');
    print('Success rate: ${succRate.toStringAsFixed(2)}%');
    print('');
    print('Category breakdown:');
    final chiAcc = (report['chinese_accuracy'] as double) * 100;
    final engAcc = (report['english_accuracy'] as double) * 100;
    print(
        '  Chinese: ${report['chinese_count']} tests, ${chiAcc.toStringAsFixed(2)}% accuracy');
    print(
        '  English: ${report['english_count']} tests, ${engAcc.toStringAsFixed(2)}% accuracy');
    print('-' * 60);

    final sortedResults = List<Map>.from(report['results'])
      ..sort((a, b) =>
          (a['accuracy'] as double).compareTo(b['accuracy'] as double));

    if (sortedResults.isNotEmpty && sortedResults.first['accuracy'] < 0.8) {
      print('\nTests needing improvement (accuracy < 80%):');
      int count = 0;
      for (final r in sortedResults) {
        if ((r['accuracy'] as double) < 0.8 && count < 5) {
          final accPct = (r['accuracy'] as double) * 100;
          print('${count + 1}. ${r['image']} - ${accPct.toStringAsFixed(1)}%');
          print('   Expected: ${r['expected']}');
          print('   Actual:   ${r['actual']}');
          count++;
        }
      }
    }

    final failedTests =
        sortedResults.where((r) => (r['accuracy'] as double) < 0.5).toList();
    if (failedTests.isNotEmpty) {
      print('\nFailed tests (accuracy < 50%):');
      for (int i = 0; i < failedTests.length; i++) {
        final r = failedTests[i];
        final accPct = (r['accuracy'] as double) * 100;
        print('${i + 1}. ${r['image']} - ${accPct.toStringAsFixed(1)}%');
        if (r['error'] != null) {
          print('   Error: ${r['error']}');
        }
      }
    }
  }
}
// ignore_for_file: avoid_print
