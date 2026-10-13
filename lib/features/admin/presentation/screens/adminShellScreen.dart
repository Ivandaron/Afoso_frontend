import 'dart:ui';

import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/core/storage/secure_storage.dart';
import 'package:afoso1/features/admin/presentation/providers/admin_provider.dart';
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
  String _adminName = 'Admin';

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
  void initState() {
    super.initState();
    _loadAdminName();
  }

  Future<void> _loadAdminName() async {
    final name = await SecureStorageService.getUserName();
    if (!mounted) return;
    setState(() {
      if (name != null && name.trim().isNotEmpty) {
        _adminName = name.trim();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _tabs.indexWhere(
      (tab) => widget.currentLocation.startsWith(tab.path),
    );
    final currentIndex = activeIndex >= 0 ? activeIndex : 0;
    final pendingCount = ref.watch(pendingRegistrationsProvider).maybeWhen(
      data: (items) => items.length,
      orElse: () => 0,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                _buildSideRail(currentIndex, pendingCount),
                Expanded(child: widget.child),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: widget.child,
          bottomNavigationBar: _buildBottomNav(currentIndex, pendingCount),
        );
      },
    );
  }

  void _navigate(int index) {
    if (context.mounted) {
      context.go(_tabs[index].path);
    }
  }

  Widget _buildSideRail(int activeIndex, int pendingCount) {
    return Container(
      width: 230,
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
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
                Expanded(
                  child: Column(
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
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          ...List.generate(_tabs.length, (i) {
            final tab = _tabs[i];
            final active = i == activeIndex;
            final showBadge = i == 1 && pendingCount > 0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: InkWell(
                onTap: () => _navigate(i),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primarySurface : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            active ? tab.activeIcon : tab.icon,
                            size: 20,
                            color: active ? AppColors.primary : AppColors.textSecondary,
                          ),
                          if (showBadge)
                            Positioned(
                              right: -6,
                              top: -6,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    pendingCount > 9 ? '9+' : pendingCount.toString(),
                                    style: GoogleFonts.dmSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tab.label,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            color: active ? AppColors.primary : AppColors.textSecondary,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
                  child: Text(
                    _adminName,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
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

  Widget _buildBottomNav(int activeIndex, int pendingCount) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final active = i == activeIndex;
              final showBadge = i == 1 && pendingCount > 0;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _navigate(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primarySurface : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              active ? tab.activeIcon : tab.icon,
                              color: active ? AppColors.primary : AppColors.textHint,
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tab.shortLabel,
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                color: active ? AppColors.primary : AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                        if (showBadge)
                          Positioned(
                            right: 18,
                            top: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  pendingCount > 9 ? '9+' : pendingCount.toString(),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
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
