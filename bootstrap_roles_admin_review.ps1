$ErrorActionPreference = "Stop"

function Ensure-Dir($path) {
  if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path | Out-Null }
}

function Write-File($path, $content) {
  $dir = Split-Path $path
  Ensure-Dir $dir
  Set-Content -Path $path -Value $content -Encoding UTF8
  Write-Host "Wrote: $path"
}

function Patch-Pubspec-AddDep($depLine) {
  $pub = ".\pubspec.yaml"
  if (!(Test-Path $pub)) { throw "pubspec.yaml not found. Run from project root." }
  $txt = Get-Content $pub -Raw
  if ($txt -match [regex]::Escape($depLine.Split(':')[0] + ":")) {
    Write-Host "pubspec already contains $($depLine.Split(':')[0])"
    return
  }

  if ($txt -notmatch "(?m)^\s*dependencies:\s*$") { throw "dependencies: section not found in pubspec.yaml" }

  # Insert under dependencies:
  $patched = [regex]::Replace(
    $txt,
    "(?m)^(dependencies:\s*)$",
    "`$1`r`n  $depLine",
    1
  )
  Set-Content -Path $pub -Value $patched -Encoding UTF8
  Write-Host "Patched pubspec.yaml: added $depLine"
}

# 1) Add Firestore dependency
Patch-Pubspec-AddDep "cloud_firestore: ^5.6.0"

# 2) User repo (roles + ensure user doc)
Write-File ".\lib\data\repo\user_repo.dart" @'
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
'@

# 3) Firestore Deck repo (approved/pending/rejected)
Write-File ".\lib\data\repo\firestore_deck_repo.dart" @'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/deck.dart';

class FirestoreDeckRepo {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('decks');

  Future<List<Deck>> listApprovedDecks() async {
    final q = await _col.where('status', isEqualTo: 'approved').orderBy('createdAt', descending: true).get();
    return q.docs.map(_fromDoc).toList();
  }

  Future<List<Deck>> listPendingDecks() async {
    final q = await _col.where('status', isEqualTo: 'pending').orderBy('createdAt', descending: true).get();
    return q.docs.map(_fromDoc).toList();
  }

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

      // Placeholder fields for later PPT pipeline
      'slideCount': 0,
      'thumbUrl': null,
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
    // Your existing Deck model likely expects: id, title, specialty, etc.
    // We keep it defensive: if your model differs, tell me and I’ll adjust.
    return Deck(
      id: d.id,
      title: (m['title'] as String?) ?? 'Untitled',
      specialty: (m['specialty'] as String?) ?? 'General',
      description: (m['description'] as String?) ?? '',
      slideCount: (m['slideCount'] as int?) ?? 0,
      thumbnailUrl: (m['thumbUrl'] as String?) ?? '',
      tags: List<String>.from((m['tags'] as List?) ?? const []),
    );
  }
}
'@

# 4) Review screen (admin only)
Ensure-Dir ".\lib\features\review"
Write-File ".\lib\features\review\review_screen.dart" @'
import 'package:flutter/material.dart';
import '../../data/repo/firestore_deck_repo.dart';

class ReviewScreen extends StatefulWidget {
  final FirestoreDeckRepo repo;
  const ReviewScreen({super.key, required this.repo});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  Future<void> _refresh() async => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: FutureBuilder(
        future: widget.repo.listPendingDecks(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final decks = snap.data!;
          if (decks.isEmpty) {
            return const Center(child: Text('No pending decks.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: decks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final d = decks[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(d.specialty, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await widget.repo.setStatus(d.id, 'rejected');
                                if (mounted) _refresh();
                              },
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                await widget.repo.setStatus(d.id, 'approved');
                                if (mounted) _refresh();
                              },
                              child: const Text('Approve'),
                            ),
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
    );
  }
}
'@

# 5) Patch Uploads screen: create pending deck
Write-File ".\lib\features\uploads\uploads_screen.dart" @'
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
'@

Write-Host "`nDone. Now update AuthGate + Library + app routes manually (I’m keeping the patch small and safe)."
Write-Host "Next: follow the instructions in chat."
