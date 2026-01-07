import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  List<Deck> _allDecks = [];

  Future<void> _loadDecks() async {
    final d = await widget.repo.listApprovedDecks();
    if (mounted) setState(() => _allDecks = d);
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

    return _allDecks.where((d) {
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
          // Increased height so the search bar sits lower under the toolbar
          preferredSize: const Size.fromHeight(140),
          child: Padding(
            // Add extra top padding to push the search field further down
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
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

                const SizedBox(height: 6),

                // Filters row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Specialty',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        value: _specialty,
                        items: specialties
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => _specialty = v ?? 'All'),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: DropdownButtonFormField<String>(
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
      body: _allDecks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Builder(builder: (context) {
              final filtered = _applyFilters();
              if (filtered.isEmpty) {
                return const Center(child: Text('No decks match your filters'));
              }

              return DeckGrid(
                decks: filtered,
                // Open deck detail and pass initial index so the big slide loads at the selected preview
                onDeckTap: (deck, idx) => context.go('/deck/${deck.id}?i=$idx'),
              );
            }),
    );
  }
}
