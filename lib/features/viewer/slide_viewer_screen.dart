import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../data/repo/deck_repo.dart';

class SlideViewerScreen extends StatefulWidget {
  final DeckRepo repo;
  final String deckId;
  final int initialIndex;

  const SlideViewerScreen({
    super.key,
    required this.repo,
    required this.deckId,
    required this.initialIndex,
  });

  @override
  State<SlideViewerScreen> createState() => _SlideViewerScreenState();
}

class _SlideViewerScreenState extends State<SlideViewerScreen> {
  late final PageController _controller;
  bool _uiVisible = true;
  int _page = 0;

  final Map<String, Future<String>> _urlFutures = {};

  @override
  void initState() {
    super.initState();
    _page = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);

    // Listen to page controller for continuous parallax and progress updates
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _toggleUi() => setState(() => _uiVisible = !_uiVisible);

  Future<String> _resolveToUrl(String maybeUrlOrStoragePath) {
    final s = maybeUrlOrStoragePath.trim();
    if (s.startsWith('http://') || s.startsWith('https://')) {
      return Future.value(s);
    }
    return FirebaseStorage.instance.ref(s).getDownloadURL();
  }

  Future<String> _getUrlCached(String key) {
    return _urlFutures.putIfAbsent(key, () => _resolveToUrl(key));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.repo.getDeck(widget.deckId),
      builder: (context, snap) {
        // Loading
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Error
        if (snap.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF0B0B0B),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error loading deck:\n\n${snap.error}',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        // Not found
        final deck = snap.data;
        if (deck == null) {
          return const Scaffold(
            body: Center(child: Text('Deck not found.')),
          );
        }

        // URL-first, fallback to storage paths if needed
        final List<String> slideRefs =
            deck.slideImageUrls.isNotEmpty ? deck.slideImageUrls : deck.slides;

        if (slideRefs.isEmpty) {
          return const Scaffold(
            backgroundColor: Color(0xFF0B0B0B),
            body: Center(
              child: Text(
                'Slides are not ready yet.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        return Scaffold(
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).colorScheme.primary.withOpacity(0.06), Theme.of(context).colorScheme.surface],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                // moving background glow (parallax)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Builder(builder: (context) {
                      final page = _controller.hasClients ? (_controller.page ?? _controller.initialPage.toDouble()) : _page.toDouble();
                      final norm = slideRefs.length > 1 ? (page / (slideRefs.length - 1)).clamp(0.0, 1.0) : 0.5;

                      return Transform.translate(
                        offset: Offset((norm - 0.5) * 120, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                Theme.of(context).colorScheme.secondary.withOpacity(0.04),
                                Colors.transparent,
                              ],
                              radius: 0.8,
                              center: Alignment.center,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // PageView with parallax + interactive zoom
                GestureDetector(
                  onTap: _toggleUi,
                  child: PageView.builder(
                    controller: _controller,
                    physics: const BouncingScrollPhysics(),
                    itemCount: slideRefs.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, index) {
                      final ref = slideRefs[index];

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          // compute parallax offset from PageController.page
                          double pageOffset = 0;
                          try {
                            pageOffset = (_controller.page ?? _controller.initialPage.toDouble()) - index;
                          } catch (_) {}

                          final parallax = pageOffset * constraints.maxWidth * 0.15;

                          return InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            child: Center(
                              child: FutureBuilder<String>(
                                future: _getUrlCached(ref),
                                builder: (context, urlSnap) {
                                  if (urlSnap.connectionState != ConnectionState.done) {
                                    return const CircularProgressIndicator();
                                  }

                                  if (urlSnap.hasError) {
                                    return Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        'Failed to resolve slide ${index + 1}\n\n${urlSnap.error}',
                                        style: const TextStyle(color: Colors.white70),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }

                                  return FractionalTranslation(
                                    translation: Offset(parallax / constraints.maxWidth, 0),
                                    child: Hero(
                                      tag: 'deck_${deck.id}_cover',
                                      child: CachedNetworkImage(
                                        imageUrl: urlSnap.data!,
                                        fit: BoxFit.contain,
                                        placeholder: (c, _) => const CircularProgressIndicator(),
                                        errorWidget: (c, err, __) => Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Text(
                                            'Image request failed:\n$err',
                                            style: const TextStyle(color: Colors.white70),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Top UI
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  top: _uiVisible ? 0 : -80,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          const Spacer(),
                          Text(
                            '${_page + 1} / ${slideRefs.length}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom progress indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  bottom: _uiVisible ? 16 : -48,
                  left: 16,
                  right: 16,
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress bar
                        _buildProgressBar(slideRefs.length),
                        const SizedBox(height: 8),
                        // Page dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(slideRefs.length, (i) {
                            final selected = i == _page;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 280),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: selected ? 18 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: selected ? Theme.of(context).colorScheme.primary : Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(int total) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final page = _controller.hasClients ? (_controller.page ?? _controller.initialPage.toDouble()) : _page.toDouble();
        final progress = ((page + 1) / total).clamp(0.0, 1.0);
        return Container(
          width: double.infinity,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        );
      },
    );
  }
}
