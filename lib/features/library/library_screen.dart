import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repo/deck_repo.dart';
import '../../widgets/deck_grid.dart';

class LibraryScreen extends StatelessWidget {
  final DeckRepo repo;
  const LibraryScreen({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: FutureBuilder(
        future: repo.listApprovedDecks(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final decks = snap.data!;
          if (decks.isEmpty) {
            return const Center(child: Text('No decks available.'));
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
