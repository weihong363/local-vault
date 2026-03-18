import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/core/constants/app_theme.dart';
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/domain/entities/summary_merge_models.dart';
import 'package:local_vault/core/providers/summary_entities_provider.dart';
import 'package:local_vault/core/services/app_settings_service.dart';
import 'package:local_vault/core/services/ocr_service.dart';
import 'package:local_vault/core/services/summary_metadata_service.dart';
import 'package:local_vault/features/memory/presentation/pages/memory_merge_diff_page.dart';

class SavePage extends ConsumerStatefulWidget {
  final dynamic initialData; // 可以是 String 或 Map (图片分享) 或 SummaryEntity (编辑)
  final SummaryEntity? editingSummary; // 要编辑的摘要

  const SavePage({super.key, this.initialData, this.editingSummary});

  @override
  ConsumerState<SavePage> createState() => _SavePageState();
}

class _SavePageState extends ConsumerState<SavePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  String _source = 'manual';
  bool _hasInitializedShareText = false;
  bool _isSaving = false; // 添加保存状态
  bool _isProcessingOcr = false; // OCR 处理中
  bool _previewEnabled = false;
  bool _isGeneratingPreview = false;
  PreparedSummaryDraft? _previewDraft;
  String? _previewError;
  Timer? _previewDebounce;
  int _previewGeneration = 0;
  String? _lastPreviewSignature;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onPreviewInputChanged);
    _contentController.addListener(_onPreviewInputChanged);
    _tagsController.addListener(_onPreviewInputChanged);
    _remarkController.addListener(_onPreviewInputChanged);
    _loadPreviewPreference();

    // 先检查是否是编辑模式
    if (widget.editingSummary != null) {
      _initEditMode();
      return;
    }

    // 延迟到第一帧后检查路由参数，确保 ModalRoute 已准备好
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // 先尝试从路由参数获取（优先级更高）
      await _checkRouteArguments();

      // 如果路由参数失败，记录日志但不主动从 MethodChannel 拉取
      // 因为 ShareService 已经在 main.dart 中统一处理了
      if (!_hasInitializedShareText) {
        debugPrint('⚠️ [SavePage] 未从路由参数获取到分享文本，请检查 ShareService');
      }
    });
  }

  /// 初始化编辑模式
  void _initEditMode() {
    final summary = widget.editingSummary!;
    debugPrint('✏️ [SavePage] 编辑模式：${summary.title}');

    _titleController.text = summary.title;
    _contentController.text = summary.content;
    _tagsController.text = summary.tags.join(', ');
    _source = summary.source;
    _hasInitializedShareText = true;
  }

  /// 检查路由参数（优先级更高）
  Future<bool> _checkRouteArguments() async {
    try {
      // 等待一小段时间确保 ModalRoute 已准备好
      await Future.delayed(const Duration(milliseconds: 10));

      if (!mounted) return false;

      // 首先尝试从构造函数的 initialData 获取（GoRouter extra）
      if (widget.initialData != null) {
        // 处理文本分享
        if (widget.initialData is String && widget.initialData!.isNotEmpty) {
          final text = widget.initialData as String;
          debugPrint(
              '✅ [SavePage] 从 GoRouter extra 获取分享文本成功：${text.substring(0, math.min(50, text.length))}...');
          setState(() {
            _contentController.text = text;
            _source = 'share';
            _hasInitializedShareText = true;
          });
          return true;
        }

        // 处理图片分享
        if (widget.initialData is Map) {
          final data = widget.initialData as Map;
          final type = data['type'] as String?;
          final uris = data['uris'] as List<dynamic>?;

          if (type == 'image' && uris != null && uris.isNotEmpty) {
            debugPrint('🖼️ [SavePage] 检测到图片分享，开始 OCR 识别...');
            await _processImageOcr(uris.map((u) => u as String).toList());
            return true;
          }
        }
      }

      // 如果 initialData 为空或不是预期类型，再尝试从 ModalRoute 获取（兼容旧方式）
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.isNotEmpty) {
        debugPrint(
            '✅ [SavePage] 从 ModalRoute 获取分享文本成功：${args.substring(0, math.min(50, args.length))}...');
        setState(() {
          _contentController.text = args;
          _source = 'share';
          _hasInitializedShareText = true;
        });
        return true;
      }

      debugPrint('⚠️ [SavePage] 未找到分享文本（initialData 和 ModalRoute 均为空）');
      return false;
    } catch (e) {
      debugPrint('❌ [SavePage] 获取路由参数失败：$e');
      return false;
    }
  }

  /// 处理图片 OCR 识别
  Future<void> _processImageOcr(List<String> uris) async {
    if (_isProcessingOcr) return;

    setState(() {
      _isProcessingOcr = true;
      _source = 'share_ocr';
    });

    try {
      debugPrint('🔍 [SavePage] 开始对 ${uris.length} 张图片进行 OCR 识别');

      final ocrService = OcrService();
      OcrResult result;

      if (uris.length == 1) {
        result = await ocrService.recognizeTextFromUri(uris.first);
      } else {
        result = await ocrService.recognizeTextFromUris(uris);
      }

      if (result.success && result.text.isNotEmpty) {
        debugPrint('✅ [SavePage] OCR 识别成功，识别出 ${result.text.length} 个字符');
        setState(() {
          _contentController.text = result.text;
          _titleController.text =
              'OCR 识别 - ${DateTime.now().toString().substring(0, 16)}';
          _hasInitializedShareText = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('成功识别 ${result.text.length} 个字符'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint('⚠️ [SavePage] OCR 识别失败：${result.error}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('OCR 识别失败：${result.error ?? '未知错误'}')),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [SavePage] OCR 处理异常：$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('OCR 处理失败：${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingOcr = false;
        });
      }
    }
  }

  // 注意：_loadShareTextFromChannel 方法已移除
  // 现在由 ShareService 在 main.dart 中统一处理

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _titleController.removeListener(_onPreviewInputChanged);
    _contentController.removeListener(_onPreviewInputChanged);
    _tagsController.removeListener(_onPreviewInputChanged);
    _remarkController.removeListener(_onPreviewInputChanged);
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _remarkController.dispose(); // 释放备注控制器
    super.dispose();
  }

  Future<void> _loadPreviewPreference() async {
    final previewEnabled =
        await sl<AppSettingsService>().isSummaryMetadataPreviewEnabled();
    if (!mounted) {
      return;
    }
    setState(() {
      _previewEnabled = previewEnabled;
    });
    if (previewEnabled) {
      _schedulePreviewRefresh();
    }
  }

  void _onPreviewInputChanged() {
    _lastPreviewSignature = null;
    if (!_previewEnabled) {
      return;
    }
    _schedulePreviewRefresh();
  }

  void _schedulePreviewRefresh() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _generatePreview(),
    );
  }

  Future<void> _togglePreview(bool value) async {
    await sl<AppSettingsService>().setSummaryMetadataPreviewEnabled(value);
    if (!mounted) {
      return;
    }

    setState(() {
      _previewEnabled = value;
      if (!value) {
        _previewDraft = null;
        _previewError = null;
        _isGeneratingPreview = false;
      }
    });

    if (value) {
      _schedulePreviewRefresh();
    } else {
      _previewDebounce?.cancel();
    }
  }

  Future<void> _generatePreview({bool force = false}) async {
    final content = _contentController.text.trim();
    final signature = _buildPreviewSignature();
    if (!force &&
        _lastPreviewSignature == signature &&
        (_previewDraft != null || _previewError != null)) {
      return;
    }

    if (content.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _previewDraft = null;
        _previewError = '输入内容后即可预览推荐的标题和标签';
        _isGeneratingPreview = false;
      });
      return;
    }

    final generation = ++_previewGeneration;
    if (mounted) {
      setState(() {
        _isGeneratingPreview = true;
        _previewError = null;
      });
    }

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
      final draft = await sl<SummaryMetadataService>().preparePreview(
        title: _titleController.text.trim(),
        content: content,
        tags: tags,
        remark: _remarkController.text.trim(),
      );

      if (!mounted || generation != _previewGeneration) {
        return;
      }

      setState(() {
        _previewDraft = draft;
        _previewError = null;
        _isGeneratingPreview = false;
        _lastPreviewSignature = signature;
      });
    } catch (e) {
      if (!mounted || generation != _previewGeneration) {
        return;
      }
      setState(() {
        _previewDraft = null;
        _previewError = '预览生成失败：$e';
        _isGeneratingPreview = false;
      });
    }
  }

  void _applyPreviewToForm() {
    final draft = _previewDraft;
    if (draft == null) {
      return;
    }

    setState(() {
      _titleController.text = draft.title;
      _tagsController.text = draft.tags.join(', ');
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已将预览结果填入标题和标签'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _buildPreviewSignature() {
    return [
      _titleController.text.trim(),
      _contentController.text.trim(),
      _remarkController.text.trim(),
      _tagsController.text.trim(),
      _previewEnabled.toString(),
    ].join('::');
  }

  Future<void> _saveSummary() async {
    // 防止重复点击
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      final remark = _remarkController.text.trim();
      final inputTags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      if (content.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('内容不能为空'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final prepared = await sl<SummaryMetadataService>().prepareForSave(
        title: title,
        content: content,
        tags: inputTags,
        remark: remark,
      );
      final finalTitle = prepared.title;
      final fullContent = prepared.content;
      final tags = prepared.tags;

      if (title.isEmpty) {
        _titleController.text = finalTitle;
      }
      if (inputTags.isEmpty && tags.isNotEmpty) {
        _tagsController.text = tags.join(', ');
      }

      var successMessage =
          widget.editingSummary != null ? '已更新摘要' : '已保存到本地记忆库';

      // 判断是新增还是编辑
      if (widget.editingSummary != null) {
        // 编辑模式
        final updatedSummary = widget.editingSummary!.copyWith(
          title: finalTitle,
          content: fullContent,
          tags: tags,
          updatedAt: DateTime.now(),
        );

        debugPrint('✏️ [SavePage] 更新摘要：${updatedSummary.title}');
        await ref
            .read(summaryEntityNotifierProvider.notifier)
            .updateSummary(updatedSummary);
        debugPrint('✅ [SavePage] 更新成功');
      } else {
        // 新增模式
        final summary = SummaryEntity.create(
          title: finalTitle,
          content: fullContent,
          tags: tags,
          source: _source,
        );

        debugPrint('💾 [SavePage] 准备保存摘要：${summary.title}');
        final result = await ref
            .read(summaryEntityNotifierProvider.notifier)
            .addFactSummary(summary);
        debugPrint('✅ [SavePage] 保存成功');

        if (result.wasExactDuplicate) {
          successMessage = '检测到重复事实记忆，已更新已有记录';
        } else if (result.hasMergeSuggestions && mounted) {
          final candidate = await _showMergeCandidatePicker(result);
          if (!mounted) {
            return;
          }
          if (candidate != null) {
            final merged = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => MemoryMergeDiffPage(
                  primarySummary: candidate.summary,
                  secondarySummary: result.savedSummary,
                  primaryLabel: '原有事实记忆',
                  secondaryLabel: '新保存事实记忆',
                  similarity: candidate.similarity,
                ),
              ),
            );
            if (merged == true) {
              successMessage = '已保存并合并事实记忆';
            }
          }
        }
      }

      if (mounted) {
        // ❌ 不要直接 pop，而是跳转到首页
        // Navigator.pop(context);

        // ✅ 使用 GoRouter 导航到首页
        context.go(AppRoutes.home);

        // 显示成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(successMessage),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [SavePage] 保存失败：$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('保存失败：${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<SummaryMergeCandidate?> _showMergeCandidatePicker(
    FactSummarySaveResult result,
  ) {
    return showDialog<SummaryMergeCandidate>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('发现可合并的事实记忆'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('“${result.savedSummary.title}” 已保存，发现以下合并候选：'),
              const SizedBox(height: 12),
              SizedBox(
                height: 280,
                child: SingleChildScrollView(
                  child: Column(
                    children: result.mergeCandidates
                        .map(
                          (candidate) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(candidate.summary.title),
                            subtitle: Text(
                              '相似度 ${(candidate.similarity * 100).toStringAsFixed(1)}% · '
                              '${candidate.summary.content}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).pop(candidate),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('稍后处理'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editingSummary != null ? '编辑摘要' : '保存内容',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : null,
          ),
        ),
        elevation: 0,
        actions: [
          // 显示分享文本来源指示器
          Builder(
            builder: (context) {
              final hasShareText =
                  _source == 'share' && _contentController.text.isNotEmpty;
              if (hasShareText) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: isDark ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                            Colors.green.withValues(alpha: isDark ? 0.5 : 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.share, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        '分享',
                        style: TextStyle(
                          color: isDark
                              ? Colors.green.shade400
                              : Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 标题输入框
          TextField(
            controller: _titleController,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : null,
            ),
            decoration: InputDecoration(
              labelText: '标题 *',
              hintText: '请输入标题',
              hintStyle: TextStyle(
                color: isDark ? AppColors.darkTextMuted : Colors.grey.shade400,
              ),
              labelStyle: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : null,
              ),
              prefixIcon: Icon(Icons.title,
                  color: isDark ? AppColors.primary : Colors.blue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.primary : Colors.blue.shade300,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor:
                  isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
            ),
          ),

          const SizedBox(height: 20),

          // 内容输入框
          TextField(
            controller: _contentController,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : null,
            ),
            decoration: InputDecoration(
              labelText: '内容 *',
              hintText: '从其他应用分享的内容将自动填充到这里',
              hintStyle: TextStyle(
                color: isDark ? AppColors.darkTextMuted : Colors.grey.shade400,
              ),
              labelStyle: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : null,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Icon(Icons.notes,
                    color: isDark ? AppColors.primary : Colors.blue),
              ),
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.primary : Colors.blue.shade300,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor:
                  isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
            ),
            maxLines: 8,
            minLines: 5,
          ),

          const SizedBox(height: 20),

          // 备注输入框
          TextField(
            controller: _remarkController,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : null,
            ),
            decoration: InputDecoration(
              labelText: '备注',
              hintText: '添加一些备注说明（可选）',
              hintStyle: TextStyle(
                color: isDark ? AppColors.darkTextMuted : Colors.grey.shade400,
              ),
              labelStyle: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : null,
              ),
              prefixIcon: Icon(Icons.comment,
                  color: isDark ? Colors.orange.shade400 : Colors.orange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      isDark ? Colors.orange.shade400 : Colors.orange.shade300,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor:
                  isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
            ),
            maxLines: 4,
            minLines: 2,
          ),

          const SizedBox(height: 20),

          // 标签输入框
          TextField(
            controller: _tagsController,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : null,
            ),
            decoration: InputDecoration(
              labelText: '标签',
              hintText: '用逗号分隔多个标签',
              hintStyle: TextStyle(
                color: isDark ? AppColors.darkTextMuted : Colors.grey.shade400,
              ),
              labelStyle: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : null,
              ),
              prefixIcon: Icon(Icons.local_offer,
                  color: isDark ? Colors.purple.shade400 : Colors.purple),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      isDark ? Colors.purple.shade400 : Colors.purple.shade300,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor:
                  isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
            ),
          ),

          const SizedBox(height: 16),

          SwitchListTile.adaptive(
            value: _previewEnabled,
            onChanged: _togglePreview,
            contentPadding: EdgeInsets.zero,
            title: const Text('预览推荐标题和标签'),
            subtitle: const Text(
              '开启后会根据当前内容生成建议，不会自动覆盖你的表单内容',
            ),
          ),

          if (_previewEnabled) ...[
            const SizedBox(height: 12),
            _buildPreviewCard(isDark),
          ],

          const SizedBox(height: 32),

          // 保存按钮
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveSummary,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save_alt, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          widget.editingSummary != null ? '更新摘要' : '保存到本地记忆库',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // 提示文字
          Center(
            child: Text(
              '带 * 为必填项',
              style: TextStyle(
                color: isDark ? AppColors.darkTextMuted : Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(bool isDark) {
    final previewDraft = _previewDraft;
    final previewError = _previewError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceVariant.withValues(alpha: 0.85)
            : Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.35)
              : Colors.blueGrey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 18,
                color: isDark ? AppColors.primary : Colors.blueGrey.shade700,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '保存结果预览',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _isGeneratingPreview
                    ? null
                    : () => _generatePreview(force: true),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('刷新'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '预览会优先根据正文推荐更适合作为摘要的标题和标签。',
            style: TextStyle(
              fontSize: 12,
              color:
                  isDark ? AppColors.darkTextMuted : Colors.blueGrey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          if (_isGeneratingPreview)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (previewError != null)
            Text(
              previewError,
              style: TextStyle(
                color: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
              ),
            )
          else if (previewDraft != null) ...[
            _buildPreviewField(
              label: '推荐标题',
              value: previewDraft.title,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            Text(
              '推荐标签',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.darkTextMuted : Colors.blueGrey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: previewDraft.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: _applyPreviewToForm,
                  icon: const Icon(Icons.auto_fix_high_outlined),
                  label: const Text('应用到表单'),
                ),
                const SizedBox(width: 12),
                Text(
                  previewDraft.usedModel ? '来自内置模型' : '来自本地规则',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : Colors.blueGrey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewField({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextMuted : Colors.blueGrey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color:
                isDark ? AppColors.darkTextPrimary : Colors.blueGrey.shade900,
          ),
        ),
      ],
    );
  }
}
