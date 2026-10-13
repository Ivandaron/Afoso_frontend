import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/features/member/presentation/providers/member_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SituationBanner extends ConsumerWidget {
  const SituationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final situationAsync = ref.watch(memberSituationProvider);

    return situationAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (situation) {
        final (color, icon, actionLabel) = _data(situation.situation);

        return GestureDetector(
          onTap: () => context.go('/member/deposit'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        situation.situationLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        actionLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
              ],
            ),
          ),
        );
      },
    );
  }

  (Color, IconData, String) _data(String situation) {
    switch (situation) {
      case 'EN_RETARD':
        return (
          AppColors.danger,
          Icons.error_rounded,
          'Touchez pour régulariser',
        );
      case 'EN_AVANCE':
        return (
          const Color(0xFF7C3AED),
          Icons.rocket_launch_rounded,
          'Vous êtes en avance, continuez !',
        );
      case 'A_JOUR':
        return (
          AppColors.success,
          Icons.check_circle_rounded,
          'Aucun retard, félicitations',
        );
      default:
        return (
          AppColors.warning,
          Icons.pending_rounded,
          'Payez votre cotisation du mois',
        );
    }
  }
}
