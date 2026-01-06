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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleUi() => setState(() => _uiVisible = !_uiVisible);

  Future<String> _resolveToUrl(String maybeUrlOrStoragePath) {
    if (maybeUrlOrStoragePath.startsWith('http://') ||
        maybeUrlOrStoragePath.startsWith('https://')) {
      return Future.value(maybeUrlOrStoragePath);
    }
    return FirebaseStorage.instance.ref(maybeUrlOrStoragePath).getDownloadURL();
  }

  Future<String> _getUrlCached(String key) {
    return _urlFutures.putIfAbsent(key, () => _resolveToUrl(key));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.repo.getDeck(widget.deckId),
      builder: (context, snap) {
        // 1) Loading state
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2) Error state (this fixes the "spinner forever" problem)
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

        // 3) No data / not found
        final deck = snap.data;
        if (deck == null) {
          return const Scaffold(
            body: Center(child: Text('Deck not found.')),
          );
        }

        // Prefer old URLs, fall back to new Storage paths
        final List<String> slideRefs =
            deck.slideImageUrls.isNotEmpty ? deck.slideImageUrls : deck.slides;

        debugPrint(
          "DECK DEBUG: slideImageUrls=${deck.slideImageUrls.length}, "
          "slides=${deck.slides.length}, "
          "using=${slideRefs.length}",
        );

        if (slideRefs.isEmpty) {
          return const Scaffold(
            backgroundColor: Color(0xFF0B0B0B),
            body: Center(
              child: Text(
                'No slides found on this deck.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0B0B0B),
          body: Stack(
            children: [
              // Debug overlay visible in-app
              Positioned(
                left: 12,
                top: 60,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.black54,
                  child: Text(
                    'slideImageUrls=${deck.slideImageUrls.length}\n'
                    'slides=${deck.slides.length}\n'
                    'using=${slideRefs.length}\n'
                    'page=${_page + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),

              GestureDetector(
                onTap: _toggleUi,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: slideRefs.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, index) {
                    final ref = slideRefs[index];

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

                            return CachedNetworkImage(
                              imageUrl: urlSnap.data!,
                              fit: BoxFit.contain,
                              placeholder: (c, _) =>
                                  const CircularProgressIndicator(),
                              errorWidget: (c, err, __) => Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Image request failed:\n$err',
                                  style: const TextStyle(color: Colors.white70),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (_uiVisible)
                SafeArea(
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
            ],
          ),
        );
      },
    );
  }
}
