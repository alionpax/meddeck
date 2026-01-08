import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../data/repo/deck_repo.dart';
import '../../data/models/deck.dart';
import '../../widgets/deck_card.dart';

class OfflineScreen extends StatelessWidget {
  final DeckRepo repo;
  const OfflineScreen({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('offline');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Downloads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About Offline',
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box boxData, _) {
          final savedDeckIds = <String>[];
          for (final key in boxData.keys) {
            if (key.toString().startsWith('deck_')) {
              savedDeckIds.add(key.toString().replaceFirst('deck_', ''));
            }
          }

          if (savedDeckIds.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: savedDeckIds.length,
            itemBuilder: (context, idx) {
              final deckId = savedDeckIds[idx];
              final deckData = boxData.get('deck_$deckId') as Map?;

              if (deckData == null) return const SizedBox.shrink();

              final deck = Deck.fromMap(Map<String, dynamic>.from(deckData));

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: deck.coverImageUrl != null
                        ? Image.network(
                            deck.coverImageUrl!,
                            width: 80,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 80,
                              height: 60,
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              child: const Icon(Icons.broken_image),
                            ),
                          )
                        : Container(
                            width: 80,
                            height: 60,
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: const Icon(Icons.slideshow),
                          ),
                  ),
                  title: Text(
                    deck.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.collections, size: 14, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text('${deck.slideCount} slides'),
                        const SizedBox(width: 12),
                        Icon(Icons.category_outlined, size: 14, color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 4),
                        Text(deck.specialty),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove from offline',
                    onPressed: () => _confirmDelete(context, box, deckId, deck.title),
                  ),
                  onTap: () => context.go('/deck/$deckId'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 120,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No offline decks',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Download decks from the Library to access them offline',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.grid_view),
              label: const Text('Browse Library'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download_outlined),
            SizedBox(width: 12),
            Text('Offline Downloads'),
          ],
        ),
        content: const Text(
          'Decks you download will be saved here for offline access.\n\n'
          'To download a deck:\n'
          '1. Open any deck from the Library\n'
          '2. Tap the download icon\n'
          '3. Access it here anytime, even without internet',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Box box, String deckId, String deckTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from offline?'),
        content: Text('This will delete "$deckTitle" from your device. You can download it again later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              box.delete('deck_$deckId');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Removed from offline downloads')),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
