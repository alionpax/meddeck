import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/repo/deck_repo.dart';
import '../../data/repo/user_repo.dart';
import '../library/library_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  final DeckRepo repo;
  const AuthGate({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    final userRepo = UserRepo();

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

        return FutureBuilder<String>(
          future: userRepo.ensureUserDoc(user).then((_) => userRepo.getRole(user.uid)),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final role = roleSnap.data ?? 'user';
            // ignore: avoid_print
            print('AUTHGATE uid=${user.uid} role=$role');

            final isAdmin = role == 'admin';
            return LibraryScreen(repo: repo, isAdmin: isAdmin);
          },
        );
      },
    );
  }
}
