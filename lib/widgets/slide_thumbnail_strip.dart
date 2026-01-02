import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SlideThumbnailStrip extends StatelessWidget {
  final List<String> urls;
  final void Function(int index) onTap;

  const SlideThumbnailStrip({super.key, required this.urls, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => InkWell(
          onTap: () => onTap(i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: urls[i],
                fit: BoxFit.cover,
                placeholder: (c, _) => Container(color: Theme.of(context).dividerColor.withOpacity(0.4)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
