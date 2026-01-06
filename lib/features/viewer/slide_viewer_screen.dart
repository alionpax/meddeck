import 'package:cached_network_image/cached_network_image.dart';
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.repo.getDeck(widget.deckId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final deck = snap.data;
        if (deck == null) {
          return const Scaffold(
            body: Center(child: Text('Deck not found.')),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0B0B0B),
          body: Stack(
            children: [
              GestureDetector(
                onTap: _toggleUi,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: deck.slideImageUrls.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, index) {
                    return InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: CachedNetworkImage(
                          imageUrl: deck.slideImageUrls[index],
                          fit: BoxFit.contain,
                          placeholder: (c, _) =>
                              const CircularProgressIndicator(),
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
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        const Spacer(),
                        Text(
                          '${_page + 1} / ${deck.slideImageUrls.length}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
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
