import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepo {
  final _db = FirebaseFirestore.instance;

  Future<void> ensureUserDoc(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;

    await ref.set({
      'uid': user.uid,
      'email': user.email,
      'role': 'user', // default
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> getRole(String uid) async {
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();
    final data = snap.data();
    return (data?['role'] as String?) ?? 'user';
  }

  Future<void> setRole(String uid, String role) async {
    await _db.collection('users').doc(uid).set({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
