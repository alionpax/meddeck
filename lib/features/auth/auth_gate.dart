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
