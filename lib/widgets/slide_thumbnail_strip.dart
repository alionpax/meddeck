import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:meddeck/widgets/safe_network_image.dart';

class SlideThumbnailStrip extends StatefulWidget {
  final List<String> urls;
  final void Function(int index) onTap;
  final void Function(int index)? onIndexChanged;

  const SlideThumbnailStrip({super.key, required this.urls, required this.onTap, this.onIndexChanged});

  @override
  State<SlideThumbnailStrip> createState() => _SlideThumbnailStripState();
}

class _SlideThumbnailStripState extends State<SlideThumbnailStrip> {
  final ScrollController _ctrl = ScrollController();
  static const double _height = 72;
  static const double _sep = 8;

  double get _itemWidth => _height * (16 / 9);
  double get _itemExtent => _itemWidth + _sep;

  void _maybeReportIndex() {
    if (!mounted) return;
    final offset = _ctrl.offset;
    final idx = (offset / _itemExtent).round().clamp(0, widget.urls.length - 1);
    widget.onIndexChanged?.call(idx);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollEndNotification || n is OverscrollNotification) {
            _maybeReportIndex();
          }
          return false;
        },
        child: ListView.separated(
          controller: _ctrl,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: widget.urls.length,
          separatorBuilder: (_, __) => const SizedBox(width: _sep),
          itemBuilder: (context, i) => InkWell(
            onTap: () {
              widget.onTap(i);
              // Center the tapped item (best effort)
              final target = i * _itemExtent;
              _ctrl.animateTo(target, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: SafeNetworkImage(
                  url: widget.urls[i],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
