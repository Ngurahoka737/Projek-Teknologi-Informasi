import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../screens/main_navigation.dart';
import 'auth_controller.dart';
import 'login_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrapAsync = ref.watch(firebaseBootstrapProvider);
    final authState = ref.watch(authStateStreamProvider);

    return bootstrapAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('Firebase init gagal: $error'))),
      data: (_) {
        return authState.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) =>
              Scaffold(body: Center(child: Text('Auth error: $error'))),
          data: (User? user) {
            if (user == null) {
              return const LoginPage();
            }

            return const MainNavigation();
          },
        );
      },
    );
  }
}
