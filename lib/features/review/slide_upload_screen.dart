import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class SlideUploadScreen extends StatefulWidget {
  final String deckId;

  const SlideUploadScreen({
    super.key,
    required this.deckId,
  });

  @override
  State<SlideUploadScreen> createState() => _SlideUploadScreenState();
}

class _SlideUploadScreenState extends State<SlideUploadScreen> {
  bool _uploading = false;
  final List<File> _slides = [];

  // -------- PICK IMAGES (FIXED FOR ANDROID) --------
  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );

    if (result == null) return;

    setState(() {
      _slides.addAll(
        result.files
            .where((f) => f.path != null)
            .map((f) => File(f.path!)),
      );
    });
  }

  // -------- UPLOAD TO FIREBASE --------
  Future<void> _uploadSlides() async {
    if (_slides.isEmpty) return;

    setState(() => _uploading = true);

    try {
      final storage = FirebaseStorage.instance;
      final deckRef = FirebaseFirestore.instance
          .collection('decks')
          .doc(widget.deckId);

      final urls = <String>[];

      for (int i = 0; i < _slides.length; i++) {
        final ref = storage.ref(
          'slides/${widget.deckId}/slide_${(i + 1).toString().padLeft(3, '0')}.jpg',
        );

        await ref.putFile(_slides[i]);
        urls.add(await ref.getDownloadURL());
      }

      await deckRef.update({
        'slideImageUrls': urls,
        'slideCount': urls.length,
        'coverImageUrl': urls.first,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slides uploaded successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed')),
        );
      }
    } finally {
      setState(() => _uploading = false);
    }
  }

  // -------- UI --------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload slide images'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.image_outlined),
              label: const Text('Select slide images'),
              onPressed: _pickImages,
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _slides.isEmpty
                  ? const Center(
                      child: Text('No images selected'),
                    )
                  : ListView.builder(
                      itemCount: _slides.length,
                      itemBuilder: (_, i) => ListTile(
                        leading: const Icon(Icons.image),
                        title: Text('Slide ${i + 1}'),
                      ),
                    ),
            ),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload),
                label: Text(
                  _uploading ? 'Uploading…' : 'Upload slides',
                ),
                onPressed: _uploading ? null : _uploadSlides,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
