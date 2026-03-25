import 'package:flutter_test/flutter_test.dart';
import 'package:local_vault/core/utils/topic_placeholder_utils.dart';

void main() {
  group('TopicPlaceholderUtils', () {
    test('detects placeholder topics across supported locales', () {
      expect(
          TopicPlaceholderUtils.isPlaceholderTopic('Pending summary'), isTrue);
      expect(
        TopicPlaceholderUtils.isPlaceholderTopic('Résumé en attente'),
        isTrue,
      );
      expect(
        TopicPlaceholderUtils.isPlaceholderTopic('Ausstehende Zusammenfassung'),
        isTrue,
      );
      expect(TopicPlaceholderUtils.isPlaceholderTopic('通用主题'), isTrue);
      expect(TopicPlaceholderUtils.isPlaceholderTopic('正式发布计划'), isFalse);
    });

    test('Strips leading placeholder prefixes from multilingual topics', () {
      expect(
        TopicPlaceholderUtils.stripLeadingPlaceholder(
          'Resumen pendiente: lanzamiento del proyecto',
        ),
        'lanzamiento del proyecto',
      );
      expect(
        TopicPlaceholderUtils.stripLeadingPlaceholder('一般トピック - ログイン改版'),
        'ログイン改版',
      );
      expect(
        TopicPlaceholderUtils.stripLeadingPlaceholder('通用主题：发布节奏调整'),
        '发布节奏调整',
      );
    });
  });
}
