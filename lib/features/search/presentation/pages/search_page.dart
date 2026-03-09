import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_vault/core/constants/app_routes.dart';
import 'package:local_vault/features/summary/models/summary.dart';
import 'package:local_vault/features/summary/presentation/widgets/summary_card.dart';
import 'package:local_vault/features/summary/presentation/widgets/empty_state.dart';
import 'package:local_vault/features/summary/domain/providers/summary_provider.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Summary> _results = [];
  bool _isSearching = false;

  void _handleSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      final repository = ref.read(summaryRepositoryProvider);
      final filtered = repository.searchSummaries(query);
      
      setState(() {
        _results = filtered;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '搜索标题、内容或标签...',
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          onChanged: _handleSearch,
        ),
      ),
      body: _isSearching && _results.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? const EmptyState(message: '暂无搜索结果')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    return SummaryCard(
                      summary: _results[index],
                      onTap: () {
                        context.push(
                          AppRoutes.summaryDetail,
                          extra: _results[index],
                        );
                      },
                    );
                  },
                ),
    );
  }
}
