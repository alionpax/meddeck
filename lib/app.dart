import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme.dart';

import 'data/repo/deck_repo.dart';
import 'data/repo/firestore_deck_repo.dart';

import 'features/auth/auth_gate.dart';
import 'features/auth/signup_screen.dart';

import 'features/deck/deck_detail_screen.dart';
import 'features/viewer/slide_viewer_screen.dart';

import 'features/offline/offline_screen.dart';
import 'features/uploads/uploads_screen.dart';
import 'features/settings/settings_screen.dart';

import 'features/review/review_screen.dart';

// ✅ Use Firestore repo app-wide so list + open deck use the same source.
final DeckRepo _repo = FirestoreDeckRepo();

class MedDeckApp extends StatelessWidget {
  const MedDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        ShellRoute(
          builder: (context, state, child) => _ScaffoldShell(child: child),
          routes: [
            // Home: AuthGate (Login -> Library)
            GoRoute(
              path: '/',
              builder: (context, state) => AuthGate(repo: _repo),
              routes: [
                GoRoute(
                  path: 'deck/:id',
                  builder: (context, state) {
                    final idx = int.tryParse(state.uri.queryParameters['i'] ?? '0') ?? 0;
                    return DeckDetailScreen(
                      repo: _repo,
                      deckId: state.pathParameters['id']!,
                      initialIndex: idx,
                    );
                  },
                ),
                GoRoute(
                  path: 'viewer/:id',
                  pageBuilder: (context, state) {
                    final idx = int.tryParse(state.uri.queryParameters['i'] ?? '0') ?? 0;
                    return CustomTransitionPage(
                      key: state.pageKey,
                      child: SlideViewerScreen(
                        repo: _repo,
                        deckId: state.pathParameters['id']!,
                        initialIndex: idx,
                      ),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
                        return FadeTransition(
                          opacity: curve,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curve),
                            child: child,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),

            // ✅ Admin review route (absolute path)
            GoRoute(
              path: '/review',
              builder: (context, state) => ReviewScreen(
                repo: FirestoreDeckRepo(), // ✅ use same repo
              ),
            ),

            // Auth
            GoRoute(
              path: '/signup',
              builder: (context, state) => const SignupScreen(),
            ),

            // Tabs
            GoRoute(
              path: '/offline',
              builder: (context, state) => OfflineScreen(repo: _repo),
            ),
            GoRoute(
              path: '/uploads',
              builder: (context, state) => const UploadsScreen(),
            ),

            // Settings
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    );

    // Listen to Hive box 'offline' for persisted theme preference.
    final box = Hive.box('offline');

    return ValueListenableBuilder(
      valueListenable: box.listenable(keys: ['theme']),
      builder: (context, _, __) {
        final choice = box.get('theme', defaultValue: 'medical') as String; // default to Medical Atlas for demo
        final theme = choice == 'medical' ? buildMedicalTheme() : buildPlayfulTheme();

        return MaterialApp.router(
          title: 'MedDeck',
          theme: theme,
          routerConfig: router,
        );
      },
    );
  }
}

class _ScaffoldShell extends StatelessWidget {
  final Widget child;
  const _ScaffoldShell({required this.child});

  int _indexForLocation(String loc) {
    if (loc.startsWith('/offline')) return 1;
    if (loc.startsWith('/uploads')) return 2;
    return 0; // Library (and other routes)
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
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/offline');
              break;
            case 2:
              context.go('/uploads');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download_outlined),
            label: 'Offline',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file_outlined),
            label: 'Uploads',
          ),
        ],
      ),
    );
  }
}
