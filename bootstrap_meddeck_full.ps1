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

if (!(Test-Path ".\pubspec.yaml")) {
  throw "pubspec.yaml not found. Run this from the Flutter project root."
}

# Folders
Ensure-Dir ".\lib\core"
Ensure-Dir ".\lib\data\models"
Ensure-Dir ".\lib\data\repo"
Ensure-Dir ".\lib\features\library"
Ensure-Dir ".\lib\features\deck"
Ensure-Dir ".\lib\features\viewer"
Ensure-Dir ".\lib\features\offline"
Ensure-Dir ".\lib\features\uploads"
Ensure-Dir ".\lib\widgets"

# main.dart
Write-File ".\lib\main.dart" @'
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

# app.dart
Write-File ".\lib\app.dart" @'
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
    final router = GoRouter(
      routes: [
        ShellRoute(
          builder: (context, state, child) => _ScaffoldShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => LibraryScreen(repo: _repo),
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
            GoRoute(
              path: '/offline',
              builder: (context, state) => OfflineScreen(repo: _repo),
            ),
            GoRoute(
              path: '/uploads',
              builder: (context, state) => const UploadsScreen(),
            ),
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

class _ScaffoldShell extends StatefulWidget {
  final Widget child;
  const _ScaffoldShell({required this.child});

  @override
  State<_ScaffoldShell> createState() => _ScaffoldShellState();
}

class _ScaffoldShellState extends State<_ScaffoldShell> {
  int _indexForLocation(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/offline')) return 2;
    if (loc.startsWith('/uploads')) return 3;
    return 0;
  }

  void _onTap(int i, BuildContext context) {
    switch (i) {
      case 0: context.go('/'); break;
      case 1: context.go('/'); break; // search v2
      case 2: context.go('/offline'); break;
      case 3: context.go('/uploads'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final idx = _indexForLocation(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) => _onTap(i, context),
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

# theme.dart
Write-File ".\lib\core\theme.dart" @'
import 'package:flutter/material.dart';

ThemeData buildClinicalTheme() {
  const bg = Color(0xFFFAFAFA);
  const surface = Colors.white;
  const textPrimary = Color(0xFF111111);
  const textSecondary = Color(0xFF6B7280);
  const divider = Color(0xFFE5E7EB);
  const accent = Color(0xFF2563EB);

  final base = ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: accent));

  return base.copyWith(
    scaffoldBackgroundColor: bg,
    cardColor: surface,
    dividerColor: divider,
    textTheme: base.textTheme.copyWith(
      titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
      bodyMedium: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary),
      bodySmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: bg,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: accent,
      unselectedItemColor: textSecondary,
      backgroundColor: surface,
    ),
  );
}
'@

# models + repos + widgets + screens (the rest)
Write-File ".\lib\data\models\deck.dart" @'
class Deck {
  final String id;
  final String title;
  final String specialty;
  final int slideCount;
  final String source;
  final String coverImageUrl;
  final List<String> slideImageUrls;

  const Deck({
    required this.id,
    required this.title,
    required this.specialty,
    required this.slideCount,
    required this.source,
    required this.coverImageUrl,
    required this.slideImageUrls,
  });
}
'@

Write-File ".\lib\data\repo\deck_repo.dart" @'
import '../models/deck.dart';

abstract class DeckRepo {
  Future<List<Deck>> listApprovedDecks();
  Future<Deck?> getDeck(String id);
}
'@

Write-File ".\lib\data\repo\mock_deck_repo.dart" @'
import 'deck_repo.dart';
import '../models/deck.dart';

class MockDeckRepo implements DeckRepo {
  final List<Deck> _decks = [
    Deck(
      id: 'ecg101',
      title: 'ECG 101',
      specialty: 'Cardiology',
      slideCount: 24,
      source: 'Educational collection',
      coverImageUrl: 'https://images.unsplash.com/photo-1581594549595-35f6edc7b762?auto=format&fit=crop&w=1200&q=60',
      slideImageUrls: List.generate(24, (_) => 'https://images.unsplash.com/photo-1581594549595-35f6edc7b762?auto=format&fit=crop&w=1600&q=60'),
    ),
    Deck(
      id: 'abg',
      title: 'ABG Interpretation',
      specialty: 'Critical Care',
      slideCount: 18,
      source: 'Educational collection',
      coverImageUrl: 'https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=1200&q=60',
      slideImageUrls: List.generate(18, (_) => 'https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=1600&q=60'),
    ),
  ];

  @override
  Future<List<Deck>> listApprovedDecks() async => _decks;

  @override
  Future<Deck?> getDeck(String id) async {
    try { return _decks.firstWhere((d) => d.id == id); } catch (_) { return null; }
  }
}
'@

Write-File ".\lib\widgets\deck_card.dart" @'
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../data/models/deck.dart';

class DeckCard extends StatelessWidget {
  final Deck deck;
  final VoidCallback onTap;

  const DeckCard({super.key, required this.deck, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: deck.coverImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (c, _) => Container(color: Theme.of(context).dividerColor.withOpacity(0.4)),
                  errorWidget: (c, _, __) => Container(color: Theme.of(context).dividerColor.withOpacity(0.4)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(deck.title, style: t.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('${deck.specialty} • ${deck.slideCount} slides', style: t.bodySmall),
          ],
        ),
      ),
    );
  }
}
'@

Write-File ".\lib\widgets\deck_grid.dart" @'
import 'package:flutter/material.dart';
import '../data/models/deck.dart';
import 'deck_card.dart';

class DeckGrid extends StatelessWidget {
  final List<Deck> decks;
  final void Function(Deck deck) onDeckTap;

  const DeckGrid({super.key, required this.decks, required this.onDeckTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w >= 900 ? 4 : (w >= 600 ? 3 : 2);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: decks.length,
      itemBuilder: (context, i) => DeckCard(deck: decks[i], onTap: () => onDeckTap(decks[i])),
    );
  }
}
'@

Write-File ".\lib\widgets\slide_thumbnail_strip.dart" @'
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SlideThumbnailStrip extends StatelessWidget {
  final List<String> urls;
  final void Function(int index) onTap;

  const SlideThumbnailStrip({super.key, required this.urls, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => InkWell(
          onTap: () => onTap(i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: urls[i],
                fit: BoxFit.cover,
                placeholder: (c, _) => Container(color: Theme.of(context).dividerColor.withOpacity(0.4)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
'@

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
      appBar: AppBar(title: const Text('Library')),
      body: FutureBuilder(
        future: repo.listApprovedDecks(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final decks = snap.data!;
          if (decks.isEmpty) return const Center(child: Text('No decks available.'));
          return DeckGrid(decks: decks, onDeckTap: (deck) => context.go('/deck/${deck.id}'));
        },
      ),
    );
  }
}
'@

Write-File ".\lib\features\deck\deck_detail_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/repo/deck_repo.dart';
import '../../widgets/slide_thumbnail_strip.dart';

class DeckDetailScreen extends StatelessWidget {
  final DeckRepo repo;
  final String deckId;

  const DeckDetailScreen({super.key, required this.repo, required this.deckId});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(
        future: repo.getDeck(deckId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final deck = snap.data;
          if (deck == null) return const Center(child: Text('Deck not found.'));

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(imageUrl: deck.coverImageUrl, fit: BoxFit.cover),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(deck.title, style: t.titleLarge),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${deck.specialty}\n${deck.slideCount} slides\nSource: ${deck.source}',
                  style: t.bodySmall,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton(
                  onPressed: () => context.go('/viewer/${deck.id}?i=0'),
                  child: const Text('Preview slides'),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Offline download: next step.')),
                    );
                  },
                  child: const Text('Download offline'),
                ),
              ),
              const SizedBox(height: 16),
              SlideThumbnailStrip(
                urls: deck.slideImageUrls.take(24).toList(),
                onTap: (i) => context.go('/viewer/${deck.id}?i=$i'),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
'@

Write-File ".\lib\features\viewer\slide_viewer_screen.dart" @'
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/repo/deck_repo.dart';

class SlideViewerScreen extends StatefulWidget {
  final DeckRepo repo;
  final String deckId;
  final int initialIndex;

  const SlideViewerScreen({super.key, required this.repo, required this.deckId, required this.initialIndex});

  @override
  State<SlideViewerScreen> createState() => _SlideViewerScreenState();
}

class _SlideViewerScreenState extends State<SlideViewerScreen> {
  late final PageController _controller;
  bool _uiVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleUi() => setState(() => _uiVisible = !_uiVisible);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.repo.getDeck(widget.deckId),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final deck = snap.data;
        if (deck == null) return const Scaffold(body: Center(child: Text('Deck not found.')));

        return Scaffold(
          backgroundColor: const Color(0xFF0B0B0B),
          body: Stack(
            children: [
              GestureDetector(
                onTap: _toggleUi,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: deck.slideImageUrls.length,
                  itemBuilder: (context, index) {
                    return InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: CachedNetworkImage(
                          imageUrl: deck.slideImageUrls[index],
                          fit: BoxFit.contain,
                          placeholder: (c, _) => const CircularProgressIndicator(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_uiVisible)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        const Spacer(),
                        ValueListenableBuilder(
                          valueListenable: _controller,
                          builder: (context, _, __) {
                            final page = (_controller.hasClients && _controller.page != null)
                                ? _controller.page!.round()
                                : widget.initialIndex;
                            return Text(
                              '${page + 1} / ${deck.slideImageUrls.length}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
'@

Write-File ".\lib\features\offline\offline_screen.dart" @'
import 'package:flutter/material.dart';
import '../../data/repo/deck_repo.dart';

class OfflineScreen extends StatelessWidget {
  final DeckRepo repo;
  const OfflineScreen({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBar(title: Text('Offline')),
      body: Center(child: Text('Offline downloads will appear here.')),
    );
  }
}
'@

Write-File ".\lib\features\uploads\uploads_screen.dart" @'
import 'package:flutter/material.dart';

class UploadsScreen extends StatelessWidget {
  const UploadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBar(title: Text('Uploads')),
      body: Center(child: Text('Upload + My Uploads: next step.')),
    );
  }
}
'@

Write-Host "`nDone. Next:"
Write-Host "  flutter pub get"
Write-Host "  flutter run"
