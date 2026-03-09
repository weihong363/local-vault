import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_vault/features/gesture_config/models/gesture_config.dart';
import 'package:local_vault/features/gesture_config/domain/providers/gesture_config_provider.dart';

class GestureConfigPage extends ConsumerWidget {
  const GestureConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncConfigs = ref.watch(gestureConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('手势配置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _showResetDialog(context, ref);
            },
          ),
        ],
      ),
      body: asyncConfigs.when(
        data: (configs) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: configs.length,
            itemBuilder: (context, index) {
              return GestureConfigCard(
                config: configs[index],
                onUpdate: configs[index].readOnly
                    ? null
                    : (updatedConfig) {
                        ref.read(gestureConfigProvider.notifier).updateConfig(updatedConfig);
                      },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('错误: $error')),
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置为默认'),
        content: const Text('确定要将所有手势重置为默认设置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(gestureConfigProvider.notifier).resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已重置为默认设置')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

class GestureConfigCard extends StatelessWidget {
  final GestureConfig config;
  final Function(GestureConfig)? onUpdate;

  const GestureConfigCard({
    super.key,
    required this.config,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  config.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (config.readOnly) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '仅分享',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getActionDescription(config.action),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (!config.readOnly) ...[
              const SizedBox(height: 16),
              _ActionSelector(
                value: config.action,
                onChanged: onUpdate != null
                    ? (value) {
                        onUpdate!(config.copyWith(action: value));
                      }
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getActionDescription(GestureAction action) {
    switch (action) {
      case GestureAction.openTemplates:
        return '打开提示词模板';
      case GestureAction.saveSummary:
        return '通过分享保存摘要';
      case GestureAction.openSummaries:
        return '打开已保存的上下文';
    }
  }
}

class _ActionSelector extends StatelessWidget {
  final GestureAction value;
  final Function(GestureAction)? onChanged;

  const _ActionSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '触发动作',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<GestureAction>(
          value: value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: GestureAction.values.map((action) {
            return DropdownMenuItem<GestureAction>(
              value: action,
              child: Text(_getActionLabel(action)),
            );
          }).toList(),
          onChanged: onChanged != null
              ? (value) {
                  if (value != null) {
                    onChanged!(value);
                  }
                }
              : null,
        ),
      ],
    );
  }

  String _getActionLabel(GestureAction action) {
    switch (action) {
      case GestureAction.openTemplates:
        return '打开提示词模板';
      case GestureAction.saveSummary:
        return '通过分享保存摘要';
      case GestureAction.openSummaries:
        return '打开已保存的上下文';
    }
  }
}
