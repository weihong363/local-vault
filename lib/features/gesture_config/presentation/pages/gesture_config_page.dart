import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_vault/features/gesture_config/domain/providers/gesture_config_provider.dart';
import 'package:local_vault/features/gesture_config/models/gesture_config.dart';
import 'package:local_vault/l10n/app_localizations.dart';

class GestureConfigPage extends ConsumerStatefulWidget {
  const GestureConfigPage({super.key});

  @override
  ConsumerState<GestureConfigPage> createState() => _GestureConfigPageState();
}

class _GestureConfigPageState extends ConsumerState<GestureConfigPage> {
  List<GestureConfig>? _tempConfigs;
  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final asyncConfigs = ref.watch(gestureConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.gestureConfiguration),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: () {
                setState(() {
                  _tempConfigs = null;
                  _hasChanges = false;
                });
              },
              child: Text(loc.cancelLabel),
            ),
          if (_hasChanges)
            ElevatedButton(
              onPressed: () async {
                if (_tempConfigs != null) {
                  final messenger = ScaffoldMessenger.of(context);
                  for (final config in _tempConfigs!) {
                    await ref
                        .read(gestureConfigProvider.notifier)
                        .updateConfig(config);
                  }
                  if (!context.mounted) return;
                  setState(() {
                    _tempConfigs = null;
                    _hasChanges = false;
                  });
                  messenger.showSnackBar(
                    SnackBar(content: Text(loc.gestureConfigurationSaved)),
                  );
                }
              },
              child: Text(loc.save),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _showResetDialog(context, ref),
          ),
        ],
      ),
      body: asyncConfigs.when(
        data: (configs) {
          final displayConfigs = _tempConfigs ?? configs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: displayConfigs.length,
            itemBuilder: (context, index) {
              return GestureConfigCard(
                config: displayConfigs[index],
                allConfigs: displayConfigs,
                onUpdate: displayConfigs[index].readOnly
                    ? null
                    : (updatedConfig) {
                        setState(() {
                          _tempConfigs ??= List.from(configs);

                          final newConfigs = _tempConfigs!.map((c) {
                            if (c.id == updatedConfig.id) {
                              return updatedConfig;
                            }
                            if (!c.readOnly &&
                                c.action == updatedConfig.action) {
                              return c.copyWith(
                                action: GestureAction.openTemplates,
                              );
                            }
                            return c;
                          }).toList();

                          _tempConfigs = newConfigs;
                          _hasChanges = true;
                        });
                      },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text(loc.gestureConfigurationLoadFailed('$error'))),
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.resetToDefaults),
        content: Text(loc.resetGesturesToDefaultsMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancelLabel),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await ref.read(gestureConfigProvider.notifier).resetToDefaults();
              if (!context.mounted) return;
              setState(() {
                _tempConfigs = null;
                _hasChanges = false;
              });
              Navigator.pop(context);
              messenger.showSnackBar(
                SnackBar(content: Text(loc.restoredDefaultSettings)),
              );
            },
            child: Text(loc.confirmLabel),
          ),
        ],
      ),
    );
  }
}

class GestureConfigCard extends StatelessWidget {
  final GestureConfig config;
  final List<GestureConfig> allConfigs;
  final Function(GestureConfig)? onUpdate;

  const GestureConfigCard({
    super.key,
    required this.config,
    required this.allConfigs,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getGestureIcon(config.gestureType),
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _gestureLabel(loc, config.gestureType),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getActionDescription(context, config.action),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                if (config.readOnly) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      loc.gestureShareOnly,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (!config.readOnly) ...[
              const SizedBox(height: 20),
              _ActionSelector(
                value: config.action,
                allConfigs: allConfigs,
                currentConfigId: config.id,
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

  IconData _getGestureIcon(GestureType type) {
    switch (type) {
      case GestureType.tap2:
        return Icons.touch_app;
      case GestureType.tap3:
        return Icons.touch_app_outlined;
    }
  }

  String _getActionDescription(BuildContext context, GestureAction action) {
    final loc = AppLocalizations.of(context)!;
    switch (action) {
      case GestureAction.openTemplates:
        return loc.gestureActionOpenTemplates;
      case GestureAction.saveSummary:
        return loc.gestureActionSaveSummary;
      case GestureAction.openSummaries:
        return loc.gestureActionOpenSavedContext;
    }
  }

  String _gestureLabel(AppLocalizations loc, GestureType type) {
    switch (type) {
      case GestureType.tap2:
        return loc.gestureDoubleTap;
      case GestureType.tap3:
        return loc.gestureTripleTap;
    }
  }
}

class _ActionSelector extends StatelessWidget {
  final GestureAction value;
  final List<GestureConfig> allConfigs;
  final int currentConfigId;
  final Function(GestureAction)? onChanged;

  const _ActionSelector({
    required this.value,
    required this.allConfigs,
    required this.currentConfigId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final usedActions = allConfigs
        .where((c) => !c.readOnly && c.id != currentConfigId)
        .map((c) => c.action)
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.triggerAction,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        RadioGroup<GestureAction>(
          groupValue: value,
          onChanged: onChanged != null
              ? (selected) {
                  if (selected != null) {
                    onChanged!(selected);
                  }
                }
              : (_) {},
          child: Column(
            children: [
              ...GestureAction.values.map((action) {
                final isUsed = usedActions.contains(action) && action != value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RadioListTile<GestureAction>(
                    value: action,
                    enabled: !isUsed && onChanged != null,
                    title: Text(
                      _getActionLabel(context, action),
                      style: TextStyle(
                        color: isUsed ? Colors.grey[400] : null,
                      ),
                    ),
                    subtitle: isUsed
                        ? Text(
                            loc.alreadyUsedByAnotherGesture,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          )
                        : null,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    tileColor: action == value
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                        : null,
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  String _getActionLabel(BuildContext context, GestureAction action) {
    final loc = AppLocalizations.of(context)!;
    switch (action) {
      case GestureAction.openTemplates:
        return loc.gestureActionOpenTemplates;
      case GestureAction.saveSummary:
        return loc.gestureActionSaveSummary;
      case GestureAction.openSummaries:
        return loc.gestureActionOpenSavedContext;
    }
  }
}
