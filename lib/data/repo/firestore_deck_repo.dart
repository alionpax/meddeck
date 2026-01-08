import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:meddeck/data/models/deck.dart';
import 'package:meddeck/data/repo/deck_repo.dart';



class FirestoreDeckRepo implements DeckRepo {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('decks');

  @override
  Future<List<Deck>> listApprovedDecks() async {
    final q = await _col
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .get();

    return q.docs.map(_fromQueryDoc).toList();
  }

  // Not part of DeckRepo, but used by admin/review screens
  Future<List<Deck>> listPendingDecks() async {
    final q = await _col
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();

    return q.docs.map(_fromQueryDoc).toList();
  }

  @override
  Future<Deck?> getDeck(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) return null;

    final data = snap.data();
    if (data == null) return null;

    // Use the same parsing logic as query docs
    return _fromMap(id, data);
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

      // Fields required by your Deck model (old URL-based fields)
      'slideCount': 0,
      'source': 'user',
      'coverImageUrl': '',
      'slides': <String>[], // Storage paths will be populated by Cloud Functions
    });
  }

  Future<void> setStatus(String deckId, String status) async {
    await _col.doc(deckId).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Deck _fromQueryDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    return _fromMap(d.id, d.data());
  }

  Deck _fromMap(String id, Map<String, dynamic> m) {
    final slideImageUrlsRaw = m['slideImageUrls'];
    final slidesRaw = m['slides'];

    DateTime uploadedAt = DateTime.fromMillisecondsSinceEpoch(0);
    final ca = m['createdAt'];
    if (ca is Timestamp) {
      uploadedAt = ca.toDate();
    } else if (ca is String) {
      try {
        uploadedAt = DateTime.parse(ca);
      } catch (_) {}
    }

    return Deck(
      id: id,
      title: (m['title'] ?? 'Untitled').toString(),
      specialty: (m['specialty'] ?? 'General').toString(),

      // Firestore numeric safety
      slideCount: (m['slideCount'] as num?)?.toInt() ?? 0,

      source: (m['source'] ?? 'unknown').toString(),
      coverImageUrl: (m['coverImageUrl'] ?? '').toString(),

      slideImageUrls: (slideImageUrlsRaw is List)
          ? slideImageUrlsRaw.map((e) => e.toString()).toList()
          : const <String>[],

      // ✅ New fields for auto-convert pipeline
      slides: (slidesRaw is List)
          ? slidesRaw.map((e) => e.toString()).toList()
          : const <String>[],
      coverSlide: m['coverSlide']?.toString(),

      pptUrl: m['pptUrl']?.toString(),
      uploadedAt: uploadedAt,
    );
  }
}
