import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../data/models/deck.dart';
import 'deck_card.dart';

/// Custom scroll physics for buttery smooth scrolling
class SmoothScrollPhysics extends BouncingScrollPhysics {
  const SmoothScrollPhysics({super.parent});

  @override
  SmoothScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SmoothScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 80,
    stiffness: 100,
    damping: 20,
  );

  @override
  double get minFlingVelocity => 50.0;

  @override
  double get maxFlingVelocity => 8000.0;

  @override
  double get dragStartDistanceMotionThreshold => 3.5;
}

class DeckGrid extends StatelessWidget {
  final List<Deck> decks;
  final void Function(Deck deck, int initialIndex) onDeckTap;

  const DeckGrid({super.key, required this.decks, required this.onDeckTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const SmoothScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: decks.length,
      itemBuilder: (context, i) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 420 + (i % 6) * 50),
        curve: Curves.easeOutCubic,
        builder: (context, val, child) => Transform.scale(
          scale: 0.85 + (val * 0.15),
          child: Opacity(
            opacity: val,
            child: Transform.translate(
              offset: Offset(0, (1 - val) * 20),
              child: child,
            ),
          ),
        ),
        child: DeckCard(deck: decks[i], onTap: (idx) => onDeckTap(decks[i], idx)),
      ),
    );
  }
}
