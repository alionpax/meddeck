import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/repo/deck_repo.dart';
import '../../widgets/slide_thumbnail_strip.dart';

class DeckDetailScreen extends StatelessWidget {
  final DeckRepo repo;
  final String deckId;

  const DeckDetailScreen({super.key, required this.repo, required this.deckId});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(
        future: repo.getDeck(deckId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final deck = snap.data;
          if (deck == null) return const Center(child: Text('Deck not found.'));

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(tag: 'deck_${deck.id}_cover', child: CachedNetworkImage(imageUrl: deck.coverImageUrl, fit: BoxFit.cover)),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black.withOpacity(0.24)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(12),
                            child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(deck.title, style: t.titleLarge),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${deck.specialty}\n${deck.slideCount} slides\nSource: ${deck.source}',
                  style: t.bodySmall,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton(
                  onPressed: () => context.go('/viewer/${deck.id}?i=0'),
                  child: const Text('Preview slides'),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Offline download: next step.')),
                    );
                  },
                  child: const Text('Download offline'),
                ),
              ),
              const SizedBox(height: 16),
              SlideThumbnailStrip(
                urls: deck.slideImageUrls.take(24).toList(),
                onTap: (i) => context.go('/viewer/${deck.id}?i=$i'),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
