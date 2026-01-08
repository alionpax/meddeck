import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../widgets/safe_network_image.dart';
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

  // Track zoom state so page swipes are allowed when not zoomed
  late final TransformationController _transformationController;
  bool _isZoomed = false;
  VelocityTracker? _velocityTracker;
  double? _dragStartX;
  double? _dragLastX;

  bool _autoplay = false;
  Timer? _autoplayTimer;

  final Map<String, Future<String>> _urlFutures = {};  

  void _startAutoplay() {
    _autoplayTimer?.cancel();
    _autoplayTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_page < (_controller.positions.isNotEmpty ? (_controller.positions.first.viewportDimension > 0 ? 9999 : 0) : 9999)) {}
      if (_page < (_controller.positions.isNotEmpty ? 1000000 : 1000000)) {
        if (_page < 1000000000) {
          if (_page < 999999999) {
            // attempt to go to next page; guard will be enforced by PageView builder length
            _controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
          }
        }
      }
    });
    setState(() => _autoplay = true);
  }

  void _stopAutoplay() {
    _autoplayTimer?.cancel();
    _autoplayTimer = null;
    setState(() => _autoplay = false);
  }

  @override
  void initState() {
    super.initState();
    _page = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
    _transformationController = TransformationController();

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
    _transformationController.dispose();
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

        // Use storage paths (slides) - they never expire and are more efficient
        final List<String> slideRefs = deck.slides.isNotEmpty 
            ? deck.slides 
            : deck.slideImageUrls; // fallback for old data

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
                    physics: _isZoomed ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    itemCount: slideRefs.length,
                    onPageChanged: (i) {
                      HapticFeedback.selectionClick();
                      setState(() => _page = i);
                    },
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

                          final iv = InteractiveViewer(
                            transformationController: _transformationController,
                            minScale: 1,
                            maxScale: 4,
                            panEnabled: true,
                            onInteractionStart: (_) {
                              final scale = _transformationController.value.getMaxScaleOnAxis();
                              if (scale > 1.01 && !_isZoomed) setState(() => _isZoomed = true);
                            },
                            onInteractionUpdate: (details) {
                              final scale = details.scale;
                              if (scale != null && scale > 1.01 && !_isZoomed) setState(() => _isZoomed = true);
                            },
                            onInteractionEnd: (_) {
                              final scale = _transformationController.value.getMaxScaleOnAxis();
                              if (scale <= 1.02 && _isZoomed) {
                                _transformationController.value = Matrix4.identity();
                                setState(() => _isZoomed = false);
                              } else if (scale > 1.02 && !_isZoomed) {
                                setState(() => _isZoomed = true);
                              }
                            },
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
                                      child: SafeNetworkImage(
                                        url: urlSnap.data!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );

                          // When zoomed, allow local panning AND page-fling to still work.
                          if (_isZoomed) {
                            return Listener(
                              behavior: HitTestBehavior.translucent,
                              onPointerDown: (PointerDownEvent event) {
                                _velocityTracker = VelocityTracker.withKind(event.kind);
                                _velocityTracker?.addPosition(event.timeStamp, event.position);
                                _dragStartX = event.position.dx;
                                _dragLastX = event.position.dx;
                                if (kDebugMode) debugPrint('SlideViewer pointerDown index=$index pos=${event.position}');
                              },
                              onPointerMove: (PointerMoveEvent event) {
                                _velocityTracker?.addPosition(event.timeStamp, event.position);
                                _dragLastX = event.position.dx;
                              },
                              onPointerUp: (PointerUpEvent event) {
                                final v = _velocityTracker?.getVelocity() ?? Velocity.zero;
                                final vx = v.pixelsPerSecond.dx;
                                const thresh = 300.0; // lower threshold for touch flings
                                if (kDebugMode) debugPrint('SlideViewer pointerUp index=$index vx=$vx');
                                if (vx.abs() > thresh) {
                                  if (vx < 0 && index < slideRefs.length - 1) {
                                    // navigate forward
                                    _controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut).then((_) async {
                                      _transformationController.value = Matrix4.identity();
                                      setState(() => _isZoomed = false);
                                      await HapticFeedback.lightImpact();
                                    });
                                  } else if (vx > 0 && index > 0) {
                                    // navigate back
                                    _controller.previousPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut).then((_) async {
                                      _transformationController.value = Matrix4.identity();
                                      setState(() => _isZoomed = false);
                                      await HapticFeedback.lightImpact();
                                    });
                                  }
                                } else {
                                  // If velocity was low, fall back to distance-based detection
                                  if (_dragStartX != null && _dragLastX != null) {
                                    final dxPixels = (_dragLastX! - _dragStartX!);
                                    final distanceThresh = constraints.maxWidth * 0.25; // more permissive
                                    if (dxPixels.abs() > distanceThresh) {
                                      if (dxPixels < 0 && index < slideRefs.length - 1) {
                                        _controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut).then((_) async {
                                          _transformationController.value = Matrix4.identity();
                                          setState(() => _isZoomed = false);
                                          await HapticFeedback.lightImpact();
                                        });
                                      } else if (dxPixels > 0 && index > 0) {
                                        _controller.previousPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut).then((_) async {
                                          _transformationController.value = Matrix4.identity();
                                          setState(() => _isZoomed = false);
                                          await HapticFeedback.lightImpact();
                                        });
                                      }
                                    }
                                  }
                                }

                                _velocityTracker = null;
                              },

                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onDoubleTap: () {
                                  _transformationController.value = Matrix4.identity();
                                  setState(() => _isZoomed = false);
                                },
                                // Let the InteractiveViewer handle panning; we only detect flings here.
                                child: iv,
                              ),
                            );
                          }

                          return iv;
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

                // Floating controls shown when the slide is zoomed (pan mode)
                if (_isZoomed) ...[
                  // Prev
                  Positioned(
                    left: 8,
                    top: MediaQuery.of(context).size.height / 2 - 28,
                    child: FloatingActionButton.small(
                      onPressed: () {
                        if (_page > 0) {
                          _controller.previousPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut).then((_) {
                            _transformationController.value = Matrix4.identity();
                            setState(() => _isZoomed = false);
                          });
                        }
                      },
                      child: const Icon(Icons.chevron_left),
                    ),
                  ),

                  // Next
                  Positioned(
                    right: 8,
                    top: MediaQuery.of(context).size.height / 2 - 28,
                    child: FloatingActionButton.small(
                      onPressed: () {
                        if (_page < slideRefs.length - 1) {
                          _controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut).then((_) {
                            _transformationController.value = Matrix4.identity();
                            setState(() => _isZoomed = false);
                          });
                        }
                      },
                      child: const Icon(Icons.chevron_right),
                    ),
                  ),

                  // Autoplay toggle
                  Positioned(
                    bottom: 80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FloatingActionButton.small(
                        backgroundColor: _autoplay ? Theme.of(context).colorScheme.primary : null,
                        onPressed: () {
                          if (_autoplay) _stopAutoplay();
                          else _startAutoplay();
                        },
                        child: Icon(_autoplay ? Icons.pause : Icons.play_arrow),
                      ),
                    ),
                  ),
                ],
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
