import 'package:afoso1/core/widgets/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/admin_model.dart';
import '../providers/admin_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ÉCRAN CLASSEMENT ÉPARGNE PAR MEMBRE
// ─────────────────────────────────────────────────────────────────────────────
class AdminDepositsSummaryScreen extends ConsumerWidget {
  const AdminDepositsSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(depositsSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Épargne par membre'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(depositsSummaryProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: summaryAsync.when(
        loading: () => const _SummarySkeleton(),
        error:
            (e, _) => _ErrorState(
              message: e.toString().replaceAll('Exception: ', ''),
              onRetry: () => ref.invalidate(depositsSummaryProvider),
            ),
        data:
            (items) =>
                items.isEmpty ? _EmptyState() : _SummaryList(items: items),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LISTE
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryList extends StatelessWidget {
  final List<DepositsSummaryItem> items;
  const _SummaryList({required this.items});

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  String _fmtDate(String? raw) {
    if (raw == null) return '—';
    try {
      final d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Total général
    final grandTotal = items.fold(0.0, (s, i) => s + i.totalDeposits);
    final totalDeposits = items.fold(0, (s, i) => s + i.depositCount);

    return Column(
      children: [
        // ── Bandeau total ──────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total épargne',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${_fmt(grandTotal)} FCFA',
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nb. dépôts',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '$totalDeposits',
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Membres',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${items.length}',
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ── En-tête colonnes ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '#',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHint,
                  ),
                ),
              ),
              const Expanded(flex: 3, child: SizedBox()),
              SizedBox(
                width: 90,
                child: Text(
                  'Total',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHint,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  'Dép.',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHint,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),

        // ── Liste membres ──────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final rank = i + 1;
              final pct =
                  grandTotal > 0 ? item.totalDeposits / grandTotal : 0.0;

              return FadeInUp(
                delay: Duration(milliseconds: i * 30),
                child: _MemberDepositCard(
                  item: item,
                  rank: rank,
                  percent: pct,
                  fmtAmount: _fmt,
                  fmtDate: _fmtDate,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD MEMBRE
// ─────────────────────────────────────────────────────────────────────────────
class _MemberDepositCard extends StatelessWidget {
  final DepositsSummaryItem item;
  final int rank;
  final double percent;
  final String Function(double) fmtAmount;
  final String Function(String?) fmtDate;

  const _MemberDepositCard({
    required this.item,
    required this.rank,
    required this.percent,
    required this.fmtAmount,
    required this.fmtDate,
  });

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFFFD700); // or
    if (rank == 2) return const Color(0xFFC0C0C0); // argent
    if (rank == 3) return const Color(0xFFCD7F32); // bronze
    return AppColors.textHint;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rank <= 3 ? _rankColor.withOpacity(0.3) : AppColors.border,
          width: rank <= 3 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Rang
              SizedBox(
                width: 32,
                child: Text(
                  '#$rank',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _rankColor,
                  ),
                ),
              ),
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    item.isActive ? AppColors.primarySurface : AppColors.border,
                child: Text(
                  item.initials,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color:
                        item.isActive ? AppColors.primary : AppColors.textHint,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Nom + matricule
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.memberName.isNotEmpty ? item.memberName : '—',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.matricule != null)
                      Text(
                        item.matricule!,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
              // Montant
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${fmtAmount(item.totalDeposits)} FCFA',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '${item.depositCount} dépôt${item.depositCount > 1 ? 's' : ''}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 5,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                rank == 1
                    ? const Color(0xFFFFD700)
                    : rank == 2
                    ? const Color(0xFF90A4AE)
                    : rank == 3
                    ? const Color(0xFFCD7F32)
                    : AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Métadonnées
          Row(
            children: [
              if (item.lastDepositDate != null) ...[
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 11,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  'Dernier : ${fmtDate(item.lastDepositDate)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '${(percent * 100).toStringAsFixed(1)}% du total',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              // Badge actif/inactif
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      item.isActive ? AppColors.successLight : AppColors.border,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.isActive ? 'Actif' : 'Inactif',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color:
                        item.isActive ? AppColors.success : AppColors.textHint,
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

// ─────────────────────────────────────────────────────────────────────────────
// SKELETON / ÉTATS
// ─────────────────────────────────────────────────────────────────────────────
class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 8,
            itemBuilder:
                (_, i) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun dépôt enregistré',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

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
              message,
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
