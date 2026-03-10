import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/features/summary/domain/providers/summary_provider.dart';
import 'package:local_vault/features/summary/presentation/widgets/empty_state.dart';
import 'package:local_vault/features/summary/presentation/widgets/summary_card.dart';
import 'package:local_vault/features/summary/models/summary.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    final notifier = ref.read(summaryNotifierProvider.notifier);
    
    if (query.isEmpty) {
      notifier.refresh();
      return;
    }

    notifier.searchSummaries(query);
  }

  /// 显示确认删除对话框
  Future<void> _showDeleteConfirmationDialog(BuildContext context, Summary summary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${summary.title}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(summaryNotifierProvider.notifier).deleteSummary(summary.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已删除'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除失败：$e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 处理拖拽排序完成
  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    final currentState = ref.read(summaryNotifierProvider);
    if (currentState is! AsyncData<List<Summary>>) return;

    final summaries = List<Summary>.from(currentState.value);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final item = summaries.removeAt(oldIndex);
    summaries.insert(newIndex, item);
    
    await ref.read(summaryNotifierProvider.notifier).updateSortOrders(summaries);
  }

  @override
  Widget build(BuildContext context) {
    final asyncSummaries = ref.watch(summaryNotifierProvider);

    ref.listen(summaryNotifierProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('错误: ${next.error}')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('本地记忆库'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索标题、内容或标签...',
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
          if (summaries.isEmpty) {
            return const EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async {
              _searchController.clear();
              _handleSearch('');
              await ref.read(summaryNotifierProvider.notifier).refresh();
            },
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: summaries.length,
              onReorder: (oldIndex, newIndex) => _handleReorder(oldIndex, newIndex),
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
                  onDelete: () => _showDeleteConfirmationDialog(context, summary),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('错误: $error')),
      ),
    );
  }
}

class _BuildReorderableItem extends StatefulWidget {
  final Summary summary;
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
  bool _isDragging = false;

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
                ),
              ),
              Positioned(
                top: -8,
                left: -8,
                child: GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 18,
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
