class Deck {
  final String id;
  final String title;
  final String specialty;
  final int slideCount;
  final String source;

  // Old URL-based fields (backward compatible)
  final String coverImageUrl;
  final List<String> slideImageUrls;

  // New Storage-path-based fields (from Cloud Run + Functions)
  final String? coverSlide;   // e.g. "ppts/.../slides/slide_001.png"
  final List<String> slides;  // e.g. ["ppts/.../slide_001.png", ...]

  final String? pptUrl;
  final DateTime uploadedAt;

  Deck({
    required this.id,
    required this.title,
    required this.specialty,
    required this.slideCount,
    required this.source,
    required this.coverImageUrl,
    required this.slideImageUrls,

    // ✅ IMPORTANT: default means existing Deck(...) call sites won't break
    this.slides = const <String>[],

    this.coverSlide,
    this.pptUrl,
    DateTime? uploadedAt,
  }) : uploadedAt = uploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  factory Deck.fromJson(String id, Map<String, dynamic> json) {
    final slideImageUrlsRaw = json['slideImageUrls'];
    final slidesRaw = json['slides'];

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
      slideImageUrls: (slideImageUrlsRaw is List)
          ? slideImageUrlsRaw.map((e) => e.toString()).toList()
          : const <String>[],

      slides: (slidesRaw is List)
          ? slidesRaw.map((e) => e.toString()).toList()
          : const <String>[],

      coverSlide: json['coverSlide']?.toString(),
      pptUrl: json['pptUrl']?.toString(),
      uploadedAt: uploaded,
    );
  }
}
