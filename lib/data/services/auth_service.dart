import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_bootstrap.dart';

class AuthService {
  FirebaseAuth? get _auth =>
      FirebaseBootstrap.isAvailable ? FirebaseAuth.instance : null;

  Stream<User?> authStateChanges() {
    final auth = _auth;
    if (auth == null) {
      return Stream<User?>.value(null);
    }
    return auth.authStateChanges();
  }

  User? currentUser() => _auth?.currentUser;

  Future<void> register({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw StateError(
        'Firebase belum dikonfigurasi. Tambahkan config Firebase terlebih dahulu.',
      );
    }

    await auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> login({required String email, required String password}) async {
    final auth = _auth;
    if (auth == null) {
      throw StateError(
        'Firebase belum dikonfigurasi. Tambahkan config Firebase terlebih dahulu.',
      );
    }

    await auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async {
    final auth = _auth;
    if (auth == null) return;

    await auth.signOut();
  }
}
