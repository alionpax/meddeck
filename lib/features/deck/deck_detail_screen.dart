import 'dart:async';

import 'package:flutter/material.dart';
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
    setState(() {
      _selectedIndex = (_selectedIndex + 1);
    });
  }

  void _prevSlide() {
    setState(() {
      if (_selectedIndex > 0) _selectedIndex = (_selectedIndex - 1);
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _autoplayTimer?.cancel();
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Big slide area (changes when mini slides are tapped/swiped)
                        GestureDetector(
                          onTap: () {
                            // Enter presentation (pan) mode
                            setState(() => _inPresentation = true);
                          },
                          onHorizontalDragEnd: (details) {
                            final vx = details.primaryVelocity ?? 0;
                            if (vx < -300) {
                              // swipe left -> next
                              if (_selectedIndex < urls.length - 1) _nextSlide();
                            } else if (vx > 300) {
                              if (_selectedIndex > 0) _prevSlide();
                            }
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // When in presentation mode allow pan/zoom via InteractiveViewer
                              if (_inPresentation)
                                InteractiveViewer(
                                  minScale: 1,
                                  maxScale: 4,
                                  child: Hero(tag: 'deck_${deck.id}_slide_$_selectedIndex', child: SafeNetworkImage(url: currentUrl, fit: BoxFit.contain)),
                                )
                              else
                                Hero(tag: 'deck_${deck.id}_cover', child: SafeNetworkImage(url: currentUrl, fit: BoxFit.contain)),

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
                  onPressed: () => setState(() => _inPresentation = true),
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

              // Mini thumbnails: clicking/swiping updates big slide
              SlideThumbnailStrip(
                urls: urls.take(24).toList(),
                onTap: (i) => setState(() => _selectedIndex = i),
                onIndexChanged: (i) => setState(() => _selectedIndex = i),
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
