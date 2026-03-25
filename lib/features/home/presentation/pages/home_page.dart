import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/core/domain/entities/summary_entity.dart';
import 'package:local_vault/core/providers/summary_entities_provider.dart';
import 'package:local_vault/features/summary/presentation/widgets/empty_state.dart';
import 'package:local_vault/features/summary/presentation/widgets/summary_card.dart';
import 'package:local_vault/l10n/app_localizations.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('🏠 [HomePage] Initialized');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('🏠 [HomePage] App resumed, refreshing data');
      _refreshData();
    }
  }

  void _refreshData() {
    _searchController.clear();
    ref.read(summaryEntityNotifierProvider.notifier).refresh();
  }

  void _handleSearch(String query) {
    final notifier = ref.read(summaryEntityNotifierProvider.notifier);

    if (query.isEmpty) {
      notifier.refresh();
      return;
    }

    notifier.searchSummaries(query);
  }

  /// Show a confirmation dialog before deleting a summary.
  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, SummaryEntity summary) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteSummary),
        content: Text(loc.deleteSummaryConfirm(summary.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(loc.deleteLabel),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(summaryEntityNotifierProvider.notifier)
          .deleteSummary(summary.id);
      final deleteState = ref.read(summaryEntityNotifierProvider);
      if (deleteState.hasError || !context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.deletedLabel),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Persist the new order after drag-and-drop sorting.
  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    final currentState = ref.read(summaryEntityNotifierProvider);
    if (currentState is! AsyncData<List<SummaryEntity>>) return;

    final summaries = List<SummaryEntity>.from(currentState.value);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = summaries.removeAt(oldIndex);
    summaries.insert(newIndex, item);

    await ref
        .read(summaryEntityNotifierProvider.notifier)
        .updateSortOrders(summaries);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final asyncSummaries = ref.watch(summaryEntityNotifierProvider);

    ref.listen(summaryEntityNotifierProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorWithDetails('${next.error}'))),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.appTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: loc.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _handleSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
              onChanged: _handleSearch,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push(AppRoutes.save);
            },
          ),
        ],
      ),
      body: asyncSummaries.when(
        data: (summaries) {
          debugPrint('🏠 [HomePage] Rendering ${summaries.length} summaries');
          if (summaries.isEmpty) {
            return const EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async {
              _searchController.clear();
              _handleSearch('');
              await ref.read(summaryEntityNotifierProvider.notifier).refresh();
            },
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: summaries.length,
              onReorder: (oldIndex, newIndex) =>
                  _handleReorder(oldIndex, newIndex),
              buildDefaultDragHandles: false,
              itemBuilder: (context, index) {
                final summary = summaries[index];
                return _BuildReorderableItem(
                  key: Key(summary.id),
                  summary: summary,
                  index: index,
                  onTap: () {
                    context.push(
                      AppRoutes.summaryDetail,
                      extra: summary,
                    );
                  },
                  onDelete: () =>
                      _showDeleteConfirmationDialog(context, summary),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          debugPrint('❌ [HomePage] Rendering error state: $error');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.loadFailedLabel,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.errorWithDetails('$error'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(summaryEntityNotifierProvider.notifier)
                          .refresh();
                    },
                    child: Text(loc.retryLabel),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BuildReorderableItem extends StatefulWidget {
  final SummaryEntity summary;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BuildReorderableItem({
    super.key,
    required this.summary,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_BuildReorderableItem> createState() => _BuildReorderableItemState();
}

class _BuildReorderableItemState extends State<_BuildReorderableItem>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _elevationController;
  late Animation<double> _elevationAnimation;
  bool _isLongPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));

    _elevationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _elevationAnimation = Tween<double>(
      begin: 1.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _elevationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _elevationController.dispose();
    super.dispose();
  }

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLongPressed = true;
    });
    _scaleController.forward();
    _elevationController.forward();
  }

  void _handleLongPressEnd() {
    setState(() {
      _isLongPressed = false;
    });
    _scaleController.reverse();
    _elevationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cardContent = AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _elevationController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Card(
                margin: EdgeInsets.zero,
                elevation: _elevationAnimation.value,
                child: SummaryCard(
                  summary: widget.summary,
                  onTap: () {
                    if (!_isLongPressed) {
                      widget.onTap();
                    }
                  },
                  index: widget.index,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onLongPress: _handleLongPress,
        onLongPressUp: _handleLongPressEnd,
        child: _isLongPressed
            ? ReorderableDragStartListener(
                index: widget.index,
                child: cardContent,
              )
            : cardContent,
      ),
    );
  }
}
