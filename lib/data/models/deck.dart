class Deck {
  final String id;
  final String title;
  final String specialty;
  final int slideCount;
  final String source;

  // Storage-path-based fields (permanent, no expiration)
  final List<String> slides;  // e.g. ["ppts/.../slide_001.png", ...]
  final String? coverSlide;   // e.g. "ppts/.../slides/slide_001.png"

  // Deprecated: Old URL-based fields (kept for backward compatibility)
  @Deprecated('Use slides instead - URLs expire after 7 days')
  final String coverImageUrl;
  @Deprecated('Use slides instead - URLs expire after 7 days')
  final List<String> slideImageUrls;

  final String? pptUrl;
  final DateTime uploadedAt;

  Deck({
    required this.id,
    required this.title,
    required this.specialty,
    required this.slideCount,
    required this.source,
    required this.slides,

    // Backward compatibility - deprecated fields
    this.coverImageUrl = '',
    this.slideImageUrls = const <String>[],

    this.coverSlide,
    this.pptUrl,
    DateTime? uploadedAt,
  }) : uploadedAt = uploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  factory Deck.fromJson(String id, Map<String, dynamic> json) {
    final slidesRaw = json['slides'];
    final slideImageUrlsRaw = json['slideImageUrls'];

    DateTime uploaded = DateTime.fromMillisecondsSinceEpoch(0);
    try {
      final ts = json['createdAt'];
      if (ts is DateTime) uploaded = ts;
      // Firestore returns Timestamp objects when read from snapshots; repo handles mapping
    } catch (_) {}

    return Deck(
      id: id,
      title: (json['title'] ?? '').toString(),
      specialty: (json['specialty'] ?? '').toString(),
      slideCount: (json['slideCount'] as num?)?.toInt() ?? 0,
      source: (json['source'] ?? '').toString(),

      coverImageUrl: (json['coverImageUrl'] ?? '').toString(),
      slides: (slidesRaw is List && (slidesRaw as List).isNotEmpty)
          ? slidesRaw.map((e) => e.toString()).toList()
          : (slideImageUrlsRaw is List)
              ? slideImageUrlsRaw.map((e) => e.toString()).toList()
              : const <String>[],

      slideImageUrls: (slideImageUrlsRaw is List)
          ? slideImageUrlsRaw.map((e) => e.toString()).toList()
          : const <String>[],

      coverSlide: json['coverSlide']?.toString(),
      pptUrl: json['pptUrl']?.toString(),
      uploadedAt: uploaded,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'specialty': specialty,
      'slideCount': slideCount,
      'source': source,
      'coverImageUrl': coverImageUrl,
      'slideImageUrls': slideImageUrls,
      'slides': slides,
      'coverSlide': coverSlide,
      'pptUrl': pptUrl,
      'createdAt': uploadedAt,
    };
  }

  static Deck fromMap(Map<String, dynamic> map) {
    return Deck.fromJson(map['id'] as String, map);
  }
}

