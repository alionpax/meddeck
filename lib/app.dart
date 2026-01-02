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
            case 1: context.go('/'); break; // Search placeholder
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
