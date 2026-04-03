import 'package:afoso1/core/storage/secure_storage.dart';
import 'package:afoso1/features/auth/data/models/auth_repository.dart';
import 'package:afoso1/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _checkAuthStatus();
  }

  /// Vérifie si l'utilisateur est déjà connecté au démarrage
  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await SecureStorageService.isLoggedIn();

    if (isLoggedIn) {
      final role = await SecureStorageService.getRole();
      final name = await SecureStorageService.getUserName();
      final phone = await SecureStorageService.getUserPhone();

      state = AuthState(
        status: AuthStatus.authenticated,
        role: role,
        userName: name,
        userPhone: phone,
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// 🔐 Connexion
  Future<bool> login({required String phone, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authData = await _repository.login(
        phone: phone,
        password: password,
      );

      state = AuthState(
        status: AuthStatus.authenticated,
        role: authData.role,
        userName: authData.fullName,
        userPhone: authData.phone ?? phone,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// 🚪 Déconnexion
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Effacer le message d'erreur
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
