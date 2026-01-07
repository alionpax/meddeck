import 'package:flutter/material.dart';
import '../data/models/deck.dart';

class DeckCard extends StatefulWidget {
  final Deck deck;
  final VoidCallback onTap;

  const DeckCard({
    super.key,
    required this.deck,
    required this.onTap,
  });

  @override
  State<DeckCard> createState() => _DeckCardState();
}

class _DeckCardState extends State<DeckCard> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    setState(() => _pressed = true);
    _controller.forward();
  }

  void _onTapUp(_) {
    setState(() => _pressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapCancel: () => _onTapUp(null),
      onTapUp: _onTapUp,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, colors.secondary, colors.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE + HERO
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Hero(
                    tag: 'deck_${widget.deck.id}_cover',
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.deck.coverImageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.black.withOpacity(0.04),
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                        // Overlay gradient for contrast
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black.withOpacity(0.25)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Title
              Text(
                widget.deck.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),

              const SizedBox(height: 8),

              // Specialty chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.deck.specialty,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
