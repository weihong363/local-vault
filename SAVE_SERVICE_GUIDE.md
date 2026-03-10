# 摘要保存服务使用指南

## 概述

本项目已经封装了统一的摘要保存接口，支持多种触发方式：

- **分享触发** (`SaveTriggerType.share`) - 通过系统分享菜单
- **手势触发** (`SaveTriggerType.gesture`) - 背部敲击等手势
- **快捷操作** (`SaveTriggerType.quickAction`) - 控制中心悬浮球
- **语音唤醒** (`SaveTriggerType.voice`) - 语音指令
- **手动触发** (`SaveTriggerType.manual`) - 应用内按钮

## 核心类说明

### 1. SaveContext（保存上下文）

记录保存操作的触发来源和元数据：

```dart
// 创建分享上下文
final context = SaveContext.share(metadata: {
  'sourceApp': 'com.android.chrome',
});

// 创建手势上下文
final context = SaveContext.gesture(
  tapCount: 2,
  packageName: 'com.tencent.mm',
);

// 创建快捷操作上下文
final context = SaveContext.quickAction(actionId: 'floating_ball');
```

### 2. SavePayload（保存数据）

封装要保存的内容：

```dart
// 从分享文本创建
final payload = SavePayload.fromShare(sharedText);

// 从 OCR 结果创建
final payload = SavePayload.fromOCR(recognizedText);

// 手动创建完整数据
final payload = SavePayload(
  title: '重要笔记',
  content: '这是内容...',
  tags: ['工作', '会议'],
 remark: '需要跟进',
  sourceType: 'manual',
);
```

### 3. SummarySaveService（保存服务）

核心服务类，提供钩子机制：

```dart
final saveService = SummarySaveService();

// 注册保存前钩子
saveService.registerBeforeSave((payload, context) async {
  // 可以在这里做预处理、验证等
  if (payload.content.isEmpty) {
   return false; // 中断保存
  }
 return true; // 继续保存
});

// 注册保存后钩子
saveService.registerAfterSave((payload, context, success) {
  if (success) {
   debugPrint('保存成功：${payload.title}');
  }
});
```

### 4. SaveCoordinator（保存协调器）

门面模式，简化调用：

```dart
final coordinator = SaveCoordinator();

// 处理分享触发
await coordinator.handleShare(text: sharedText);

// 处理手势触发
await coordinator.handleGesture(
  content: clipboardContent,
  tapCount: 2,
  packageName: currentApp,
);

// 处理快捷操作触发
await coordinator.handleQuickAction(
  content: quickActionContent,
  actionId: 'ball_001',
);

// 处理语音触发
await coordinator.handleVoice(
  content: voiceRecognizedText,
  voiceCommand: '保存到记忆库',
);

// 处理手动触发（直接保存，不显示 UI）
await coordinator.handleManual(
  title: '标题',
  content: '内容',
  tags: ['标签 1', '标签 2'],
);
```

## 集成示例

### 在 MainActivity.kt 中处理分享

```kotlin
when (it.action) {
   Intent.ACTION_SEND -> {
        when {
            mimeType == "text/plain" -> {
               val text = it.getStringExtra(Intent.EXTRA_TEXT)
               if (text != null) {
                    // 原生端缓存
                    pendingShareText = text
                    // 通知 Flutter 端
                    shareChannel?.invokeMethod("onShareReceived", text)
                }
            }
        }
    }
}
```

### 在 main.dart 中监听分享

```dart
void _initializeShareService() {
  final shareService = ShareService();
  shareService.initialize();
  
  // 监听分享流
  _shareSubscription = shareService.shareStream.listen((sharedText) {
   if (mounted) {
      // 使用协调器统一处理
      SaveCoordinator().handleShare(text: sharedText.text);
    }
  });
}
```

### 在手势服务中调用

```dart
class FloatingWindowService {
  Future<void> handleGesture(int tapCount, String packageName) async {
    // 从剪贴板获取内容
    final content = await Clipboard.getData(Clipboard.kTextPlain);
    
   if (content?.text != null) {
      // 使用协调器处理手势触发保存
     await SaveCoordinator().handleGesture(
        content: content!.text!,
        tapCount: tapCount,
        packageName: packageName,
      );
    }
  }
}
```

## 钩子使用场景

### 1. 自动添加标签

```dart
SaveCoordinator().registerBeforeSave((payload, context) async {
  // 根据触发来源自动添加标签
  List<String> autoTags = [];
  
  if (context.triggerType == SaveTriggerType.share) {
    autoTags.add('来自分享');
  } else if (context.triggerType == SaveTriggerType.gesture) {
    autoTags.add('手势快速保存');
  }
  
  // 返回修改后的 payload（需要扩展 Payload 支持 copyWith）
 return true;
});
```

### 2. 保存统计

```dart
SaveCoordinator().registerAfterSave((payload, context, success) {
  if (success) {
    // 记录统计信息
    Analytics.log('summary_saved', {
      'trigger_type': context.triggerType.name,
      'source_type': payload.sourceType,
      'has_tags': payload.tags.isNotEmpty,
    });
  }
});
```

### 3. 智能标题生成

```dart
SaveCoordinator().registerBeforeSave((payload, context) async {
  // 如果标题为空，尝试从内容提取
  if (payload.title.isEmpty && payload.content.isNotEmpty) {
    final firstLine = payload.content.split('\n').first;
    // 可以调用 AI 生成标题或截取关键词
    // final generatedTitle = await AIService.generateTitle(firstLine);
  }
 return true;
});
```

## 最佳实践

### 1. 单一职责原则

每个触发方式都有独立的处理方法，保持职责清晰。

### 2. 开闭原则

通过钩子机制扩展功能，无需修改核心代码。

### 3. 依赖倒置

上层业务依赖抽象的 `SaveContext` 和 `SavePayload`，而非具体实现。

### 4. 日志记录

所有关键步骤都有详细的日志输出，便于调试。

### 5. 错误处理

每个方法都有 try-catch 保护，不会导致应用崩溃。

## 未来扩展

### 1. 批量保存

```dart
Future<bool> handleBatchSave({
 required List<SavePayload> payloads,
 required SaveContext context,
}) async {
  // 批量处理逻辑
}
```

### 2. 定时保存

```dart
Future<void> scheduleAutoSave({
 required String content,
 required Duration interval,
}) async {
  // 定时自动保存逻辑
}
```

### 3. 云同步

```dart
SaveCoordinator().registerAfterSave((payload, context, success) async {
  if (success) {
    // 异步同步到云端
   await CloudSyncService().sync(payload);
  }
});
```

## 注意事项

1. **线程安全**：所有方法都是异步的，避免在 UI 线程执行耗时操作
2. **内存管理**：及时清理不需要的钩子，避免内存泄漏
3. **测试覆盖**：为每个触发方式编写单元测试
4. **权限检查**：某些触发方式（如手势、悬浮球）需要特殊权限

## 相关文档

- [SHARE_SOLUTION.md](./SHARE_SOLUTION.md) - 分享功能详细设计
- [LocalVault-Context.md](./LocalVault-Context.md) - 项目核心思想与能力摘要
