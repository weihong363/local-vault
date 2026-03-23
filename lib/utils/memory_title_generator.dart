class StructuredMemoryTitleGenerator {
  static const Map<String, String> _appDisplayNameMap = {
    'com.tencent.mm': '微信',
    'com.instagram.android': 'Instagram',
    'com.youtube.android': 'YouTube',
    'com.whatsapp': 'WhatsApp',
    'com.microsoft.office': 'Office',
  };

  static const Map<String, String> _contentTypeDisplayMap = {
    'image': '图片',
    'video': '视频',
    'audio': '语音',
    'document': '文档',
  };

  static const Map<String, String> _contentTypeTagMap = {
    'image': '#视觉',
    'video': '#视频',
    'audio': '#语音',
    'document': '#文档',
  };

  static const int _maxTitleLength = 100;

  String generateTitle({
    required String originalContent,
    required String contentType,
    required String sourceApp,
    required DateTime timestamp,
  }) {
    final appName = _getAppDisplayName(sourceApp);
    final contentTag = _contentTypeTagMap[contentType] ?? '#话题';
    final contentTypeDisplay =
        _contentTypeDisplayMap[contentType] ?? contentType;
    final contentSnippet =
        _extractContentSnippet(originalContent, appName, contentTag);
    return _buildTitle(appName, contentSnippet, contentTypeDisplay, contentTag);
  }

  String _getAppDisplayName(String sourceApp) {
    return _appDisplayNameMap[sourceApp] ??
        sourceApp.split('.').lastWhere(
              (part) => part.isNotEmpty,
              orElse: () => sourceApp,
            );
  }

  String _extractContentSnippet(
    String originalContent,
    String appName,
    String contentTag,
  ) {
    if (originalContent.isEmpty) {
      return '';
    }

    var cleanedContent = originalContent.replaceAll(RegExp(r'^[^：]*：'), '');

    final matches = RegExp(r'[\u4e00-\u9fa5]{2,}|[a-zA-Z]{4,}')
        .allMatches(cleanedContent)
        .toList();

    if (matches.isEmpty) {
      return '';
    }

    final match = matches.last;
    int startIndex = match.start;
    int endIndex = startIndex + 20;

    if (endIndex > cleanedContent.length) {
      endIndex = cleanedContent.length;
    }

    while (endIndex < cleanedContent.length) {
      final char = cleanedContent.codeUnitAt(endIndex);
      if (char >= 0x4e00 && char <= 0x9fff) {
        endIndex++;
      } else {
        break;
      }
    }

    var contentSnippet = cleanedContent.substring(startIndex, endIndex);

    final baseLength = appName.length + contentTag.length + 2;
    final maxContentLength = _maxTitleLength - baseLength;

    if (maxContentLength <= 0) {
      return '';
    }

    if (contentSnippet.length > maxContentLength) {
      contentSnippet = contentSnippet.substring(0, maxContentLength);
    }

    return contentSnippet;
  }

  String _buildTitle(
    String appName,
    String contentSnippet,
    String contentTypeDisplay,
    String contentTag,
  ) {
    if (contentSnippet.isEmpty) {
      return _limitLength('$appName $contentTypeDisplay$contentTag');
    } else {
      return _limitLength('$appName $contentSnippet$contentTag');
    }
  }

  String _limitLength(String title) {
    if (title.length <= _maxTitleLength) {
      return title;
    }
    return title.substring(0, _maxTitleLength);
  }
}
