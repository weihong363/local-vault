import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_vault/core/di/service_locator.dart';
import 'package:local_vault/core/domain/usecases/summary_usecases.dart';
import 'package:local_vault/core/memory_runtime/entities/memory_runtime_models.dart';
import 'package:local_vault/features/summary/presentation/widgets/empty_state.dart';
import 'package:local_vault/l10n/app_localizations.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<MemorySearchHit> _results = [];
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

    Future.delayed(const Duration(milliseconds: 300), () async {
      if (!mounted) return;

      final useCases = sl<SummaryUseCases>();
      final filtered = await useCases.searchMemory(query);

      if (!mounted) return;

      setState(() {
        _results = filtered;
        _isSearching = false;
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
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: loc.searchHint,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          onChanged: _handleSearch,
        ),
      ),
      body: _isSearching && _results.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? EmptyState(message: loc.noSearchResults)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final hit = _results[index];
                    final summary = hit.summary;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(
                          _titleForHit(hit),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _buildBadge(
                                  label: _sourceLabel(hit.source),
                                  color: _sourceColor(hit.source),
                                ),
                                _buildBadge(
                                  label: hit.reason,
                                  color: Colors.grey.shade200,
                                  foreground: Colors.black87,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _contentForHit(hit),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        onTap: summary == null
                            ? null
                            : () {
                                context.push('/summary-detail', extra: summary);
                              },
                      ),
                    );
                  },
                ),
    );
  }

  String _titleForHit(MemorySearchHit hit) {
    if (hit.summary != null) return hit.summary!.title;
    if (hit.state != null) return hit.state!.effectiveTopic;
    if (hit.memoryUnit != null) return hit.memoryUnit!.effectiveTopic;
    return hit.payloadRef;
  }

  String _contentForHit(MemorySearchHit hit) {
    if (hit.summary != null) return hit.summary!.content;
    if (hit.state != null) return hit.state!.summary;
    if (hit.memoryUnit != null) return hit.memoryUnit!.summary;
    return '';
  }

  String _sourceLabel(MemorySearchSource source) {
    return switch (source) {
      MemorySearchSource.state => 'state',
      MemorySearchSource.summary => 'summary',
      MemorySearchSource.chunk => 'chunk',
    };
  }

  Color _sourceColor(MemorySearchSource source) {
    return switch (source) {
      MemorySearchSource.state => Colors.blue.shade100,
      MemorySearchSource.summary => Colors.green.shade100,
      MemorySearchSource.chunk => Colors.orange.shade100,
    };
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    Color foreground = Colors.black,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
