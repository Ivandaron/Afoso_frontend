import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/features/auth/presentation/providers/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class MemberShellScreen extends ConsumerStatefulWidget {
  final Widget child;
  const MemberShellScreen({super.key, required this.child});

  @override
  ConsumerState<MemberShellScreen> createState() => _MemberShellScreenState();
}

class _MemberShellScreenState extends ConsumerState<MemberShellScreen> {
  int _currentIndex = 0;

  final _tabs = const [
    _NavTab(
      label: 'Accueil',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      path: '/member/dashboard',
    ),
    _NavTab(
      label: 'Cotisation',
      icon: Icons.savings_outlined,
      activeIcon: Icons.savings_rounded,
      path: '/member/deposit',
    ),
    _NavTab(
      label: 'Solidarité',
      icon: Icons.volunteer_activism_outlined,
      activeIcon: Icons.volunteer_activism_rounded,
      path: '/member/solidarity',
    ),
    _NavTab(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      path: '/member/profile',
    ),
  ];

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    context.go(_tabs[index].path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
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
                final tab = _tabs[i];
                final isActive = i == _currentIndex;

                return Expanded(
                  child: InkWell(
                    onTap: () => _onTap(i),
                    splashColor: AppColors.primarySurface,
                    highlightColor: Colors.transparent,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder:
                                (child, anim) =>
                                    ScaleTransition(scale: anim, child: child),
                            child: Icon(
                              isActive ? tab.activeIcon : tab.icon,
                              key: ValueKey('${tab.label}_$isActive'),
                              size: 24,
                              color:
                                  isActive
                                      ? AppColors.primary
                                      : AppColors.textHint,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tab.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 10.5,
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w400,
                              color:
                                  isActive
                                      ? AppColors.primary
                                      : AppColors.textHint,
                              letterSpacing: 0,
                            ),
                          ),
                          // Indicateur actif
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isActive ? 20 : 0,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
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
      ),
    );
  }
}

class _NavTab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;

  const _NavTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
  });
}
