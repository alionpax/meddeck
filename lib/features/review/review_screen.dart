import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

import '../../data/repo/firestore_deck_repo.dart';
import 'slide_upload_screen.dart';

class ReviewScreen extends StatefulWidget {
  final FirestoreDeckRepo repo;

  const ReviewScreen({
    super.key,
    required this.repo,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final ConfettiController _confettiController;

  Future<void> _refresh() async {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final confettiColors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Colors.amber,
    ];

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Review submissions'),
          ),
          body: FutureBuilder(
            future: widget.repo.listPendingDecks(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snap.hasError) {
                return Center(
                  child: Text('Error: ${snap.error}'),
                );
              }

              final decks = snap.data ?? [];

              if (decks.isEmpty) {
                return const Center(
                  child: Text('No pending submissions'),
                );
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: decks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final d = decks[i];

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ---------- Title ----------
                          Text(
                            d.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // ---------- Specialty ----------
                          Row(
                            children: [
                              const Icon(
                                Icons.local_hospital_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                d.specialty,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ---------- Actions ----------
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Upload slide images',
                                icon: const Icon(Icons.image_outlined),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SlideUploadScreen(
                                        deckId: d.id,
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const Spacer(),

                              OutlinedButton(
                                onPressed: () async {
                                  await widget.repo.setStatus(
                                    d.id,
                                    'rejected',
                                  );
                                  if (mounted) _refresh();
                                },
                                child: const Text('Reject'),
                              ),

                              const SizedBox(width: 12),

                              FilledButton(
                                onPressed: () async {
                                  await widget.repo.setStatus(
                                    d.id,
                                    'approved',
                                  );
                                  _confettiController.play();
                                  await Future.delayed(const Duration(milliseconds: 800));
                                  if (mounted) _refresh();
                                },
                                child: const Text('Approve'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),

        // Confetti overlay
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: confettiColors,
                emissionFrequency: 0.02,
                numberOfParticles: 20,
                gravity: 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
