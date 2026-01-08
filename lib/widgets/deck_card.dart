import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/deck.dart';
import 'package:meddeck/widgets/safe_network_image.dart';

class DeckCard extends StatefulWidget {
  final Deck deck;
  final void Function(int initialIndex) onTap;

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
  bool _isDragging = false;
  int _previewIndex = 0;
  late final AnimationController _controller;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _pageController = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
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

  void _onLongPress() {
    // Extra haptic feedback on long press
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => setState(() => _pressed = false),
      onLongPress: _onLongPress,
      // Tapping (when not dragging the PageView) opens the deck detail at the current preview index
      onTap: () {
        HapticFeedback.lightImpact();
        if (!_isDragging) widget.onTap(_previewIndex);
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final glow = Tween<double>(begin: 0, end: 12).evaluate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
          final opacity = Tween<double>(begin: 0.0, end: 0.16).evaluate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

          // Medical theme uses a cleaner surface with a left accent stripe
          final isMedical = Theme.of(context).colorScheme.primary == const Color(0xFF6A00F4) ? false : true;

          final scale = _pressed ? 0.94 : 1.0;
          
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: scale, end: scale),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            builder: (context, scaleVal, child) => Transform.scale(
              scale: scaleVal,
              child: child,
            ),
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
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // PageView for preview thumbnails (falls back to cover image)
                                      NotificationListener<ScrollNotification>(
                                        onNotification: (n) {
                                          if (n is ScrollStartNotification) setState(() => _isDragging = true);
                                          if (n is ScrollEndNotification) setState(() => _isDragging = false);
                                          return false;
                                        },
                                        child: PageView.builder(
                                          controller: _pageController,
                                          itemCount: (widget.deck.slides.isNotEmpty)
                                              ? widget.deck.slides.length
                                              : (widget.deck.slideImageUrls.isNotEmpty ? widget.deck.slideImageUrls.length : 1),
                                          onPageChanged: (i) => setState(() => _previewIndex = i),
                                          itemBuilder: (context, i) {
                                            final url = (widget.deck.slides.isNotEmpty)
                                                ? widget.deck.slides[i]
                                                : (widget.deck.slideImageUrls.isNotEmpty ? widget.deck.slideImageUrls[i] : widget.deck.coverImageUrl);
                                            return Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                // Image only — tapping the card opens detail; use explicit play button for quick preview
                                                SafeNetworkImage(
                                                  url: url,
                                                  fit: BoxFit.cover,
                                                ),


                                              ],
                                            );
                                          },
                                        ),
                                      ),

                                      // Page indicator
                                      if ((widget.deck.slides.isNotEmpty && widget.deck.slides.length > 1) || (widget.deck.slideImageUrls.isNotEmpty && widget.deck.slideImageUrls.length > 1))
                                        Positioned(
                                          bottom: 8,
                                          left: 0,
                                          right: 0,
                                          child: Center(
                                            child: SizedBox(
                                              height: 6,
                                              child: SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                physics: const BouncingScrollPhysics(),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: List.generate(
                                                    widget.deck.slides.isNotEmpty ? widget.deck.slides.length : widget.deck.slideImageUrls.length,
                                                    (i) => Container(
                                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                                      width: _previewIndex == i ? 10 : 6,
                                                      height: 6,
                                                      decoration: BoxDecoration(
                                                        color: _previewIndex == i ? Theme.of(context).colorScheme.primary : Colors.white.withOpacity(0.6),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                      // Favorite button
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: ValueListenableBuilder(
                                          valueListenable: Hive.box('offline').listenable(),
                                          builder: (context, Box box, _) {
                                            final favorites = box.get('favorites', defaultValue: <String>[]) as List;
                                            final isFavorite = favorites.contains(widget.deck.id);

                                            return Material(
                                              color: Colors.black.withOpacity(0.5),
                                              borderRadius: BorderRadius.circular(20),
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(20),
                                                onTap: () {
                                                  final updatedFavorites = List<String>.from(favorites);
                                                  if (isFavorite) {
                                                    updatedFavorites.remove(widget.deck.id);
                                                  } else {
                                                    updatedFavorites.add(widget.deck.id);
                                                  }
                                                  box.put('favorites', updatedFavorites);
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.all(8),
                                                  child: Icon(
                                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                                    color: isFavorite ? Colors.red : Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
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
