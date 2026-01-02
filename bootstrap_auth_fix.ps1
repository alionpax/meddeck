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

Ensure-Dir ".\lib\services"
Ensure-Dir ".\lib\features\auth"

# --- Auth service
Write-File ".\lib\services\auth_service.dart" @'
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signOut() async {
    // Ignore failures from GoogleSignIn if user logged in with email/password.
    try { await GoogleSignIn().signOut(); } catch (_) {}
    await _auth.signOut();
  }

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    final google = GoogleSignIn();
    final googleUser = await google.signIn();

    if (googleUser == null) {
      throw FirebaseAuthException(code: 'CANCELLED', message: 'Sign-in cancelled');
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }
}
'@

# --- Auth gate
Write-File ".\lib\features\auth\auth_gate.dart" @'
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/repo/deck_repo.dart';
import '../library/library_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  final DeckRepo repo;
  const AuthGate({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snap.data;
        if (user == null) {
          return const LoginScreen();
        }

        return LibraryScreen(repo: repo);
      },
    );
  }
}
'@

# --- Login screen
Write-File ".\lib\features\auth\login_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _friendlyError(String raw) {
    if (raw.contains('wrong-password') || raw.contains('invalid-credential')) return 'Incorrect email or password.';
    if (raw.contains('user-not-found')) return 'No account found for that email.';
    if (raw.contains('network-request-failed')) return 'Network error. Check your connection.';
    if (raw.contains('CANCELLED')) return 'Sign-in cancelled.';
    return 'Unable to sign in. Please try again.';
  }

  Future<void> _run(Future<void> Function() fn) async {
    setState(() { _loading = true; _error = null; });
    try {
      await fn();
      // AuthGate will transition automatically.
    } catch (e) {
      setState(() { _error = _friendlyError(e.toString()); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Text('MedDeck', style: t.titleLarge),
          const SizedBox(height: 4),
          Text('Educational slide library', style: t.bodySmall),
          const SizedBox(height: 24),

          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],

          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _loading ? null : () => _run(() async {
                await _auth.signInWithEmail(_email.text, _password.text);
              }),
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Sign in'),
            ),
          ),

          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : () => _run(() async {
                await _auth.signInWithGoogle();
              }),
              icon: const Icon(Icons.account_circle_outlined),
              label: const Text('Continue with Google'),
            ),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Divider(color: Theme.of(context).dividerColor)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('or'),
              ),
              Expanded(child: Divider(color: Theme.of(context).dividerColor)),
            ],
          ),

          const SizedBox(height: 8),
          TextButton(
            onPressed: _loading ? null : () => context.go('/signup'),
            child: const Text('Create an account'),
          ),

          const SizedBox(height: 16),
          Text('Educational use only. Not medical advice.', style: t.bodySmall),
        ],
      ),
    );
  }
}
'@

# --- Signup screen (must have const constructor)
Write-File ".\lib\features\auth\signup_screen.dart" @'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String _friendlyError(String raw) {
    if (raw.contains('email-already-in-use')) return 'That email is already registered.';
    if (raw.contains('invalid-email')) return 'Enter a valid email address.';
    if (raw.contains('weak-password')) return 'Password is too weak. Use at least 6 characters.';
    if (raw.contains('Passwords do not match')) return 'Passwords do not match.';
    return 'Unable to create account. Please try again.';
  }

  Future<void> _run(Future<void> Function() fn) async {
    setState(() { _loading = true; _error = null; });
    try {
      await fn();
      if (mounted) context.go('/'); // AuthGate will switch to Library
    } catch (e) {
      setState(() { _error = _friendlyError(e.toString()); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirm,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm password',
              border: OutlineInputBorder(),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],

          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _loading ? null : () => _run(() async {
                if (_password.text != _confirm.text) {
                  throw Exception('Passwords do not match');
                }
                await _auth.signUpWithEmail(_email.text, _password.text);
              }),
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create account'),
            ),
          ),

          const SizedBox(height: 12),
          TextButton(
            onPressed: _loading ? null : () => context.go('/'),
            child: const Text('Back to sign in'),
          ),
        ],
      ),
    );
  }
}
'@

# --- Patch app.dart to include AuthGate + Settings route
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
'@

Write-Host "`nAuth repaired. Next:"
Write-Host "  flutter pub get"
Write-Host "  flutter run"
