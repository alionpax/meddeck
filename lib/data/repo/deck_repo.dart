import '../models/deck.dart';

abstract class DeckRepo {
  Future<List<Deck>> listApprovedDecks();
  Future<Deck?> getDeck(String id);
}
