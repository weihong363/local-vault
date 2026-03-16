import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/core/constants/app_theme.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/providers/summary_entities_provider.dart';
import 'package:local_vault/core/services/ocr_service.dart';
import 'package:local_vault/core/utils/summary_text_utils.dart';

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

  @override
  void initState() {
    super.initState();

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
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _remarkController.dispose(); // 释放备注控制器
    super.dispose();
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

      String finalTitle = title;
      if (finalTitle.isEmpty) {
        finalTitle = SummaryTextUtils.generateTitle(content);
        _titleController.text = finalTitle;
      }
      finalTitle = SummaryTextUtils.compressTitle(finalTitle);

      // 如果有备注，将备注添加到内容中
      final fullContent =
          remark.isNotEmpty ? '$content\n\n---备注---\n$remark' : content;

      final tags = inputTags.isNotEmpty
          ? inputTags
          : SummaryTextUtils.generateTags(finalTitle, fullContent);

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
        await ref
            .read(summaryEntityNotifierProvider.notifier)
            .addWithDeduplication(summary);
        debugPrint('✅ [SavePage] 保存成功');
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
                Text(widget.editingSummary != null ? '已更新摘要' : '已保存到本地记忆库'),
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
                          color: isDark ? Colors.green.shade400 : Colors.green.shade700,
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
              prefixIcon: Icon(Icons.title, color: isDark ? AppColors.primary : Colors.blue),
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
              fillColor: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
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
                child: Icon(Icons.notes, color: isDark ? AppColors.primary : Colors.blue),
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
              fillColor: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
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
              prefixIcon: Icon(Icons.comment, color: isDark ? Colors.orange.shade400 : Colors.orange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.orange.shade400 : Colors.orange.shade300, 
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
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
              prefixIcon: Icon(Icons.local_offer, color: isDark ? Colors.purple.shade400 : Colors.purple),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.purple.shade400 : Colors.purple.shade300, 
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
            ),
          ),

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
}
