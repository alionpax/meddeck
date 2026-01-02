import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/deck.dart';

class FirestoreDeckRepo {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('decks');

  Future<List<Deck>> listApprovedDecks() async {
    final q = await _col
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .get();

    return q.docs.map(_fromDoc).toList();
  }

  Future<List<Deck>> listPendingDecks() async {
    final q = await _col
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();

    return q.docs.map(_fromDoc).toList();
  }

  /// For now this creates a "metadata-only" deck entry for workflow testing.
  /// Later we'll attach PPT upload + slide image generation.
  Future<void> createPendingDeck({
    required String title,
    required String specialty,
    required String ownerUid,
  }) async {
    await _col.add({
      'title': title.trim(),
      'specialty': specialty.trim(),
      'status': 'pending',
      'ownerUid': ownerUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),

      // Fields required by your Deck model:
      'slideCount': 0,
      'source': 'user',
      'coverImageUrl': '',
      'slideImageUrls': <String>[],
    });
  }

  Future<void> setStatus(String deckId, String status) async {
    await _col.doc(deckId).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Deck _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();

    return Deck(
      id: d.id,
      title: (m['title'] as String?) ?? 'Untitled',
      specialty: (m['specialty'] as String?) ?? 'General',
      slideCount: (m['slideCount'] as int?) ?? 0,
      source: (m['source'] as String?) ?? 'unknown',
      coverImageUrl: (m['coverImageUrl'] as String?) ?? '',
      slideImageUrls: List<String>.from((m['slideImageUrls'] as List?) ?? const []),
    );
  }
}
