import 'package:flutter/services.dart';

class FlutterClipboardManager {
  FlutterClipboardManager._();

  static Future<void> copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<ClipboardData?> getData() async {
    return await Clipboard.getData(Clipboard.kTextPlain);
  }
}
