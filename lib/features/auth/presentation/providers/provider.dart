import 'package:afoso1/features/auth/data/models/auth_repository.dart';
import 'package:afoso1/features/auth/presentation/providers/auth_notifier.dart';
import 'package:afoso1/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
