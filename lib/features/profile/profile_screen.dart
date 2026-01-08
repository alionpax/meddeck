import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    final box = Hive.box('offline');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      (user.email ?? 'U')[0].toUpperCase(),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.email ?? 'Unknown',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Medical Student',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Stats
          const Text(
            'Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('decks')
                .where('ownerUid', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              final uploadCount = snapshot.data?.docs.length ?? 0;

              return ValueListenableBuilder(
                valueListenable: box.listenable(),
                builder: (context, Box boxData, _) {
                  final favorites = boxData.get('favorites', defaultValue: <String>[]) as List;
                  final offlineCount = boxData.keys.where((k) => k.toString().startsWith('deck_')).length;

                  return Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.upload_file,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$uploadCount',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                                Text(
                                  'Uploads',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${favorites.length}',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                                Text(
                                  'Favorites',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.download,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$offlineCount',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                                Text(
                                  'Offline',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // My Uploads
          const Text(
            'My Uploads',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('decks')
                .where('ownerUid', isEqualTo: user.uid)
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.upload_file_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          ),
                          const SizedBox(height: 12),
                          const Text('No uploads yet'),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = data['title'] as String? ?? 'Untitled';
                  final status = data['status'] as String? ?? 'pending';

                  return Card(
                    child: ListTile(
                      leading: Icon(
                        status == 'approved'
                            ? Icons.check_circle
                            : status == 'rejected'
                                ? Icons.cancel
                                : Icons.pending,
                        color: status == 'approved'
                            ? Colors.green
                            : status == 'rejected'
                                ? Colors.red
                                : Colors.orange,
                      ),
                      title: Text(title),
                      subtitle: Text(status.toUpperCase()),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
