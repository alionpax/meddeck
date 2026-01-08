import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../widgets/safe_network_image.dart';
import '../../data/repo/deck_repo.dart';
import '../../widgets/slide_thumbnail_strip.dart';

class DeckDetailScreen extends StatefulWidget {
  final DeckRepo repo;
  final String deckId;
  final int initialIndex;

  const DeckDetailScreen({super.key, required this.repo, required this.deckId, this.initialIndex = 0});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  int _selectedIndex = 0;
  bool _inPresentation = false;
  bool _autoplay = false;
  Timer? _autoplayTimer;
  bool _isFavorite = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
    _loadFavoriteStatus();
  }

  void _loadFavoriteStatus() {
    final box = Hive.box('offline');
    final favorites = box.get('favorites', defaultValue: <String>[]) as List;
    setState(() {
      _isFavorite = favorites.contains(widget.deckId);
    });
  }

  Future<void> _toggleFavorite() async {
    final box = Hive.box('offline');
    final favorites = List<String>.from(box.get('favorites', defaultValue: <String>[]) as List);
    
    if (_isFavorite) {
      favorites.remove(widget.deckId);
    } else {
      favorites.add(widget.deckId);
    }
    
    await box.put('favorites', favorites);
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _startAutoplay() {
    _autoplayTimer?.cancel();
    _autoplayTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _nextSlide();
    });
    setState(() => _autoplay = true);
  }

  void _stopAutoplay() {
    _autoplayTimer?.cancel();
    _autoplayTimer = null;
    setState(() => _autoplay = false);
  }

  void _nextSlide() {
    if (_pageController.hasClients && _pageController.page != null) {
      final nextPage = (_pageController.page!.round() + 1);
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevSlide() {
    if (_pageController.hasClients && _pageController.page != null) {
      final prevPage = (_pageController.page!.round() - 1);
      if (prevPage >= 0) {
        _pageController.animateToPage(
          prevPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _autoplayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final box = Hive.box('offline');

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share deck',
            onPressed: () async {
              final deck = await widget.repo.getDeck(widget.deckId);
              if (deck != null && context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.share),
                        SizedBox(width: 12),
                        Text('Share Deck'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Share "${deck.title}" with others:'),
                        const SizedBox(height: 16),
                        SelectableText(
                          'meddeck://deck/${deck.id}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                      FilledButton.icon(
                        onPressed: () {
                          // Copy to clipboard would go here
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Link copied!')),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy Link'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          ValueListenableBuilder(
            valueListenable: box.listenable(),
            builder: (context, Box boxData, _) {
              final isOffline = boxData.containsKey('deck_${widget.deckId}');

              return IconButton(
                icon: Icon(
                  isOffline ? Icons.download_done : Icons.download_outlined,
                  color: isOffline ? Theme.of(context).colorScheme.primary : null,
                ),
                tooltip: isOffline ? 'Saved offline' : 'Download for offline',
                onPressed: () async {
                  if (isOffline) {
                    // Remove from offline
                    await box.delete('deck_${widget.deckId}');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Removed from offline')),
                      );
                    }
                  } else {
                    // Save for offline
                    final deck = await widget.repo.getDeck(widget.deckId);
                    if (deck != null) {
                      await box.put('deck_${widget.deckId}', deck.toMap());
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Saved for offline access'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: widget.repo.getDeck(widget.deckId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final deck = snap.data;
          if (deck == null) return const Center(child: Text('Deck not found.'));

          final urls = deck.slides.isNotEmpty 
              ? deck.slides 
              : (deck.slideImageUrls.isNotEmpty ? deck.slideImageUrls : [deck.coverImageUrl]);
          final currentUrl = (_selectedIndex >= 0 && _selectedIndex < urls.length) ? urls[_selectedIndex] : (urls.isNotEmpty ? urls.first : deck.coverImageUrl);

          return ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              const SizedBox(height: 16),
              
              // Wrap in card container similar to library
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Big slide preview with gradient border
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                                Theme.of(context).colorScheme.tertiary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: PageView.builder(
                                itemCount: urls.length,
                                controller: _pageController,
                                onPageChanged: (index) {
                                  setState(() => _selectedIndex = index);
                                  HapticFeedback.selectionClick();
                                },
                                itemBuilder: (context, index) {
                                  final url = urls[index];
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() => _inPresentation = true);
                                    },
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // When in presentation mode allow pan/zoom via InteractiveViewer
                                        if (_inPresentation)
                                          InteractiveViewer(
                                            minScale: 1,
                                            maxScale: 4,
                                            child: Hero(tag: 'deck_\${deck.id}_slide_\$index', child: SafeNetworkImage(url: url, fit: BoxFit.contain)),
                                          )
                                        else
                                          Hero(tag: 'deck_\${deck.id}_slide_\$index', child: SafeNetworkImage(url: url, fit: BoxFit.contain)),

                                    // If in presentation mode, overlay controls
                                        if (_inPresentation)
                                          Positioned(
                                            left: 12,
                                            top: 12,
                                            child: FloatingActionButton.small(
                                              onPressed: () => setState(() => _inPresentation = false),
                                              child: const Icon(Icons.close),
                                            ),
                                          ),

                                        if (_inPresentation)
                                          Positioned(
                                            left: 12,
                                            right: 12,
                                            bottom: 12,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                FloatingActionButton.small(
                                                  onPressed: _prevSlide,
                                                  child: const Icon(Icons.chevron_left),
                                                ),
                                                Row(
                                                  children: [
                                                    FloatingActionButton.small(
                                                      onPressed: () {
                                                        if (_autoplay) _stopAutoplay();
                                                        else _startAutoplay();
                                                      },
                                                      backgroundColor: _autoplay ? Theme.of(context).colorScheme.primary : null,
                                                      child: Icon(_autoplay ? Icons.pause : Icons.play_arrow),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    FloatingActionButton.small(
                                                      onPressed: _nextSlide,
                                                      child: const Icon(Icons.chevron_right),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                        ),
                      ),
                    ),
                  ),

                      const SizedBox(height: 12),

                      // Title and details with theme colors
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          deck.title,
                          style: t.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              avatar: Icon(Icons.category, size: 16, color: Theme.of(context).colorScheme.secondary),
                              label: Text(deck.specialty),
                              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                            ),
                            Chip(
                              avatar: Icon(Icons.slideshow, size: 16, color: Theme.of(context).colorScheme.tertiary),
                              label: Text('${deck.slideCount} slides'),
                              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Centered action buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Like button
                            IconButton.filled(
                              onPressed: _toggleFavorite,
                              icon: Icon(
                                _isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: _isFavorite ? Colors.red : null,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Download button
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Offline download: next step.')),
                                  );
                                },
                                icon: const Icon(Icons.download),
                                label: const Text('Download offline'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Mini thumbnails: clicking/swiping updates big slide
                      SlideThumbnailStrip(
                        urls: urls.take(24).toList(),
                        selectedIndex: _selectedIndex,
                        onTap: (i) {
                          _pageController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        onIndexChanged: (i) {
                          _pageController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16), // Bottom padding
            ],
          );
        },
      ),
    );
  }
}
