import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Unknown';
    final box = Hive.box('offline');
    final currentTheme = box.get('theme', defaultValue: 'meddeck') as String;
    final isDarkMode = box.get('darkMode', defaultValue: false) as bool;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          const Text('Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(email[0].toUpperCase()),
              ),
              title: Text(email),
              subtitle: Text('Signed in', style: Theme.of(context).textTheme.bodySmall),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/profile'),
            ),
          ),
          const SizedBox(height: 24),

          // Appearance
          const Text('Appearance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          
          // Dark mode toggle
          Card(
            child: SwitchListTile(
              secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
              title: const Text('Dark Mode'),
              subtitle: Text(isDarkMode ? 'Enabled' : 'Disabled'),
              value: isDarkMode,
              onChanged: (bool value) {
                box.put('darkMode', value);
              },
            ),
          ),
          const SizedBox(height: 12),

          // Theme selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Color Theme'),
                    dense: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      value: currentTheme,
                      items: const [
                        DropdownMenuItem(value: 'meddeck', child: Text('MedDeck (Coral-Purple)')),
                        DropdownMenuItem(value: 'playful', child: Text('Playful Aurora')),
                        DropdownMenuItem(value: 'medical', child: Text('Medical Atlas')),
                        DropdownMenuItem(value: 'forest', child: Text('Forest Green')),
                        DropdownMenuItem(value: 'mono', child: Text('Monochrome')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        box.put('theme', v);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Actions
          const Text('Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              'Educational use only. Not medical advice.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'MedDeck v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
