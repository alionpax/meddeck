import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Unknown';
    final box = Hive.box('offline');
    final currentTheme = box.get('theme', defaultValue: 'playful') as String;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          const Text('Account', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(email),
          ),
          const SizedBox(height: 16),

          // Theme selector
          const Text('Appearance', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.color_lens_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: currentTheme,
                    items: const [
                      DropdownMenuItem(value: 'playful', child: Text('Playful Aurora')),
                      DropdownMenuItem(value: 'medical', child: Text('Medical Atlas')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      box.put('theme', v);
                      // ValueListenableBuilder in app will update theme automatically
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () async {
                await AuthService().signOut();
                if (context.mounted) {
                  // AuthGate will show LoginScreen again.
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Sign out'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Educational use only. Not medical advice.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
