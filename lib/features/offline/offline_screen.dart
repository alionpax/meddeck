import 'package:flutter/material.dart';
import '../../data/repo/deck_repo.dart';

class OfflineScreen extends StatelessWidget {
  final DeckRepo repo;
  const OfflineScreen({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline')),
      body: const Center(child: Text('Offline downloads will appear here.')),
    );
  }
}
