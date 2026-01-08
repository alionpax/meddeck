import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;

class UploadsScreen extends StatefulWidget {
  const UploadsScreen({super.key});

  @override
  State<UploadsScreen> createState() => _UploadsScreenState();
}

class _UploadsScreenState extends State<UploadsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _presenterCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  late ConfettiController _confettiController;

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

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _titleCtrl.dispose();
    _presenterCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  // ---------- Pick PPT ----------
  Future<void> _pickPpt() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ppt', 'pptx'],
    );

    if (result == null || result.files.single.path == null) return;

    final f = File(result.files.single.path!);
    final fileName = result.files.single.name;

    // Extract metadata from document
    String topicSuggestion = '';
    String presenterName = '';
    String presentationDate = '';

    try {
      if (fileName.toLowerCase().endsWith('.pptx')) {
        // PPTX is a ZIP file, extract metadata from XML
        final bytes = await f.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        // Extract title from docProps/core.xml
        final coreFile = archive.findFile('docProps/core.xml');
        if (coreFile != null) {
          final coreContent = String.fromCharCodes(coreFile.content as List<int>);
          final coreDoc = xml.XmlDocument.parse(coreContent);
          
          // Try to get title
          final titleElement = coreDoc.findAllElements('dc:title').firstOrNull;
          if (titleElement != null && titleElement.innerText.isNotEmpty) {
            topicSuggestion = titleElement.innerText;
          }
          
          // Try to get creator/author
          final creatorElement = coreDoc.findAllElements('dc:creator').firstOrNull;
          if (creatorElement != null && creatorElement.innerText.isNotEmpty) {
            presenterName = creatorElement.innerText;
          }
          
          // Try to get created date
          final createdElement = coreDoc.findAllElements('dcterms:created').firstOrNull;
          if (createdElement != null && createdElement.innerText.isNotEmpty) {
            try {
              final dateStr = createdElement.innerText;
              final parsedDate = DateTime.parse(dateStr);
              presentationDate = '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';
            } catch (_) {}
          }
        }

        // If title not found in core.xml, try app.xml
        if (topicSuggestion.isEmpty) {
          final appFile = archive.findFile('docProps/app.xml');
          if (appFile != null) {
            final appContent = String.fromCharCodes(appFile.content as List<int>);
            final appDoc = xml.XmlDocument.parse(appContent);
            final titlesElement = appDoc.findAllElements('TitlesOfParts').firstOrNull;
            if (titlesElement != null && titlesElement.innerText.isNotEmpty) {
              topicSuggestion = titlesElement.innerText;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error extracting metadata: $e');
    }

    // Fallback to filename if metadata extraction failed
    if (topicSuggestion.isEmpty) {
      topicSuggestion = fileName
          .replaceAll(RegExp(r'\.(ppt|pptx)$', caseSensitive: false), '')
          .replaceAll(RegExp(r'[_-]+'), ' ')
          .trim();
    }

    // Fallback to current user if no presenter found
    if (presenterName.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      presenterName = user?.displayName ?? user?.email?.split('@').first ?? 'Unknown Presenter';
    }

    // Fallback to today's date if no date found
    if (presentationDate.isEmpty) {
      final today = DateTime.now();
      presentationDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    }

    int? fileSize;
    try {
      fileSize = f.lengthSync();
    } catch (_) {
      fileSize = null;
    }

    setState(() {
      _pptFile = f;
      _pptName = fileName;
      _pptSize = fileSize;

      // Auto-fill form fields (user can edit these)
      if (_titleCtrl.text.isEmpty) {
        _titleCtrl.text = topicSuggestion;
      }
      if (_presenterCtrl.text.isEmpty) {
        _presenterCtrl.text = presenterName;
      }
      if (_dateCtrl.text.isEmpty) {
        _dateCtrl.text = presentationDate;
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
        'presenterName': _presenterCtrl.text.trim(),
        'presentationDate': _dateCtrl.text.trim(),
        'fileSizeBytes': _pptSize,
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

      if (mounted) {
        _confettiController.play();
        _showSuccessDialog();
      }

      setState(() {
        _pptFile = null;
        _pptName = null;
        _pptSize = null;
        _titleCtrl.clear();
        _presenterCtrl.clear();
        _dateCtrl.clear();
        _selectedSpecialty = 'General';
        _uploadProgress = null;
      });
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
      debugPrint(e.toString());
    } finally {
      setState(() => _uploading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Upload Successful!'),
          ],
        ),
        content: const Text(
          'Your PowerPoint has been submitted for review.\n\n'
          'You\'ll be able to see it in the Library once an admin approves it.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Upload Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Something went wrong with your upload.'),
            const SizedBox(height: 12),
            Text(
              'Error: $error',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadPpt();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
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
      body: Stack(
        children: [
          SafeArea(
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
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Topic, presenter, and date are extracted from the document metadata. You can edit them before submitting.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Topic',
                          border: OutlineInputBorder(),
                          helperText: 'Extracted from document title',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a topic' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _presenterCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Presenter Name',
                          border: OutlineInputBorder(),
                          helperText: 'Extracted from document author',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter presenter name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Presentation Date',
                          border: OutlineInputBorder(),
                          helperText: 'Extracted from document created date',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter presentation date' : null,
                      ),
                    ],
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
                              const SizedBox(height: 4),
                              if (_pptSize != null) Text(
                                'Size: ${(_pptSize! / (1024 * 1024)).toStringAsFixed(2)} MB',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                              ),
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
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
