# Summary Save Service Usage Guide

## Overview

This project has encapsulated a unified summary saving interface, supporting multiple trigger methods:

- **Share trigger** (`SaveTriggerType.share`) - through system share menu
- **Gesture trigger** (`SaveTriggerType.gesture`) - back tap and other gestures
- **Quick action** (`SaveTriggerType.quickAction`) - control center floating ball
- **Voice wake-up** (`SaveTriggerType.voice`) - voice commands
- **Manual trigger** (`SaveTriggerType.manual`) - in-app buttons

## Core Class Explanation

### 1. SaveContext (Save Context)

Records the trigger source and metadata of the save operation:

```dart
// Create share context
final context = SaveContext.share(metadata: {
  'sourceApp': 'com.android.chrome',
});

// Create gesture context
final context = SaveContext.gesture(
  tapCount: 2,
  packageName: 'com.tencent.mm',
);

// Create quick action context
final context = SaveContext.quickAction(actionId: 'floating_ball');
```

### 2. SavePayload (Save Data)

Encapsulates the content to be saved:

```dart
// Create from share text
final payload = SavePayload.fromShare(sharedText);

// Create from OCR result
final payload = SavePayload.fromOCR(recognizedText);

// Manually create complete data
final payload = SavePayload(
  title: 'Important Note',
  content: 'This is content...',
  tags: ['Work', 'Meeting'],
  remark: 'Need to follow up',
  sourceType: 'manual',
);
```

### 3. SummarySaveService (Save Service)

Core service class, providing hook mechanism:

```dart
final saveService = SummarySaveService();

// Register before save hook
saveService.registerBeforeSave((payload, context) async {
// Can do preprocessing, validation, etc. here
  if (payload.content.isEmpty) {
return false; // Interrupt save
  }
return true; // Continue saving
});

// Register after save hook
saveService.registerAfterSave((payload, context, success) {
  if (success) {
debugPrint('Save successful: ${payload.title}');
  }
});
```

### 4. SaveCoordinator (Save Coordinator)

Facade pattern, simplifies calling:

```dart
final coordinator = SaveCoordinator();

// Handle share trigger
await coordinator.handleShare(text: sharedText);

// Handle gesture trigger
await coordinator.handleGesture(
  content: clipboardContent,
  tapCount: 2,
  packageName: currentApp,
);

// Handle quick action trigger
await coordinator.handleQuickAction(
  content: quickActionContent,
  actionId: 'ball_001',
);

// Handle voice trigger
await coordinator.handleVoice(
  content: voiceRecognizedText,
voiceCommand: 'Save to memory bank',
);

// Handle manual trigger (direct save, no UI)
await coordinator.handleManual(
title: 'Title',
content: 'Content',
tags: ['Tag 1',
'
Tag
2
'
]
,
);
```

## Integration Examples

### Handling Share in MainActivity.kt

```kotlin
when (it.action) {
   Intent.ACTION_SEND -> {
        when {
            mimeType == "text/plain" -> {
               val text = it.getStringExtra(Intent.EXTRA_TEXT)
               if (text != null) {
                   // Native side cache
                    pendingShareText = text
                   // Notify Flutter side
                    shareChannel?.invokeMethod("onShareReceived", text)
                }
            }
        }
    }
}
```

### Listening for Share in main.dart

```dart
void _initializeShareService() {
  final shareService = ShareService();
  shareService.initialize();

  // Listen to share stream
  _shareSubscription = shareService.shareStream.listen((sharedText) {
   if (mounted) {
     // Use coordinator to handle uniformly
      SaveCoordinator().handleShare(text: sharedText.text);
    }
  });
}
```

### Calling in Gesture Service

```dart
class FloatingWindowService {
  Future<void> handleGesture(int tapCount, String packageName) async {
    // Get content from clipboard
    final content = await Clipboard.getData(Clipboard.kTextPlain);
    
   if (content?.text != null) {
     // Use coordinator to handle gesture-triggered save
     await SaveCoordinator().handleGesture(
        content: content!.text!,
        tapCount: tapCount,
        packageName: packageName,
      );
    }
  }
}
```

## Hook Usage Scenarios

### 1. Automatic Tag Addition

```dart
SaveCoordinator().registerBeforeSave((payload, context) async {
// Automatically add tags based on trigger source
  List<String> autoTags = [];
  
  if (context.triggerType == SaveTriggerType.share) {
autoTags.add('From Share');
  } else if (context.triggerType == SaveTriggerType.gesture) {
autoTags.add('Gesture Quick Save');
  }

// Return modified payload (need to extend Payload to support copyWith)
 return true;
});
```

### 2. Save Statistics

```dart
SaveCoordinator().registerAfterSave((payload, context, success) {
  if (success) {
// Record statistical information
    Analytics.log('summary_saved', {
      'trigger_type': context.triggerType.name,
      'source_type': payload.sourceType,
      'has_tags': payload.tags.isNotEmpty,
    });
  }
});
```

### 3. Intelligent Title Generation

```dart
SaveCoordinator().registerBeforeSave((payload, context) async {
// If title is empty, try to extract from content
  if (payload.title.isEmpty && payload.content.isNotEmpty) {
    final firstLine = payload.content.split('\n').first;
// Can call AI to generate title or extract keywords
    // final generatedTitle = await AIService.generateTitle(firstLine);
  }
 return true;
});
```

## Best Practices

### 1. Single Responsibility Principle

Each trigger method has its own independent processing method, keeping responsibilities clear.

### 2. Open/Closed Principle

Extend functionality through hook mechanism without modifying core code.

### 3. Dependency Inversion

Upper-level business depends on abstract `SaveContext` and `SavePayload`, not specific implementations.

### 4. Logging

All key steps have detailed log output for easy debugging.

### 5. Error Handling

Each method has try-catch protection to prevent app crashes.

## Future Extensions

### 1. Batch Save

```dart
Future<bool> handleBatchSave({
 required List<SavePayload> payloads,
 required SaveContext context,
}) async {
  // Batch processing logic
}
```

### 2. Scheduled Save

```dart
Future<void> scheduleAutoSave({
 required String content,
 required Duration interval,
}) async {
  // Scheduled auto-save logic
}
```

### 3. Cloud Sync

```dart
SaveCoordinator().registerAfterSave((payload, context, success) async {
  if (success) {
// Async sync to cloud
   await CloudSyncService().sync(payload);
  }
});
```

## Notes

1. **Thread Safety**: All methods are asynchronous, avoid performing time-consuming operations on UI thread
2. **Memory Management**: Clean up unnecessary hooks in time to avoid memory leaks
3. **Test Coverage**: Write unit tests for each trigger method
4. **Permission Check**: Some trigger methods (like gestures, floating balls) require special permissions

## Related Documents

- [SHARE_SOLUTION.md](SHARE_SOLUTION.md) - Detailed design of sharing functionality
- [LocalVault-Context.md](../LocalVault-Context.md) - Project core ideas and capability summary
