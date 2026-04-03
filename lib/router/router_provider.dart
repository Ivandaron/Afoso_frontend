import 'package:afoso1/features/admin/presentation/screens/adminDashboardScreen.dart';
import 'package:afoso1/features/admin/presentation/screens/adminShellScreen.dart';
import 'package:afoso1/features/admin/presentation/screens/admin_member_screen.dart';
import 'package:afoso1/features/admin/presentation/screens/admin_solidarity_screen.dart';
import 'package:afoso1/features/admin/presentation/screens/registration_screen.dart';
import 'package:afoso1/features/auth/data/models/RegistrationResponse.dart';
import 'package:afoso1/features/auth/presentation/providers/auth_state.dart';
import 'package:afoso1/features/auth/presentation/providers/provider.dart';
import 'package:afoso1/features/auth/presentation/screens/ForgotPasswordScreen.dart';
import 'package:afoso1/features/auth/presentation/screens/login_screen.dart';
import 'package:afoso1/features/auth/presentation/screens/pending_approval_screen.dart';
import 'package:afoso1/features/auth/presentation/screens/register_screen.dart';
import 'package:afoso1/features/member/presentation/screens/depositScreen.dart';
import 'package:afoso1/features/member/presentation/screens/memberDashboardScreen.dart';
import 'package:afoso1/features/member/presentation/screens/memberShellScreen.dart';
import 'package:afoso1/features/member/presentation/screens/member_profile_Screen.dart';
import 'package:afoso1/features/member/presentation/screens/solidarityScreen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _GoRouterNotifier(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.unknown) return null;

      final path = state.uri.path;
      final isPublic =
          path.startsWith('/login') ||
          path.startsWith('/register') ||
          path.startsWith('/forgot-password') ||
          path.startsWith('/payment-pending');

      if (!authState.isAuthenticated) {
        return isPublic ? null : '/login';
      }
      if (authState.isAuthenticated &&
          isPublic &&
          !path.startsWith('/payment-pending')) {
        return authState.isAdmin ? '/admin/dashboard' : '/member/dashboard';
      }
      if (authState.isAdmin && path.startsWith('/member'))
        return '/admin/dashboard';
      if (authState.isMember && path.startsWith('/admin'))
        return '/member/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/payment-pending',
        builder:
            (_, state) => PaymentPendingScreen(
              registration: state.extra as RegistrationResponse,
            ),
      ),
      ShellRoute(
        builder: (_, __, child) => MemberShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/member/dashboard',
            builder: (_, __) => const MemberDashboardScreen(),
          ),
          GoRoute(
            path: '/member/deposit',
            builder: (_, __) => const DepositScreen(),
          ),
          GoRoute(
            path: '/member/solidarity',
            builder: (_, __) => const SolidarityScreen(),
          ),
          GoRoute(
            path: '/member/profile',
            builder: (_, __) => const MemberProfileScreen(),
          ),
        ],
      ),

      ShellRoute(
        builder: (_, __, child) => AdminShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (_, __) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/registrations',
            builder: (_, __) => const AdminRegistrationsScreen(),
          ),
          GoRoute(
            path: '/admin/members',
            builder: (_, __) => const AdminMembersScreen(),
          ),
          GoRoute(
            path: '/admin/solidarity',
            builder: (_, __) => const AdminSolidarityScreen(),
          ),
        ],
      ),
    ],

    errorBuilder:
        (context, state) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Page introuvable: ${state.uri}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
  );
});

class _GoRouterNotifier extends ChangeNotifier {
  _GoRouterNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}
