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

  bool _uploading = false;

  // ---------- Pick PPT ----------
  Future<void> _pickPpt() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ppt', 'pptx'],
    );

    if (result == null || result.files.single.path == null) return;

    setState(() {
      _pptFile = File(result.files.single.path!);
      _pptName = result.files.single.name;
    });
  }

  // ---------- Upload ----------
  Future<void> _uploadPpt() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _pptFile == null) return;

    final topic = _titleCtrl.text.trim();
    if (topic.isEmpty) {
      _toast('Please enter a topic');
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

      await storageRef.putFile(_pptFile!);
      final downloadUrl = await storageRef.getDownloadURL();

      await deckRef.update({
        'pptUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _toast('Upload submitted for review');

      setState(() {
        _pptFile = null;
        _pptName = null;
        _titleCtrl.clear();
        _selectedSpecialty = 'General';
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PowerPoint details',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Topic',
                  border: OutlineInputBorder(),
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

              OutlinedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: const Text('Select PPT / PPTX file'),
                onPressed: _pickPpt,
              ),

              if (_pptName != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.description_outlined, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _pptName!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const Spacer(),

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
    );
  }
}
