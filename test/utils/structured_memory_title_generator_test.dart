import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/utils/memory_title_generator.dart';

void main() {
  group('StructuredMemoryTitleGenerator', () {
    test(
        'should generate title with app name and content snippet for regular text',
        () {
      final generator = StructuredMemoryTitleGenerator();

      final result = generator.generateTitle(
        originalContent: '这是一条来自微信的聊天记录，内容是关于周末聚餐的安排',
        contentType: 'text',
        sourceApp: 'com.tencent.mm',
        timestamp: DateTime.now(),
      );

      expect(result, contains('微信'));
      expect(result, contains('聚餐'));
      expect(result, contains('#')); // Has topic tag
    });

    test('should generate title with media type and content for images', () {
      final generator = StructuredMemoryTitleGenerator();

      final result = generator.generateTitle(
        originalContent: '',
        contentType: 'image',
        sourceApp: 'com.instagram.android',
        timestamp: DateTime.now(),
      );

      expect(result, contains('Instagram'));
      expect(result, contains('图片'));
      expect(result, contains('#视觉')); // Media tag
    });

    test('should generate title with video type and content for videos', () {
      final generator = StructuredMemoryTitleGenerator();

      final result = generator.generateTitle(
        originalContent: '视频内容：产品发布会现场',
        contentType: 'video',
        sourceApp: 'com.youtube.android',
        timestamp: DateTime.now(),
      );

      expect(result, contains('YouTube'));
      expect(result, contains('发布会'));
      expect(result, contains('#视频')); // Video tag
    });

    test('should generate title with audio type and content for voice messages',
        () {
      final generator = StructuredMemoryTitleGenerator();

      final result = generator.generateTitle(
        originalContent: '语音消息：明天会议时间改为下午3点',
        contentType: 'audio',
        sourceApp: 'com.whatsapp',
        timestamp: DateTime.now(),
      );

      expect(result, contains('WhatsApp'));
      expect(result, contains('会议'));
      expect(result, contains('#语音')); // Audio tag
    });

    test('should generate title with document type and content for files', () {
      final generator = StructuredMemoryTitleGenerator();

      final result = generator.generateTitle(
        originalContent: '文档标题：季度财务报告',
        contentType: 'document',
        sourceApp: 'com.microsoft.office',
        timestamp: DateTime.now(),
      );

      expect(result, contains('Office'));
      expect(result, contains('财务报告'));
      expect(result, contains('#文档')); // Document tag
    });

    test('should generate concise title within length limit', () {
      final generator = StructuredMemoryTitleGenerator();

      final longContent = 'x' * 500 + '重要信息';
      final result = generator.generateTitle(
        originalContent: longContent,
        contentType: 'text',
        sourceApp: 'com.tencent.mm',
        timestamp: DateTime.now(),
      );

      expect(result.length, lessThanOrEqualTo(100));
      expect(result, contains('重要信息'));
      expect(result, contains('微信'));
    });
  });
}
