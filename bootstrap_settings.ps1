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

if (!(Test-Path ".\pubspec.yaml")) { throw "Run this from your Flutter project root (pubspec.yaml not found)." }

Ensure-Dir ".\lib\features\settings"

# --- Settings screen
Write-File ".\lib\features\settings\settings_screen.dart" @'
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Unknown';

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
'@

# --- Patch: add Settings route + remove floating logout button
Write-File ".\lib\app.dart" @'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'data/repo/mock_deck_repo.dart';
import 'features/auth/auth_gate.dart';
import 'features/auth/signup_screen.dart';
import 'features/deck/deck_detail_screen.dart';
import 'features/viewer/slide_viewer_screen.dart';
import 'features/offline/offline_screen.dart';
import 'features/uploads/uploads_screen.dart';
import 'features/settings/settings_screen.dart';

final _repo = MockDeckRepo();

class MedDeckApp extends StatelessWidget {
  const MedDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        ShellRoute(
          builder: (context, state, child) => _ScaffoldShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => AuthGate(repo: _repo),
              routes: [
                GoRoute(
                  path: 'deck/:id',
                  builder: (context, state) => DeckDetailScreen(
                    repo: _repo,
                    deckId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: 'viewer/:id',
                  builder: (context, state) => SlideViewerScreen(
                    repo: _repo,
                    deckId: state.pathParameters['id']!,
                    initialIndex: int.tryParse(state.uri.queryParameters['i'] ?? '0') ?? 0,
                  ),
                ),
              ],
            ),
            GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
            GoRoute(path: '/offline', builder: (context, state) => OfflineScreen(repo: _repo)),
            GoRoute(path: '/uploads', builder: (context, state) => const UploadsScreen()),
            GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'MedDeck',
      theme: buildClinicalTheme(),
      routerConfig: router,
    );
  }
}

class _ScaffoldShell extends StatelessWidget {
  final Widget child;
  const _ScaffoldShell({required this.child});

  int _indexForLocation(String loc) {
    if (loc.startsWith('/offline')) return 2;
    if (loc.startsWith('/uploads')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    final idx = _indexForLocation(loc);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/'); break;
            case 1: context.go('/'); break; // Search v2 placeholder
            case 2: context.go('/offline'); break;
            case 3: context.go('/uploads'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.search_outlined), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.download_outlined), label: 'Offline'),
          BottomNavigationBarItem(icon: Icon(Icons.upload_file_outlined), label: 'Uploads'),
        ],
      ),
    );
  }
}
'@

# --- Patch Library screen: add gear icon (top right)
Write-File ".\lib\features\library\library_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repo/deck_repo.dart';
import '../../widgets/deck_grid.dart';

class LibraryScreen extends StatelessWidget {
  final DeckRepo repo;
  const LibraryScreen({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: FutureBuilder(
        future: repo.listApprovedDecks(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final decks = snap.data!;
          if (decks.isEmpty) {
            return const Center(child: Text('No decks available.'));
          }
          return DeckGrid(
            decks: decks,
            onDeckTap: (deck) => context.go('/deck/${deck.id}'),
          );
        },
      ),
    );
  }
}
'@

Write-Host "`nDone. Run:"
Write-Host "  flutter run"
