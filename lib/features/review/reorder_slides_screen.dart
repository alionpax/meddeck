import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meddeck/widgets/safe_network_image.dart';

class ReorderSlidesScreen extends StatefulWidget {
  final String deckId;
  final List<String> urls;

  const ReorderSlidesScreen({
    super.key,
    required this.deckId,
    required this.urls,
  });

  @override
  State<ReorderSlidesScreen> createState() =>
      _ReorderSlidesScreenState();
}

class _ReorderSlidesScreenState
    extends State<ReorderSlidesScreen> {
  late List<String> _slides;

  @override
  void initState() {
    super.initState();
    _slides = List.from(widget.urls);
  }

  Future<void> _save() async {
    await FirebaseFirestore.instance
        .collection('decks')
        .doc(widget.deckId)
        .update({
      'slideImageUrls': _slides,
      'coverImageUrl': _slides.first,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reorder slides'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _slides.length,
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) newIndex--;
          setState(() {
            final item = _slides.removeAt(oldIndex);
            _slides.insert(newIndex, item);
          });
        },
        itemBuilder: (_, i) => ListTile(
          key: ValueKey(_slides[i]),
          leading: SafeNetworkImage(
            url: _slides[i],
            fit: BoxFit.cover,
          ),
          title: Text('Slide ${i + 1}'),
          trailing: const Icon(Icons.drag_handle),
        ),
      ),
    );
  }
}
