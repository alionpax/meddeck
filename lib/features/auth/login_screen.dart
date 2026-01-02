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
