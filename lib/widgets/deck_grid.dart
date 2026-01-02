import 'package:flutter/material.dart';
import '../data/models/deck.dart';
import 'deck_card.dart';

class DeckGrid extends StatelessWidget {
  final List<Deck> decks;
  final void Function(Deck deck) onDeckTap;

  const DeckGrid({super.key, required this.decks, required this.onDeckTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w >= 900 ? 4 : (w >= 600 ? 3 : 2);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: decks.length,
      itemBuilder: (context, i) => DeckCard(deck: decks[i], onTap: () => onDeckTap(decks[i])),
    );
  }
}
