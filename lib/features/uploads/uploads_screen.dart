import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class UploadsScreen extends StatefulWidget {
  const UploadsScreen({super.key});

  @override
  State<UploadsScreen> createState() => _UploadsScreenState();
}

class _UploadsScreenState extends State<UploadsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();

  final List<String> _specialties = const [
    'General',
    'Cardiology',
    'Neurology',
    'Orthopedics',
    'Radiology',
    'Pediatrics',
    'Surgery',
    'Internal Medicine',
    'Emergency Medicine',
  ];

  String _selectedSpecialty = 'General';

  File? _pptFile;
  String? _pptName;
  int? _pptSize;

  bool _uploading = false;
  double? _uploadProgress;

  // ---------- Pick PPT ----------
  Future<void> _pickPpt() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ppt', 'pptx'],
    );

    if (result == null || result.files.single.path == null) return;

    final f = File(result.files.single.path!);

    setState(() {
      _pptFile = f;
      _pptName = result.files.single.name;
      try {
        _pptSize = f.lengthSync();
      } catch (_) {
        _pptSize = null;
      }
    });
  }

  // ---------- Upload ----------
  Future<void> _uploadPpt() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _pptFile == null) return;

    if (!_formKey.currentState!.validate()) return;
    final topic = _titleCtrl.text.trim();
    if (_pptFile == null) {
      _toast('Please select a PPT file to upload');
      return;
    }

    setState(() => _uploading = true);

    try {
      final deckRef =
          FirebaseFirestore.instance.collection('decks').doc();

      await deckRef.set({
        'title': topic,
        'specialty': _selectedSpecialty,
        'ownerUid': user.uid,
        'source': 'user',
        'status': 'pending',
        'pptUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final storageRef = FirebaseStorage.instance.ref(
        'ppts/${deckRef.id}/$_pptName',
      );

      final uploadTask = storageRef.putFile(_pptFile!);

      uploadTask.snapshotEvents.listen((s) {
        final total = s.totalBytes;
        final transferred = s.bytesTransferred;
        if (total > 0) {
          setState(() => _uploadProgress = transferred / total);
        }
      });

      final snapshot = await uploadTask;
      final downloadUrl = await storageRef.getDownloadURL();

      await deckRef.update({
        'pptUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _toast('Upload submitted for review');

      setState(() {
        _pptFile = null;
        _pptName = null;
        _pptSize = null;
        _titleCtrl.clear();
        _selectedSpecialty = 'General';
        _uploadProgress = null;
      });
    } catch (e) {
      _toast('Upload failed');
      debugPrint(e.toString());
    } finally {
      setState(() => _uploading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit PowerPoint File for Review'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PowerPoint details',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Topic',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a topic' : null,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedSpecialty,
                  items: _specialties
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedSpecialty = v);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Specialty',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Presentation file',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                // File picker card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_pptName == null) ...[
                              Text('No file selected', style: theme.textTheme.bodySmall),
                              const SizedBox(height: 8),
                              Text('PPT / PPTX only. Max 100MB', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                            ] else ...[
                              Text(
                                _pptName!,
                                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              if (_pptSize != null) Text('${(_pptSize! / (1024 * 1024)).toStringAsFixed(1)} MB', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.attach_file),
                              label: const Text('Select'),
                              onPressed: _pickPpt,
                            ),
                            const SizedBox(height: 8),
                            IconButton(
                              onPressed: _pptName == null ? null : () => setState(() { _pptFile = null; _pptName = null; _pptSize = null; }),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_uploadProgress != null) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: _uploadProgress),
                  const SizedBox(height: 6),
                  Text('${(_uploadProgress! * 100).toStringAsFixed(0)}% uploaded', style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload),
                    label: Text(
                      _uploading
                          ? 'Uploading…'
                          : 'Submit for review',
                    ),
                    onPressed:
                        (_pptFile == null || _uploading)
                            ? null
                            : _uploadPpt,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All uploads are reviewed before becoming publicly visible.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
