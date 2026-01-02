import 'package:flutter/material.dart';

class UploadsScreen extends StatelessWidget {
  const UploadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uploads')),
      body: const Center(child: Text('Upload + My Uploads: next step.')),
    );
  }
}
