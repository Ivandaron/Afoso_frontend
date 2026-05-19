import 'package:afoso1/core/widgets/animations.dart';
import 'package:afoso1/features/admin/presentation/screens/adminFinancialPeriodScreen.dart';
import 'package:afoso1/features/auth/presentation/providers/provider.dart';
import 'package:afoso1/features/member/presentation/providers/member_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/admin_provider.dart';
import 'admin_deposits_summary_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final pendingAsync = ref.watch(pendingRegistrationsProvider);
    final fundAsync = ref.watch(activeFundProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(dashboardStatsProvider);
              ref.invalidate(pendingRegistrationsProvider);
              ref.invalidate(activeFundProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
          ),
          IconButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Déconnexion'),
                      content: const Text('Voulez-vous vous déconnecter ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Se déconnecter'),
                        ),
                      ],
                    ),
              );

              if (confirm == true) {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(pendingRegistrationsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stats cards ─────────────────────────────────────────────
              statsAsync.when(
                loading: () => const _StatsGridSkeleton(),
                error:
                    (e, _) => _ErrorBanner(
                      msg: 'Erreur de chargement des statistiques',
                      onRetry: () => ref.invalidate(dashboardStatsProvider),
                    ),
                data: (stats) => FadeInDown(child: _StatsGrid(stats: stats)),
              ),
              const SizedBox(height: 24),

              // ── Inscriptions en attente ──────────────────────────────────
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Inscriptions en attente',
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/admin/registrations'),
                      child: Text(
                        'Voir tout',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              pendingAsync.when(
                loading: () => const _ListSkeleton(count: 3),
                error: (_, __) => const SizedBox.shrink(),
                data:
                    (list) =>
                        list.isEmpty
                            ? _EmptyCard(
                              icon: Icons.check_circle_outline,
                              message: 'Aucune inscription en attente',
                              color: AppColors.success,
                            )
                            : Column(
                              children:
                                  list
                                      .take(3)
                                      .map(
                                        (r) => FadeInLeft(
                                          child: _PendingRegistrationTile(
                                            registration: r,
                                            onApprove: () async {
                                              final ok = await ref
                                                  .read(
                                                    registrationActionProvider
                                                        .notifier,
                                                  )
                                                  .approve(r.id);
                                              if (ok && context.mounted) {
                                                ref.invalidate(
                                                  pendingRegistrationsProvider,
                                                );
                                                ref.invalidate(
                                                  dashboardStatsProvider,
                                                );
                                                _showSnack(
                                                  context,
                                                  'Inscription approuvée ✅',
                                                );
                                              }
                                            },
                                            onReject:
                                                () => _showRejectDialog(
                                                  context,
                                                  ref,
                                                  r.id,
                                                ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
              ),

              const SizedBox(height: 24),

              // ── Cagnotte solidaire ────────────────────────────────────────
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cagnotte solidaire',
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/admin/solidarity'),
                      child: Text(
                        'Gérer',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FadeInUp(
                delay: const Duration(milliseconds: 250),
                child: fundAsync.when(
                  loading: () => const _ListSkeleton(count: 1),
                  error:
                      (_, __) => _EmptyCard(
                        icon: Icons.volunteer_activism_outlined,
                        message: 'Aucune cagnotte active',
                        color: AppColors.textHint,
                        actionLabel: 'Créer une cagnotte',
                        onAction: () => context.go('/admin/solidarity'),
                      ),
                  data:
                      (fund) =>
                          fund == null
                              ? _EmptyCard(
                                icon: Icons.volunteer_activism_outlined,
                                message: 'Aucune cagnotte active',
                                color: AppColors.textHint,
                                actionLabel: 'Créer une cagnotte',
                                onAction: () => context.go('/admin/solidarity'),
                              )
                              : _AdminFundCard(fund: fund),
                ),
              ),

              const SizedBox(height: 24),

              // ── Accès rapide analyses ─────────────────────────────────────
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: Text(
                  'Analyses',
                  style: GoogleFonts.dmSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                delay: const Duration(milliseconds: 340),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickAccessCard(
                        icon: Icons.bar_chart_rounded,
                        title: 'Analyse\nfinancière',
                        subtitle: 'Par période',
                        color: AppColors.primary,
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => const AdminFinancialPeriodScreen(),
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAccessCard(
                        icon: Icons.leaderboard_rounded,
                        title: 'Classement\népargne',
                        subtitle: 'Membres',
                        color: const Color(0xFF7C3AED),
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => const AdminDepositsSummaryScreen(),
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRejectDialog(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Rejeter l\'inscription',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Veuillez indiquer le motif du rejet.',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Motif du rejet...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Rejeter'),
              ),
            ],
          ),
    );

    if (ok == true && reasonCtrl.text.trim().isNotEmpty) {
      final success = await ref
          .read(registrationActionProvider.notifier)
          .reject(id, reason: reasonCtrl.text.trim());
      if (success && context.mounted) {
        ref.invalidate(pendingRegistrationsProvider);
        _showSnack(context, 'Inscription rejetée');
      }
    }
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS GRID
// ─────────────────────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final dynamic stats;
  const _StatsGrid({required this.stats});

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    // Montant réel des frais d'inscription depuis /registration-fees/total
    final registrationRevenue = stats.totalRegistrationFees;

    final cards = [
      _StatData(
        'Épargne totale',
        '${_fmt(stats.totalDeposits)} FCFA',
        Icons.account_balance_wallet_rounded,
        AppColors.primary,
        null,
      ),
      _StatData(
        'Membres actifs',
        '${stats.activeMembers}',
        Icons.people_rounded,
        AppColors.success,
        null,
      ),
      _StatData(
        'Revenus\ninscriptions',
        '${_fmt(registrationRevenue)} FCFA',
        Icons.how_to_reg_rounded,
        const Color(0xFF7C3AED), // violet
        null,
      ),
      _StatData(
        'Inscriptions\nen attente',
        '${stats.pendingRegistrations}',
        Icons.pending_actions_rounded,
        stats.pendingRegistrations > 0 ? AppColors.warning : AppColors.success,
        stats.pendingRegistrations > 0 ? 'À traiter' : null,
      ),
      _StatData(
        'Transactions\néchecs',
        '${stats.failedTransactions}',
        Icons.error_outline_rounded,
        stats.failedTransactions > 0 ? AppColors.danger : AppColors.success,
        null,
      ),
    ];

    return Column(
      children: [
        // Ligne 1 : 2 grandes stats (épargne + membres)
        Row(
          children: [
            Expanded(child: _StatCard(data: cards[0])),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(data: cards[1])),
          ],
        ),
        const SizedBox(height: 12),
        // Ligne 2 : 3 stats (revenus inscriptions, en attente, échecs)
        Row(
          children: [
            for (int i = 2; i < cards.length; i++) ...[
              if (i > 2) const SizedBox(width: 8),
              Expanded(child: _StatCard(data: cards[i], compact: true)),
            ],
          ],
        ),
      ],
    );
  }
}

class _StatData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? badge;
  const _StatData(this.title, this.value, this.icon, this.color, this.badge);
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  final bool compact;
  const _StatCard({required this.data, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: compact ? 30 : 36,
                height: compact ? 30 : 36,
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  data.icon,
                  color: data.color,
                  size: compact ? 15 : 18,
                ),
              ),
              if (data.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data.badge!,
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: data.color,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            data.value,
            style: GoogleFonts.dmSans(
              fontSize: compact ? 16 : 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.title,
            style: GoogleFonts.dmSans(
              fontSize: compact ? 10 : 11,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// dashboard_stats_enhanced.dart - À intégrer dans adminDashboardScreen.dart

class _EnhancedStatsGrid extends StatelessWidget {
  final dynamic stats;
  final double previousPeriodTotal;

  const _EnhancedStatsGrid({
    required this.stats,
    required this.previousPeriodTotal,
  });

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  double _getVariation(double current, double previous) {
    if (previous == 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final totalDeposits = stats.totalDeposits;
    final variation = _getVariation(totalDeposits, previousPeriodTotal);
    final isPositive = variation >= 0;

    return Column(
      children: [
        // Carte principale - Épargne totale avec variation
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isPositive ? AppColors.success : AppColors.danger)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPositive ? Icons.trending_up : Icons.trending_down,
                          size: 14,
                          color:
                              isPositive ? AppColors.success : AppColors.danger,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${variation.abs().toStringAsFixed(1)}%',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color:
                                isPositive
                                    ? AppColors.success
                                    : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Épargne totale',
                style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '${_fmt(totalDeposits)} FCFA',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        // Grille des autres stats
        Row(
          children: [
            _MiniStatCard(
              icon: Icons.people_rounded,
              label: 'Membres actifs',
              value: '${stats.activeMembers}',
              color: AppColors.success,
              previousValue: stats.previousActiveMembers,
            ),
            const SizedBox(width: 10),
            _MiniStatCard(
              icon: Icons.how_to_reg_rounded,
              label: 'Revenus inscriptions',
              value: '${_fmt(stats.totalRegistrationFees)} FCFA',
              color: const Color(0xFF7C3AED),
              previousValue: stats.previousRegistrationFees,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _MiniStatCard(
              icon: Icons.pending_actions_rounded,
              label: 'En attente',
              value: '${stats.pendingRegistrations}',
              color:
                  stats.pendingRegistrations > 0
                      ? AppColors.warning
                      : AppColors.success,
              previousValue: stats.previousPendingRegistrations,
            ),
            const SizedBox(width: 10),
            _MiniStatCard(
              icon: Icons.error_outline_rounded,
              label: 'Transactions échouées',
              value: '${stats.failedTransactions}',
              color:
                  stats.failedTransactions > 0
                      ? AppColors.danger
                      : AppColors.success,
              previousValue: stats.previousFailedTransactions,
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double? previousValue;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.previousValue,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
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
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const Spacer(),
                if (previousValue != null)
                  _VariationBadge(current: value, previous: previousValue!),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VariationBadge extends StatelessWidget {
  final String current;
  final double previous;

  const _VariationBadge({required this.current, required this.previous});

  @override
  Widget build(BuildContext context) {
    // Simplifié - à adapter selon vos besoins
    return const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PENDING REGISTRATION TILE
// ─────────────────────────────────────────────────────────────────────────────
class _PendingRegistrationTile extends StatelessWidget {
  final dynamic registration;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingRegistrationTile({
    required this.registration,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  registration.firstName.isNotEmpty
                      ? registration.firstName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      registration.fullName,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      registration.phone,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'En attente',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          if (registration.city != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  registration.city,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Rejeter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approuver'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminFundCard extends StatelessWidget {
  final dynamic fund;
  const _AdminFundCard({required this.fund});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.volunteer_activism_rounded,
            color: AppColors.success,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fund.title,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${fund.collectedAmount.toStringAsFixed(0)} / ${fund.targetAmount.toStringAsFixed(0)} FCFA',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(fund.progressPercent * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
              Text(
                '${fund.contributionCount} contrib.',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACCESS CARD
// ─────────────────────────────────────────────────────────────────────────────
class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Voir',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios_rounded, size: 11, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS GRID SKELETON
// ─────────────────────────────────────────────────────────────────────────────
class _StatsGridSkeleton extends StatelessWidget {
  const _StatsGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: List.generate(
        4,
        (_) => Container(
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  final int count;
  const _ListSkeleton({required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyCard({
    required this.icon,
    required this.message,
    required this.color,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.msg, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.danger),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Réessayer',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
