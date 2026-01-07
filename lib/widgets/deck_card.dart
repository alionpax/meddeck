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
      onTap: () {
        // quick pulse on tap for microinteraction
        _controller.forward(from: 0);
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final glow = Tween<double>(begin: 0, end: 12).evaluate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
          final opacity = Tween<double>(begin: 0.0, end: 0.16).evaluate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

          // Medical theme uses a cleaner surface with a left accent stripe
          final isMedical = Theme.of(context).colorScheme.primary == const Color(0xFF6A00F4) ? false : true;

          return AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutBack,
            child: Stack(
              children: [
                // Glow overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(opacity),
                          blurRadius: glow,
                          spreadRadius: glow / 4,
                        ),
                      ],
                    ),
                  ),
                ),

                // Card surface
                Container(
                  decoration: BoxDecoration(
                    color: isMedical ? Theme.of(context).cardColor : null,
                    gradient: isMedical
                        ? null
                        : LinearGradient(
                            colors: [colors.primary, colors.secondary, colors.tertiary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(16),
                    border: isMedical ? Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.12)) : null,
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // IMAGE + HERO with left accent overlay for medical theme
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Hero(
                                tag: 'deck_${widget.deck.id}_cover',
                                child: Image.network(
                                  widget.deck.coverImageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image_not_supported),
                                  ),
                                ),
                              ),

                              if (isMedical)
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 8,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),

                              // slide count badge
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.16),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.slideshow, size: 14, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(widget.deck.slideCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Title
                      Text(
                        widget.deck.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: isMedical ? Theme.of(context).colorScheme.onSurface : Colors.white),
                      ),

                      const SizedBox(height: 8),

                      // Specialty chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isMedical ? Theme.of(context).colorScheme.secondary.withOpacity(0.10) : Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.deck.specialty,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isMedical ? Theme.of(context).colorScheme.secondary : Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
