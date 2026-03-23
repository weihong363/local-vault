/// 记忆内容类型分类
///
/// 用于决定晋升/降级的差异化策略
enum MemoryContentType {
  /// 临时任务（难升易降）
  temporaryTask,

  /// 用户偏好（易升难降）
  userPreference,

  /// 项目上下文（易升，仅主线进 core）
  projectContext,

  /// 长期目标
  longTermGoal,

  /// 核心项目
  coreProject,

  /// 关键约束（中等，升 core 要确认）
  keyConstraint,

  /// 身份级约束（较容易但要确认）
  identityLevel,

  /// 一次性细节（不建议，不会）
  oneTimeDetail;

  /// 从文本内容自动推断类型
  static MemoryContentType inferFromText(String title, String content) {
    final text = '$title $content'.toLowerCase();

    // 临时任务关键词
    if (_containsAny(text, ['记得', '别忘了', '提醒', 'todo', '待办'])) {
      return temporaryTask;
    }

    // 身份级关键词
    if (_containsAny(text, ['我是', '我喜欢', '我总是', '我不'])) {
      return identityLevel;
    }

    // 项目关键词
    if (_containsAny(text, ['项目', 'project', '开发', 'product', 'app'])) {
      return projectContext;
    }

    // 偏好关键词
    if (_containsAny(text, ['喜欢', '偏好', '习惯', 'prefer', 'like'])) {
      return userPreference;
    }

    // 默认返回项目上下文
    return projectContext;
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
}
