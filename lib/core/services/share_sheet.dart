import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShareSheet {
  ShareSheet._();

  static Future<void> share(
    BuildContext context,
    String text, {
    String? subject,
  }) async {
    final ShareSheetPlatform platform = ShareSheetPlatform.instance;

    await platform.share(
      text,
      subject: subject,
    );
  }
}

abstract class ShareSheetPlatform {
  static ShareSheetPlatform instance = ShareSheetPlatformAndroid();

  Future<void> share(String text, {String? subject});
}

class ShareSheetPlatformAndroid extends ShareSheetPlatform {
  @override
  Future<void> share(String text, {String? subject}) async {
    const channel = MethodChannel('local_vault/share');

    try {
      await channel.invokeMethod('share', {
        'text': text,
        'subject': subject,
      });
    } on PlatformException catch (e) {
      debugPrint('Share failed: ${e.message}');
    }
  }
}
