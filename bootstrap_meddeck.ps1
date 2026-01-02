# This script creates folders and writes ALL Dart files automatically.
# Run it from the Flutter project root (where pubspec.yaml exists).

$ErrorActionPreference = "Stop"

function EnsureDir($p) {
  if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null }
}

function WriteFile($path, $content) {
  EnsureDir (Split-Path $path)
  Set-Content -Path $path -Value $content -Encoding UTF8
  Write-Host "Created $path"
}

if (!(Test-Path ".\pubspec.yaml")) {
  Write-Error "pubspec.yaml not found. Run this in your Flutter project root."
  exit 1
}

EnsureDir ".\lib\core"
EnsureDir ".\lib\data\models"
EnsureDir ".\lib\data\repo"
EnsureDir ".\lib\features\library"
EnsureDir ".\lib\features\deck"
EnsureDir ".\lib\features\viewer"
EnsureDir ".\lib\features\offline"
EnsureDir ".\lib\features\uploads"
EnsureDir ".\lib\widgets"

WriteFile ".\lib\main.dart" @'
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('offline');
  runApp(const MedDeckApp());
}
'@

WriteFile ".\lib\app.dart" @'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'data/repo/mock_deck_repo.dart';
import 'features/library/library_screen.dart';
import 'features/deck/deck_detail_screen.dart';
import 'features/viewer/slide_viewer_screen.dart';
import 'features/offline/offline_screen.dart';
import 'features/uploads/uploads_screen.dart';

final _repo = MockDeckRepo();

class MedDeckApp extends StatelessWidget {
  const MedDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: buildClinicalTheme(),
      routerConfig: GoRouter(
        routes: [
          ShellRoute(
            builder: (context, state, child) =>
                Scaffold(body: child, bottomNavigationBar: _Nav()),
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => LibraryScreen(repo: _repo),
                routes: [
                  GoRoute(
                    path: 'deck/:id',
                    builder: (c, s) => DeckDetailScreen(
                      repo: _repo,
                      deckId: s.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'viewer/:id',
                    builder: (c, s) => SlideViewerScreen(
                      repo: _repo,
                      deckId: s.pathParameters['id']!,
                      initialIndex:
                          int.tryParse(s.uri.queryParameters['i'] ?? '0') ?? 0,
                    ),
                  ),
                ],
              ),
              GoRoute(path: '/offline', builder: (_, __) => OfflineScreen(repo: _repo)),
              GoRoute(path: '/uploads', builder: (_, __) => const UploadsScreen()),
            ],
          ),
        ],
      ),
    );
  }
}

class _Nav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Library'),
        BottomNavigationBarItem(icon: Icon(Icons.download), label: 'Offline'),
        BottomNavigationBarItem(icon: Icon(Icons.upload_file), label: 'Uploads'),
      ],
    );
  }
}
'@

Write-Host "`nFiles created successfully."
Write-Host "Next run:"
Write-Host "  flutter pub get"
Write-Host "  flutter run"
