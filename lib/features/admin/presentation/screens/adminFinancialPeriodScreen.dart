import 'package:afoso1/core/widgets/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/admin_model.dart';
import '../providers/admin_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ÉCRAN ANALYSE FINANCIÈRE PAR PÉRIODE
// ─────────────────────────────────────────────────────────────────────────────
class AdminFinancialPeriodScreen extends ConsumerWidget {
  const AdminFinancialPeriodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodState = ref.watch(periodNotifierProvider);
    final overviewAsync = ref.watch(periodOverviewProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analyse financière'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(periodOverviewProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Sélecteur de période ───────────────────────────────────────
          _PeriodSelector(
            current: periodState.preset,
            onSelect:
                (preset) => ref
                    .read(periodNotifierProvider.notifier)
                    .selectPreset(preset),
            onCustom: () => _pickCustomRange(context, ref),
          ),

          // ── Plage de dates affichée ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.date_range_rounded,
                  size: 14,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_fmtDate(periodState.startDate)} → ${_fmtDate(periodState.endDate)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Contenu ────────────────────────────────────────────────────
          Expanded(
            child: overviewAsync.when(
              loading:
                  () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
              error:
                  (e, _) => _ErrorBanner(
                    msg: e.toString().replaceAll('Exception: ', ''),
                    onRetry: () => ref.invalidate(periodOverviewProvider),
                  ),
              data: (overview) => _OverviewBody(overview: overview),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
      builder:
          (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.primary),
            ),
            child: child!,
          ),
    );
    if (range != null) {
      ref
          .read(periodNotifierProvider.notifier)
          .selectCustom(range.start, range.end);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SÉLECTEUR DE PÉRIODE
// ─────────────────────────────────────────────────────────────────────────────
class _PeriodSelector extends StatelessWidget {
  final PeriodPreset current;
  final ValueChanged<PeriodPreset> onSelect;
  final VoidCallback onCustom;

  const _PeriodSelector({
    required this.current,
    required this.onSelect,
    required this.onCustom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...PeriodPreset.values.map(
              (preset) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Chip(
                  label: preset.label,
                  selected: current == preset,
                  onTap: () => onSelect(preset),
                ),
              ),
            ),
            _Chip(
              label: '📅 Personnalisé',
              selected: false,
              onTap: onCustom,
              icon: null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? icon;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CORPS PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────
class _OverviewBody extends StatelessWidget {
  final PeriodOverview overview;
  const _OverviewBody({required this.overview});

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenu = overview.totalRevenue;
    final cotisationPct =
        totalRevenu > 0 ? overview.totalMonthlyPayments / totalRevenu : 0.0;
    final inscriptionPct =
        totalRevenu > 0
            ? overview.totalRegistrationPayments / totalRevenu
            : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card revenus totaux ──────────────────────────────────────────
          FadeInDown(
            child: _GradientCard(
              icon: Icons.account_balance_rounded,
              label: 'Revenus totaux sur la période',
              value: '${_fmt(totalRevenu)} FCFA',
              sublabel:
                  '${overview.days} jours · ${overview.newMembers} nouveau${overview.newMembers > 1 ? 'x' : ''} membre${overview.newMembers > 1 ? 's' : ''}',
              gradient: const [AppColors.primary, Color(0xFF1565C0)],
            ),
          ),

          const SizedBox(height: 16),

          // ── Décomposition ────────────────────────────────────────────────
          Text(
            'Décomposition des revenus',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Cotisations mensuelles
          FadeInLeft(
            delay: const Duration(milliseconds: 100),
            child: _RevenueCard(
              icon: Icons.savings_rounded,
              label: 'Cotisations mensuelles',
              value: '${_fmt(overview.totalMonthlyPayments)} FCFA',
              percent: cotisationPct,
              color: AppColors.primary,
              description: 'Dépôts mensuels des membres sur la période',
            ),
          ),

          const SizedBox(height: 10),

          // Frais d'inscription
          FadeInLeft(
            delay: const Duration(milliseconds: 180),
            child: _RevenueCard(
              icon: Icons.how_to_reg_rounded,
              label: 'Frais d\'inscription',
              value: '${_fmt(overview.totalRegistrationPayments)} FCFA',
              percent: inscriptionPct,
              color: const Color(0xFF7C3AED),
              description: 'Paiements d\'inscription collectés sur la période',
            ),
          ),

          const SizedBox(height: 20),

          // ── Résumé activité ──────────────────────────────────────────────
          Text(
            'Activité sur la période',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Row(
              children: [
                Expanded(
                  child: _StatMiniCard(
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'Nouveaux membres',
                    value: '${overview.newMembers}',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatMiniCard(
                    icon: Icons.calendar_today_rounded,
                    label: 'Durée analysée',
                    value: '${overview.days}j',
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Répartition visuelle
          FadeInUp(
            delay: const Duration(milliseconds: 260),
            child: _RevenueBreakdownBar(
              cotisationPct: cotisationPct,
              inscriptionPct: inscriptionPct,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS COMPOSANTS
// ─────────────────────────────────────────────────────────────────────────────

class _GradientCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sublabel;
  final List<Color> gradient;

  const _GradientCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sublabel,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sublabel,
            style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double percent;
  final Color color;
  final String description;

  const _RevenueCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      description,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(percent * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatMiniCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueBreakdownBar extends StatelessWidget {
  final double cotisationPct;
  final double inscriptionPct;

  const _RevenueBreakdownBar({
    required this.cotisationPct,
    required this.inscriptionPct,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartition des revenus',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Barre composite
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                if (cotisationPct > 0)
                  Flexible(
                    flex: (cotisationPct * 100).round(),
                    child: Container(height: 14, color: AppColors.primary),
                  ),
                if (inscriptionPct > 0)
                  Flexible(
                    flex: (inscriptionPct * 100).round(),
                    child: Container(
                      height: 14,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Légende
          Row(
            children: [
              _LegendDot(color: AppColors.primary, label: 'Cotisations'),
              const SizedBox(width: 16),
              _LegendDot(color: const Color(0xFF7C3AED), label: 'Inscriptions'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.msg, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              msg,
              style: GoogleFonts.dmSans(color: AppColors.danger),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
