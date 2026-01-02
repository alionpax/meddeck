class Deck {
  final String id;
  final String title;
  final String specialty;
  final int slideCount;
  final String source;
  final String coverImageUrl;
  final List<String> slideImageUrls;

  const Deck({
    required this.id,
    required this.title,
    required this.specialty,
    required this.slideCount,
    required this.source,
    required this.coverImageUrl,
    required this.slideImageUrls,
  });
}
