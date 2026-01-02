import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/repo/firestore_deck_repo.dart';

class UploadsScreen extends StatefulWidget {
  const UploadsScreen({super.key});

  @override
  State<UploadsScreen> createState() => _UploadsScreenState();
}

class _UploadsScreenState extends State<UploadsScreen> {
  final _repo = FirestoreDeckRepo();
  final _title = TextEditingController();
  final _specialty = TextEditingController(text: 'General');
  bool _loading = false;
  String? _msg;

  @override
  void dispose() {
    _title.dispose();
    _specialty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Uploads')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Submit a deck for admin review', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _specialty,
            decoration: const InputDecoration(
              labelText: 'Specialty',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: (user == null || _loading) ? null : () async {
                setState(() { _loading = true; _msg = null; });
                try {
                  await _repo.createPendingDeck(
                    title: _title.text,
                    specialty: _specialty.text,
                    ownerUid: user.uid,
                  );
                  _title.clear();
                  setState(() { _msg = 'Submitted. Awaiting approval.'; });
                } catch (e) {
                  setState(() { _msg = 'Failed: $e'; });
                } finally {
                  if (mounted) setState(() { _loading = false; });
                }
              },
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit for review'),
            ),
          ),
          if (_msg != null) ...[
            const SizedBox(height: 12),
            Text(_msg!),
          ],
          const SizedBox(height: 16),
          Text(
            'PPT upload pipeline comes next (storage + preview). For now, this submits metadata for workflow testing.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
