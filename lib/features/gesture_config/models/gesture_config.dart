enum GestureType {
  tap2, // 轻点 2 下
  tap3, // 轻点 3 下
}

enum GestureAction {
  openTemplates,
  saveSummary,
  openSummaries,
}

class GestureConfig {
  final int id;
  final String name;
  final GestureType gestureType;
  final int fingerCount;
  final GestureAction action;
  final bool readOnly;

  GestureConfig({
    required this.id,
    required this.name,
    required this.gestureType,
    required this.fingerCount,
    required this.action,
    this.readOnly = false,
  });

  GestureConfig copyWith({
    int? id,
    String? name,
    GestureType? gestureType,
    int? fingerCount,
    GestureAction? action,
    bool? readOnly,
  }) {
    return GestureConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      gestureType: gestureType ?? this.gestureType,
      fingerCount: fingerCount ?? this.fingerCount,
      action: action ?? this.action,
      readOnly: readOnly ?? this.readOnly,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gestureType': gestureType.index,
      'fingerCount': fingerCount,
      'action': action.index,
      'readOnly': readOnly,
    };
  }

  factory GestureConfig.fromJson(Map<String, dynamic> json) {
    final gestureTypeIndex = json['gestureType'] as int;
    final actionIndex = json['action'] as int;
    
    // 安全地转换枚举，处理旧的配置数据
    final gestureType = gestureTypeIndex >= 0 && gestureTypeIndex < GestureType.values.length
        ? GestureType.values[gestureTypeIndex]
        : GestureType.tap2; // 默认值
    
    final action = actionIndex >= 0 && actionIndex < GestureAction.values.length
        ? GestureAction.values[actionIndex]
        : GestureAction.openTemplates; // 默认值
    
    return GestureConfig(
      id: json['id'] as int,
      name: json['name'] as String,
      gestureType: gestureType,
      fingerCount: json['fingerCount'] as int,
      action: action,
      readOnly: json['readOnly'] as bool? ?? false,
    );
  }

  static List<GestureConfig> getDefaultConfigs() {
    return [
      GestureConfig(
        id: 1,
        name: '轻点 2 下',
        gestureType: GestureType.tap2,
        fingerCount: 2,
        action: GestureAction.openTemplates,
      ),
      GestureConfig(
        id: 2,
        name: '轻点 3 下',
        gestureType: GestureType.tap3,
        fingerCount: 3,
        action: GestureAction.openSummaries,
      ),
      GestureConfig(
        id: 3,
        name: '保存摘要',
        gestureType: GestureType.tap2,
        fingerCount: 2,
        action: GestureAction.saveSummary,
        readOnly: true,
      ),
    ];
  }
}
