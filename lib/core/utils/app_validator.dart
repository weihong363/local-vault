
class AppValidator {
  AppValidator._();

  static bool isValidTitle(String title) {
    return title.isNotEmpty && title.length <= 100;
  }

  static bool isValidContent(String content) {
    return content.isNotEmpty && content.length <= 10000;
  }

  static bool isValidTag(String tag) {
    return tag.isNotEmpty && tag.length <= 20;
  }
}
