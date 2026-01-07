import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SafeNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const SafeNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
  });

  bool get _looksLikeUrl {
    final u = url.trim();
    return u.startsWith('http://') || u.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final u = url.trim();

    if (u.isEmpty || !_looksLikeUrl) {
      return Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Icon(Icons.photo, size: 32, color: Colors.black38),
      );
    }

    return CachedNetworkImage(
      imageUrl: u,
      fit: fit,
      placeholder: (context, url) => Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, size: 28, color: Colors.black38),
      ),
    );
  }
}

