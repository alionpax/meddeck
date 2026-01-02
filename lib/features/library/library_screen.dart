import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repo/deck_repo.dart';
import '../../data/repo/firestore_deck_repo.dart';
import '../../widgets/deck_grid.dart';

class LibraryScreen extends StatelessWidget {
  final DeckRepo repo; // keep for existing navigation
  final bool isAdmin;

  const LibraryScreen({
    super.key,
    required this.repo,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreDeckRepo();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          if (isAdmin)
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
      ),
      body: FutureBuilder(
        future: fs.listApprovedDecks(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load library.\n${snap.error}'),
              ),
            );
          }

          final decks = snap.data ?? const [];
          if (decks.isEmpty) {
            return const Center(child: Text('No approved decks yet.'));
          }

          return DeckGrid(
            decks: decks,
            onDeckTap: (deck) => context.go('/deck/${deck.id}'),
          );
        },
      ),
    );
  }
}
