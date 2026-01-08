import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/repo/deck_repo.dart';
import '../../data/models/deck.dart';
import '../../widgets/deck_grid.dart';

class LibraryScreen extends StatefulWidget {
  final DeckRepo repo;
  final bool isAdmin;

  const LibraryScreen({
    super.key,
    required this.repo,
    required this.isAdmin,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _specialty = 'All';
  String _dateRange = 'Any';
  bool _showFavoritesOnly = false;

  List<Deck> _allDecks = [];
  bool _isLoading = true;
  String? _errorMessage;

  Future<void> _loadDecks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final d = await widget.repo.listApprovedDecks();
      if (mounted) {
        setState(() {
          _allDecks = d;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDecks();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Deck> _applyFilters() {
    final q = _searchController.text.toLowerCase().trim();
    final now = DateTime.now();
    final box = Hive.box('offline');
    final favorites = box.get('favorites', defaultValue: <String>[]) as List;

    return _allDecks.where((d) {
      // Favorites filter
      if (_showFavoritesOnly && !favorites.contains(d.id)) {
        return false;
      }

      // Search query
      if (q.isNotEmpty) {
        final match = d.title.toLowerCase().contains(q) || d.specialty.toLowerCase().contains(q);
        if (!match) return false;
      }

      // Specialty
      if (_specialty != 'All' && d.specialty != _specialty) {
        return false;
      }

      // Date range
      if (_dateRange == '24h') {
        if (d.uploadedAt.isBefore(now.subtract(const Duration(hours: 24)))) return false;
      } else if (_dateRange == '7d') {
        if (d.uploadedAt.isBefore(now.subtract(const Duration(days: 7)))) return false;
      } else if (_dateRange == '30d') {
        if (d.uploadedAt.isBefore(now.subtract(const Duration(days: 30)))) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final specialties = <String>{'All', ..._allDecks.map((d) => d.specialty)}.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.95)),
        actions: [
          if (widget.isAdmin)
            IconButton(
              tooltip: 'Review',
              onPressed: () => context.push('/review'),
              icon: const Icon(Icons.fact_check_outlined),
            ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
        bottom: PreferredSize(
          // Adjusted height for filters
          preferredSize: const Size.fromHeight(200),
          child: Padding(
            // Add extra top padding to push the search field further down
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Search field (more compact)
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by title or specialty',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                    prefixIcon: const Icon(Icons.search_outlined),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Favorites chip
                ValueListenableBuilder(
                  valueListenable: Hive.box('offline').listenable(),
                  builder: (context, Box box, _) {
                    final favorites = box.get('favorites', defaultValue: <String>[]) as List;
                    return Row(
                      children: [
                        FilterChip(
                          avatar: Icon(
                            _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                          ),
                          label: Text('Favorites (${favorites.length})'),
                          selected: _showFavoritesOnly,
                          onSelected: (bool value) {
                            setState(() => _showFavoritesOnly = value);
                          },
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Filters row (side-by-side)
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Specialty',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        value: _specialty,
                        items: specialties
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _specialty = v ?? 'All'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Upload date',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        value: _dateRange,
                        items: const [
                          DropdownMenuItem(value: 'Any', child: Text('Any')),
                          DropdownMenuItem(value: '24h', child: Text('Last 24h')),
                          DropdownMenuItem(value: '7d', child: Text('Last 7 days')),
                          DropdownMenuItem(value: '30d', child: Text('Last 30 days')),
                        ],
                        onChanged: (v) => setState(() => _dateRange = v ?? 'Any'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_allDecks.isEmpty) {
      return _buildEmptyLibrary();
    }

    final filtered = _applyFilters();
    if (filtered.isEmpty) {
      return _buildNoResults();
    }

    return DeckGrid(
      decks: filtered,
      onDeckTap: (deck, idx) => context.go('/deck/${deck.id}?i=$idx'),
    );
  }

  Widget _buildLoadingSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load library',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _loadDecks,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLibrary() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              size: 120,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No decks yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Upload your first PowerPoint to get started',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/uploads'),
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Deck'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No matches found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your filters or search query',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _specialty = 'All';
                  _dateRange = 'Any';
                  _showFavoritesOnly = false;
                });
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }
}

