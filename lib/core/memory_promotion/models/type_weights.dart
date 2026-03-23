import 'memory_content_type.dart';

/// 类型权重配置
class TypeWeights {
  const TypeWeights(
    this.promotionSpeed,
    this.demotionThreshold,
  );

  /// 晋升速度系数 (0.5-2.0)
  /// > 1.0 加速，< 1.0 减速
  final double promotionSpeed;

  /// 降级阈值系数 (0.8-1.5)
  /// > 1.0 更难降级，< 1.0 更容易降级
  final double demotionThreshold;

  /// 临时任务：难升易降
  static const temporaryTask = TypeWeights(0.3, 0.5);

  /// 用户偏好：易升难降
  static const userPreference = TypeWeights(1.2, 1.3);

  /// 项目上下文：易升，仅主线进 core
  static const projectContext = TypeWeights(1.5, 1.0);

  /// 长期目标：中等偏快
  static const longTermGoal = TypeWeights(1.3, 1.2);

  /// 核心项目：易升，谨慎降
  static const coreProject = TypeWeights(1.5, 1.1);

  /// 关键约束：中等，升 core 要确认
  static const keyConstraint = TypeWeights(1.2, 1.3);

  /// 身份级：中等，极难降
  static const identityLevel = TypeWeights(1.0, 1.5);

  /// 一次性细节：不升自降
  static const oneTimeDetail = TypeWeights(0.1, 0.2);

  /// 根据内容类型获取权重
  static TypeWeights forType(MemoryContentType type) {
    switch (type) {
      case MemoryContentType.temporaryTask:
        return temporaryTask;
      case MemoryContentType.userPreference:
        return userPreference;
      case MemoryContentType.projectContext:
        return projectContext;
      case MemoryContentType.longTermGoal:
        return longTermGoal;
      case MemoryContentType.coreProject:
        return coreProject;
      case MemoryContentType.keyConstraint:
        return keyConstraint;
      case MemoryContentType.identityLevel:
        return identityLevel;
      case MemoryContentType.oneTimeDetail:
        return oneTimeDetail;
    }
  }
}
