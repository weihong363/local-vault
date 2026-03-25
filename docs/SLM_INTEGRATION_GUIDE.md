# SLM Integration Implementation Guide

> Update time: 2026-03-18  
> This document has been updated from a "pure planning document" to "current implementation status + follow-up
> recommendations".

---

## Current Conclusion

Local Vault's SLM integration has entered the "runnable enhancement layer" stage, not just a paper design.

The current SLM solution in the project has the following characteristics:

- There is already a real `MemorySLMService` implementation, not a placeholder interface.
- It has been integrated into memory merging, topic extraction, upgrade reasons, and title tag generation during saving.
- Strategies and prompts have been externalized into JSON configurations, not all hard-coded.
- The security strategy of "immediately falling back to rules when the model is unavailable" is adopted by default.

In other words, the current positioning of SLM is:

**Enhance memory quality, but never block the main流程 of saving, retrieving, displaying, and cleaning.**

---

## Core Architecture

### Current Architecture

```
┌─────────────────────────────────────────────────┐
│                  MemorySLMService              │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌─────────────┐     No     ┌─────────────┐     │
│  │ Model       │──────────►│ Rule Engine │     │
│  │ Available?  │            └──────┬──────┘     │
│  └──────┬──────┘                  │           │
│         │ Yes                     │           │
│         ▼                         │           │
│  ┌─────────────┐                  │           │
│  │ SLM         │                  │           │
│  │ Processing  │◄─────────────────┘           │
│  └──────┬──────┘                              │
│         │                                     │
│         ▼                                     │
│  ┌─────────────┐                              │
│  │ Result      │                              │
│  │ Processing  │                              │
│  └─────────────┘                              │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Key Files

| File                                               | Purpose                    | Status |
|----------------------------------------------------|----------------------------|--------|
| `lib/core/domain/services/memory_slm_service.dart` | SLM service implementation | ✅      |
| `lib/core/domain/services/topic_extractor.dart`    | Topic extraction service   | ✅      |
| `lib/core/domain/services/memory_merger.dart`      | Memory merging service     | ✅      |
| `assets/configs/slm_strategies.json`               | SLM strategy configuration | ✅      |

---

## Implementation Status

### 1. MemorySLMService ✅

**Core Methods**:

| Method               | Function                          | Status |
|----------------------|-----------------------------------|--------|
| `extractTopic()`     | Extract topic from memory content | ✅      |
| `mergeMemories()`    | Merge multiple memories           | ✅      |
| `generateTitle()`    | Generate title for memory         | ✅      |
| `generateTags()`     | Generate tags for memory          | ✅      |
| `explainPromotion()` | Explain promotion reasons         | ✅      |

**Fallback Mechanism**:

```dart
Future<String> extractTopic(String content) async {
   try {
      if (!isModelAvailable()) {
         return _ruleBasedTopicExtractor.extract(content); // Fallback
      }

      final prompt = _strategies['topic_extraction']['prompt']
              .replaceAll('{content}', content);

      final result = await _slmClient.generate(prompt);
      return result.trim();
   } catch (e) {
      _logger.warning('SLM topic extraction failed, falling back to rules: $e');
      return _ruleBasedTopicExtractor.extract(content); // Fallback
   }
}
```

### 2. External Configuration ✅

**`slm_strategies.json`**:

```json
{
   "strategies": {
      "topic_extraction": {
         "prompt": "Extract a concise topic from this content: {content}",
         "max_length": 50
      },
      "memory_merging": {
         "prompt": "Merge these two memories into one coherent memory: {memory1}\n{memory2}",
         "max_length": 500
      },
      "title_generation": {
         "prompt": "Generate a concise title for this memory: {content}",
         "max_length": 100
      },
      "tag_generation": {
         "prompt": "Generate 3-5 relevant tags for this memory: {content}",
         "max_length": 100
      },
      "promotion_explanation": {
         "prompt": "Explain why this memory should be promoted: {content}",
         "max_length": 200
      }
   }
}
```

### 3. Integration Points ✅

**Where SLM is used**:

| Integration Point                              | Purpose                      | Status |
|------------------------------------------------|------------------------------|--------|
| `SummaryUseCases.addSessionMemory()`           | Title/topic/tags generation  | ✅      |
| `SummaryUseCases.mergeMemories()`              | Memory merging               | ✅      |
| `SummaryUseCases._upgradeFactToCoreIfNeeded()` | Promotion reason explanation | ✅      |
| `TopicExtractor.extract()`                     | Topic extraction             | ✅      |

---

## Usage Examples

### 1. Basic Usage

```dart

final slmService = ref.read(memorySLMServiceProvider);

// Extract topic
final topic = await
slmService.extractTopic
(
memoryContent);

// Merge memories
final mergedMemory = await slmService.mergeMemories([memory1, memory2]);

// Generate title and tags
final title = await slmService.generateTitle(memoryContent);
final tags = await slmService.generateTags(memoryContent);

// Explain promotion
final explanation = await slmService.explainPromotion(memoryContent);
```

### 2. Integration with Save Flow

```dart
// In SummaryUseCases.addSessionMemory()
Future<void> addSessionMemory(SummaryEntity summary) async {
   // Generate topic using SLM (with fallback)
   final topic = await _slmService.extractTopic(summary.content);

   // Generate title if not provided
   if (summary.title.isEmpty) {
      summary = summary.copyWith(
         title: await _slmService.generateTitle(summary.content),
      );
   }

   // Generate tags if empty
   if (summary.tags.isEmpty) {
      final tags = await _slmService.generateTags(summary.content);
      summary = summary.copyWith(tags: tags.split(',').map((t) => t.trim()).toList());
   }

   // Save to repository
   await _repository.saveSummary(summary);

   // Check promotion
   await _upgradeSessionToFactIfNeeded(summary.id);
}
```

---

## Performance Considerations

### Current Performance

| Operation        | SLM (ms)   | Rule-based (ms) |
|------------------|------------|-----------------|
| Topic extraction | ~500-1000  | ~10-50          |
| Memory merging   | ~1000-2000 | ~100-300        |
| Title generation | ~300-500   | ~50-100         |
| Tag generation   | ~400-600   | ~50-150         |

### Optimization Strategies

1. **Caching**: Cache SLM results for similar inputs
2. **Background Processing**: Use isolates for SLM operations
3. **Batch Processing**: Group multiple SLM requests
4. **Progressive Enhancement**: Show rule-based results first, then update with SLM

---

## Security Strategy

### Core Security Principles

1. **No Network Dependency**: SLM runs locally, no network calls
2. **Fallback Safety**: Always fallback to rule-based methods
3. **Resource Limits**: Set memory and time limits for SLM
4. **Error Handling**: Gracefully handle SLM failures

### Implementation

```dart
class MemorySLMService {
   static const _MAX_MEMORY_USAGE = 256 * 1024 * 1024; // 256MB
   static const _MAX_EXECUTION_TIME = Duration(seconds: 5);

   Future<T> _withTimeout<T>(Future<T> future) async {
      try {
         return await future.timeout(_MAX_EXECUTION_TIME);
      } on TimeoutException {
         _logger.warning('SLM operation timed out');
         throw SLMTimeoutException();
      }
   }

   bool _checkResourceUsage() {
      final memoryUsage = _getCurrentMemoryUsage();
      if (memoryUsage > _MAX_MEMORY_USAGE) {
         _logger.warning('SLM memory usage exceeded: $memoryUsage');
         return false;
      }
      return true;
   }
}
```

---

## Model Management

### Current Model

| Model          | Size   | Quantization | Status |
|----------------|--------|--------------|--------|
| TinyLlama-1.1B | ~400MB | 4-bit        | ✅      |

### Model Selection Criteria

1. **Size**: Must be small enough for mobile devices
2. **Performance**: Fast inference for real-time use
3. **Quality**: Good enough for memory-related tasks
4. **License**: Permissive for commercial use

### Model Updates

```dart
class ModelManager {
   Future<bool> updateModel(String modelId) async {
      try {
         // Download model
         final modelPath = await _downloadModel(modelId);

         // Verify model
         if (!await _verifyModel(modelPath)) {
            _logger.error('Model verification failed');
            return false;
         }

         // Update model path
         _settingsService.setSLMModelPath(modelPath);
         return true;
      } catch (e) {
         _logger.error('Model update failed: $e');
         return false;
      }
   }
}
```

---

## Troubleshooting

### Common Issues

| Issue             | Cause                 | Solution                                |
|-------------------|-----------------------|-----------------------------------------|
| SLM not available | Model not downloaded  | Download model in settings              |
| SLM slow          | Model too large       | Use smaller quantized model             |
| SLM crashes       | Memory limit exceeded | Increase memory limit or use rule-based |
| Poor SLM results  | Inadequate prompt     | Update prompts in slm_strategies.json   |

### Debugging

```dart
// Enable SLM debug logs
final slmService = ref.read(memorySLMServiceProvider);
slmService.enableDebugLogs
(true);

// Check SLM status
final status = await slmService.getStatus();
print('SLM status: ${status.available}, Model: ${status.modelName}');

// Test SLM functionality
final testResult = await slmService.test();
print('SLM test result: 
$
testResult
'
);
```

---

## Future Enhancements

### Short-term

1. **Better Prompt Engineering**: Improve prompts for specific tasks
2. **Model Quantization**: Test different quantization levels
3. **Batch Processing**: Process multiple memories at once
4. **User Feedback Loop**: Learn from user corrections

### Long-term

1. **Model Fine-tuning**: Fine-tune model on memory-related data
2. **Multi-model Support**: Support different models for different tasks
3. **Edge AI Optimization**: Optimize for specific devices
4. **Cloud Fallback**: Optional cloud SLM for complex tasks

---

## Migration Guide

### From Rule-based to SLM

1. **Enable SLM** in settings
2. **Download model** if not already downloaded
3. **Test SLM** functionality
4. **Monitor performance** and adjust as needed

### Rollback

1. **Disable SLM** in settings
2. **Clear model cache** if needed
3. **System will automatically fallback** to rule-based methods

---

## Testing Strategy

### Test Cases

1. **Basic SLM functionality**
   - Topic extraction
   - Memory merging
   - Title generation
   - Tag generation

2. **Fallback mechanism**
   - SLM unavailable
   - SLM timeout
   - SLM error

3. **Performance**
   - Response time
   - Memory usage
   - Battery impact

4. **Quality**
   - Compare SLM vs rule-based results
   - User feedback on quality

---

## Deployment Notes

### Android

- **Storage**: ~500MB for model
- **Memory**: Minimum 2GB RAM
- **API Level**: 21+

### iOS

- **Storage**: ~500MB for model
- **Memory**: Minimum 2GB RAM
- **iOS Version**: 13+

### Web

- **Limited support**: SLM may not work in all browsers
- **Fallback**: Rule-based methods always available

---

## Conclusion

Local Vault's SLM integration is now a functional enhancement layer that improves memory quality without blocking the
main user flow. The implementation follows a conservative approach with robust fallback mechanisms to ensure
reliability.

Key achievements:

- ✅ Real SLM service implementation
- ✅ Externalized strategy configuration
- ✅ Seamless integration with existing code
- ✅ Robust fallback to rule-based methods
- ✅ Performance and security considerations

The SLM integration will continue to evolve, with a focus on improving model quality, performance, and user experience
while maintaining the core principle of local-first operation.

---

*Last updated: 2026-03-18*
*Version: v1.0.0*
