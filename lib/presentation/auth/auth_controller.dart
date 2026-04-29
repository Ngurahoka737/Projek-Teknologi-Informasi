import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../di/injection.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firebase_bootstrap.dart';
import 'auth_state.dart';

final authServiceProvider = Provider<AuthService>(
  (ref) => getIt<AuthService>(),
);

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.read(authServiceProvider));
  },
);

final firebaseBootstrapProvider = FutureProvider<void>((ref) async {
  await FirebaseBootstrap.initialize();
});

final authStateStreamProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges();
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authService) : super(const AuthState());

  final AuthService _authService;

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.login(email: email, password: password);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }

    state = state.copyWith(isLoading: false, errorMessage: null);
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.register(email: email, password: password);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }

    state = state.copyWith(isLoading: false, errorMessage: null);
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}
