import 'dart:ui';

import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/core/storage/secure_storage.dart';
import 'package:afoso1/features/auth/presentation/providers/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminShellScreen extends ConsumerStatefulWidget {
  final Widget child;
  final String currentLocation;

  const AdminShellScreen({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  @override
  ConsumerState<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends ConsumerState<AdminShellScreen> {
  final String _adminName = 'Admin';

  static const _tabs = [
    _Tab(
      label: 'Dashboard',
      shortLabel: 'Home',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      path: '/admin/dashboard',
    ),
    _Tab(
      label: 'Inscriptions',
      shortLabel: 'Inscriptions',
      icon: Icons.person_add_outlined,
      activeIcon: Icons.person_add_rounded,
      path: '/admin/registrations',
    ),
    _Tab(
      label: 'Membres',
      shortLabel: 'Membres',
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      path: '/admin/members',
    ),
    _Tab(
      label: 'Cagnottes',
      shortLabel: 'Cagnottes',
      icon: Icons.volunteer_activism_outlined,
      activeIcon: Icons.volunteer_activism_rounded,
      path: '/admin/solidarity',
    ),
    _Tab(
      label: 'Paramètres',
      shortLabel: 'Paramètres',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      path: '/admin/settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final activeIndex = _tabs.indexWhere(
      (tab) => widget.currentLocation.startsWith(tab.path),
    );
    final currentIndex = activeIndex >= 0 ? activeIndex : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                _buildSideRail(currentIndex),
                Expanded(child: widget.child),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: widget.child,
          bottomNavigationBar: _buildBottomNav(currentIndex),
        );
      },
    );
  }

  void _navigate(int index) {
    if (context.mounted) {
      context.go(_tabs[index].path);
    }
  }

  // ── SIDE RAIL (desktop/tablet) ─────────────────────────────────────────────
  Widget _buildSideRail(int activeIndex) {
    return Container(
      width: 230,
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AFOSO',
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Administration',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // Nav items
          ...List.generate(_tabs.length, (i) {
            final t = _tabs[i];
            final active = i == activeIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: InkWell(
                onTap: () => _navigate(i),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        active ? AppColors.primarySurface : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        active ? t.activeIcon : t.icon,
                        size: 20,
                        color:
                            active
                                ? AppColors.primary
                                : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.label,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w400,
                            color:
                                active
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (active)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const Spacer(),
          const Divider(color: AppColors.border, height: 1),

          // Profil admin
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(
                    _adminName.isNotEmpty ? _adminName[0].toUpperCase() : 'A',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _adminName,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Administrateur',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (!mounted) return;
                    context.go('/login');
                  },
                  icon: const Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                  tooltip: 'Déconnexion',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── BOTTOM NAV (mobile) ───────────────────────────────────────────────────
  Widget _buildBottomNav(int activeIndex) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final t = _tabs[i];
              final active = i == activeIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => _navigate(i),
                  splashColor: AppColors.primarySurface,
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        active ? t.activeIcon : t.icon,
                        size: 22,
                        color: active ? AppColors.primary : AppColors.textHint,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        t.shortLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w400,
                          color:
                              active ? AppColors.primary : AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: active ? 16 : 0,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  final String label;
  final String shortLabel;
  final IconData icon;
  final IconData activeIcon;
  final String path;

  const _Tab({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.activeIcon,
    required this.path,
  });
}
