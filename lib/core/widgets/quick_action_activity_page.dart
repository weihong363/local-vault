import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_vault/features/quick_action/models/quick_action_type.dart';
import 'package:local_vault/features/quick_action/presentation/pages/quick_action_page.dart';

/// QuickActionActivity 专用页面 - 用于模板和摘要选择
class QuickActionActivityPage extends ConsumerStatefulWidget {
  const QuickActionActivityPage({super.key});

  @override
  ConsumerState<QuickActionActivityPage> createState() =>
      _QuickActionActivityPageState();
}

class _QuickActionActivityPageState
    extends ConsumerState<QuickActionActivityPage> {
  static const MethodChannel _channel =
      MethodChannel('com.ironion.localvault/quick_action');

  QuickActionType? _actionType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getActionType();
  }

  Future<void> _getActionType() async {
    try {
      final actionType = await _channel.invokeMethod<String>('getActionType');
      if (mounted) {
        setState(() {
          switch (actionType) {
            case 'OPEN_TEMPLATES':
              _actionType = QuickActionType.templates;
              break;
            case 'OPEN_SUMMARIES':
              _actionType = QuickActionType.summaries;
              break;
            default:
              _actionType = null;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('获取 action type 失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_actionType == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('无效的操作类型'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _finishActivity(),
                  child: const Text('关闭'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return QuickActionPage(
      actionType: _actionType!,
      onFinish: _finishActivity,
    );
  }

  Future<void> _finishActivity() async {
    try {
      await _channel.invokeMethod('finishActivity');
    } catch (e) {
      debugPrint('关闭 Activity 失败: $e');
      if (mounted) {
        context.pop();
      }
    }
  }
}
