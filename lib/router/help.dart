// ─────────────────────────────────────────────────────────────────────────────
// HELPER — GoRouter refresh stream depuis Riverpod
// ─────────────────────────────────────────────────────────────────────────────
import 'package:afoso1/features/auth/presentation/providers/auth_notifier.dart';
import 'package:afoso1/features/auth/presentation/providers/auth_state.dart';
import 'package:afoso1/features/auth/presentation/providers/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(ProviderRef ref, AuthNotifier notifier) {
    ref.listen<AuthState>(authProvider, (_, __) {
      notifyListeners();
    });
  }
}
