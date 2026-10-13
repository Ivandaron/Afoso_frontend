import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/core/widgets/animations.dart';
import 'package:afoso1/features/admin/data/admin_repository.dart';
import 'package:afoso1/features/admin/data/models/admin_model.dart';
import 'package:afoso1/features/admin/presentation/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminAdvancePaymentsScreen extends ConsumerWidget {
  const AdminAdvancePaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageAsync = ref.watch(advancePaymentsPageProvider);
    final statsAsync = ref.watch(advancePaymentStatsProvider);
    final topAsync = ref.watch(topAdvanceMembersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paiements anticipés'),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(advancePaymentsPageProvider);
              ref.invalidate(advancePaymentStatsProvider);
              ref.invalidate(topAdvanceMembersProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(advancePaymentsPageProvider);
          ref.invalidate(advancePaymentStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stats globales ─────────────────────────────────────
              statsAsync.when(
                loading: () => const _StatsSkeleton(),
                error: (_, __) => const SizedBox.shrink(),
                data:
                    (stats) =>
                        FadeInDown(child: _GlobalStatsCard(stats: stats)),
              ),
              const SizedBox(height: 20),

              // ── Top membres ────────────────────────────────────────
              topAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data:
                    (top) =>
                        top.isEmpty
                            ? const SizedBox.shrink()
                            : FadeInUp(child: _TopMembersCard(members: top)),
              ),
              const SizedBox(height: 20),

              // ── Filtres ────────────────────────────────────────────
              const _FilterBar(),
              const SizedBox(height: 12),

              // ── Liste paginée ──────────────────────────────────────
              pageAsync.when(
                loading: () => const _ListSkeleton(),
                error:
                    (e, _) => _ErrorState(
                      message: e.toString().replaceAll('Exception: ', ''),
                      onRetry:
                          () => ref.invalidate(advancePaymentsPageProvider),
                    ),
                data:
                    (page) =>
                        page.isEmpty
                            ? const _EmptyState()
                            : _PaymentsList(page: page),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STATS GLOBALES
// ═══════════════════════════════════════════════════════════════════════════

class _GlobalStatsCard extends StatelessWidget {
  final AdvancePaymentStats stats;

  const _GlobalStatsCard({required this.stats});

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
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
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Vue d\'ensemble',
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
            '${_fmt(stats.totalAdvanceAmount)} FCFA',
            style: GoogleFonts.dmSans(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total encaissé en avance',
            style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white60),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.people_outline,
                  value: '${stats.distinctMembers}',
                  label: 'Membres',
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(
                child: _MiniStat(
                  icon: Icons.calendar_month_outlined,
                  value: '${stats.totalAdvanceMonths}',
                  label: 'Mois cumulés',
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(
                child: _MiniStat(
                  icon: Icons.receipt_long_outlined,
                  value: '${stats.totalAdvancePayments}',
                  label: 'Transactions',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white60),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TOP MEMBRES
// ═══════════════════════════════════════════════════════════════════════════

class _TopMembersCard extends StatelessWidget {
  final List<TopAdvanceMember> members;

  const _TopMembersCard({required this.members});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFFFD700),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Top 10 prévoyants',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(members.length, (i) {
            final m = members[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _rankColor(i + 1).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _rankColor(i + 1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      m.fullName.isNotEmpty ? m.fullName : '—',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${m.totalMonthsInAdvance} mois',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _rankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return AppColors.textHint;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BARRE DE FILTRES
// ═══════════════════════════════════════════════════════════════════════════

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(advancePaymentsFilterProvider);
    final notifier = ref.read(advancePaymentsFilterProvider.notifier);
    final currentYear = DateTime.now().year;

    return Container(
      padding: const EdgeInsets.all(12),
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
              const Icon(
                Icons.filter_alt_outlined,
                size: 16,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 8),
              Text(
                'Filtres',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (filter.year != null || filter.month != null)
                TextButton(
                  onPressed: () => notifier.reset(),
                  child: Text(
                    'Réinitialiser',
                    style: GoogleFonts.dmSans(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _YearChip(
                  label: 'Toutes années',
                  selected: filter.year == null,
                  onTap: () => notifier.setYear(null),
                ),
                const SizedBox(width: 6),
                ...List.generate(3, (i) {
                  final y = currentYear - i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _YearChip(
                      label: '$y',
                      selected: filter.year == y,
                      onTap: () => notifier.setYear(y),
                    ),
                  );
                }),
                const SizedBox(width: 12),
                Container(width: 1, height: 24, color: AppColors.border),
                const SizedBox(width: 12),
                _YearChip(
                  label: 'Tous mois',
                  selected: filter.month == null,
                  onTap: () => notifier.setMonth(null),
                ),
                const SizedBox(width: 6),
                ...List.generate(12, (i) {
                  final m = i + 1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _YearChip(
                      label: _monthShort(m),
                      selected: filter.month == m,
                      onTap: () => notifier.setMonth(m),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthShort(int m) {
    const months = [
      '',
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    if (m < 1 || m > 12) return '';
    return months[m];
  }
}

class _YearChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _YearChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LISTE DES PAIEMENTS
// ═══════════════════════════════════════════════════════════════════════════

class _PaymentsList extends ConsumerWidget {
  final AdvancePaymentPage page;

  const _PaymentsList({required this.page});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(
            '${page.totalElements} paiement(s) — ${page.totalAdvanceMonths} mois cumulés',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ...page.payments.map(
          (p) => FadeInUp(child: _AdvancePaymentTile(payment: p)),
        ),
        if (page.totalPages > 1) ...[
          const SizedBox(height: 12),
          _PaginationBar(page: page),
        ],
      ],
    );
  }
}

class _AdvancePaymentTile extends StatelessWidget {
  final AdvancePayment payment;

  const _AdvancePaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.memberName ?? '—',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      payment.monthLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                    if (payment.monthsInAdvance > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '+${payment.monthsInAdvance} mois',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (payment.paymentDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Payé le ${_fmtDate(payment.paymentDate!)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${payment.paidAmount.toStringAsFixed(0)} F',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      payment.isCompleted
                          ? AppColors.successLight
                          : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  payment.isCompleted ? 'Complété' : payment.status,
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color:
                        payment.isCompleted
                            ? AppColors.success
                            : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAGINATION
// ═══════════════════════════════════════════════════════════════════════════

class _PaginationBar extends ConsumerWidget {
  final AdvancePaymentPage page;

  const _PaginationBar({required this.page});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(advancePaymentsFilterProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed:
              page.page > 0 ? () => notifier.setPage(page.page - 1) : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text(
          'Page ${page.page + 1} / ${page.totalPages}',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        IconButton(
          onPressed:
              page.page + 1 < page.totalPages
                  ? () => notifier.setPage(page.page + 1)
                  : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SKELETONS & ÉTATS
// ═══════════════════════════════════════════════════════════════════════════

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) => Container(
    height: 180,
    decoration: BoxDecoration(
      color: AppColors.border,
      borderRadius: BorderRadius.circular(18),
    ),
  );
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      4,
      (_) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 40),
    alignment: Alignment.center,
    child: Column(
      children: [
        const Icon(
          Icons.rocket_launch_outlined,
          size: 56,
          color: AppColors.textHint,
        ),
        const SizedBox(height: 12),
        Text(
          'Aucun paiement anticipé',
          style: GoogleFonts.dmSans(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
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
            message,
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.danger),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Réessayer')),
      ],
    ),
  );
}
