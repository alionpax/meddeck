import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a slide image to:
  /// slides/<deckId>/slide_001.jpg
  /// Returns the public download URL
  Future<String> uploadSlide({
    required String deckId,
    required File file,
    required int index,
  }) async {
    final ext = p.extension(file.path);

    final ref = _storage.ref(
      'slides/$deckId/slide_${index.toString().padLeft(3, "0")}$ext',
    );

    final snapshot = await ref.putFile(file);
    final url = await snapshot.ref.getDownloadURL();

    return url;
  }
}
