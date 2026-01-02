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
