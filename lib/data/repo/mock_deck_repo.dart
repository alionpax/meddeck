import 'deck_repo.dart';
import '../models/deck.dart';

class MockDeckRepo implements DeckRepo {
  final List<Deck> _decks = [
    Deck(
      id: 'ecg101',
      title: 'ECG 101',
      specialty: 'Cardiology',
      slideCount: 24,
      source: 'Educational collection',
      coverImageUrl: 'https://images.unsplash.com/photo-1581594549595-35f6edc7b762?auto=format&fit=crop&w=1200&q=60',
      slideImageUrls: List.generate(24, (_) => 'https://images.unsplash.com/photo-1581594549595-35f6edc7b762?auto=format&fit=crop&w=1600&q=60'),
    ),
    Deck(
      id: 'abg',
      title: 'ABG Interpretation',
      specialty: 'Critical Care',
      slideCount: 18,
      source: 'Educational collection',
      coverImageUrl: 'https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=1200&q=60',
      slideImageUrls: List.generate(18, (_) => 'https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=1600&q=60'),
    ),
  ];

  @override
  Future<List<Deck>> listApprovedDecks() async => _decks;

  @override
  Future<Deck?> getDeck(String id) async {
    try { return _decks.firstWhere((d) => d.id == id); } catch (_) { return null; }
  }
}
