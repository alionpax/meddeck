import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../data/models/deck.dart';

class DeckCard extends StatelessWidget {
  final Deck deck;
  final VoidCallback onTap;

  const DeckCard({super.key, required this.deck, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: deck.coverImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (c, _) => Container(color: Theme.of(context).dividerColor.withOpacity(0.4)),
                  errorWidget: (c, _, __) => Container(color: Theme.of(context).dividerColor.withOpacity(0.4)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(deck.title, style: t.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('${deck.specialty} â€¢ ${deck.slideCount} slides', style: t.bodySmall),
          ],
        ),
      ),
    );
  }
}
