import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/core/storage/secure_storage.dart';
import 'package:afoso1/core/network/api_client.dart';
import 'package:afoso1/core/widgets/animations.dart';
import 'package:afoso1/features/auth/presentation/providers/provider.dart';
import 'package:afoso1/features/admin/presentation/providers/admin_provider.dart';
import 'package:afoso1/features/member/presentation/providers/deposit_list_tile.dart';
import 'package:afoso1/features/member/presentation/providers/member_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class MemberDashboardScreen extends ConsumerStatefulWidget {
  const MemberDashboardScreen({super.key});

  @override
  ConsumerState<MemberDashboardScreen> createState() =>
      _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends ConsumerState<MemberDashboardScreen> {
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final name = await SecureStorageService.getUserName();
    if (mounted) setState(() => _userName = name ?? 'Membre');
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(depositSummaryProvider);
    final depositsAsync = ref.watch(myDepositsProvider);
    final fundAsync = ref.watch(activeFundProvider);
    final adminAlert = ref.watch(adminAlertProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(depositSummaryProvider);
          ref.invalidate(myDepositsProvider);
          ref.invalidate(activeFundProvider);
          await ref.read(adminAlertProvider.notifier).loadAlert();
        },
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: AppColors.white,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                  child: FadeInDown(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${_greeting()}, 👋',
                          style: GoogleFonts.dmSans(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userName,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Déconnexion',
                ),
              ],
            ),

            // ── Contenu ───────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Résumé financier ──────────────────────────────────────
                  summaryAsync.when(
                    loading: () => const _SummaryCardSkeleton(),
                    error:
                        (e, _) => _ErrorCard(
                          message: 'Impossible de charger le résumé',
                          onRetry: () => ref.invalidate(depositSummaryProvider),
                        ),
                    data:
                        (summary) =>
                            FadeInUp(child: _SummaryCard(summary: summary)),
                  ),
                  const SizedBox(height: 20),
                  // ── Message d’alerte admin ──────────────────────────────────────────────
                  if (adminAlert.isNotEmpty)
                    FadeInUp(
                      delay: const Duration(milliseconds: 100),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.warning.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                adminAlert,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // ── Cagnotte active ───────────────────────────────────────
                  fundAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data:
                        (fund) =>
                            fund != null
                                ? FadeInUp(
                                  delay: const Duration(milliseconds: 100),
                                  child: _ActiveFundBanner(fund: fund),
                                )
                                : const SizedBox.shrink(),
                  ),

                  // ── Actions rapides ────────────────────────────────────────
                  const SizedBox(height: 20),
                  FadeInUp(
                    delay: const Duration(milliseconds: 150),
                    child: Row(
                      children: [
                        _QuickAction(
                          icon: Icons.add_circle_outline_rounded,
                          label: 'Cotiser',
                          color: AppColors.primary,
                          onTap: () => context.go('/member/deposit'),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          icon: Icons.volunteer_activism_outlined,
                          label: 'Solidarité',
                          color: AppColors.success,
                          onTap: () => context.go('/member/solidarity'),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          icon: Icons.history_rounded,
                          label: 'Historique',
                          color: AppColors.warning,
                          onTap: () => context.go('/member/deposit'),
                        ),
                      ],
                    ),
                  ),

                  // ── Derniers dépôts ────────────────────────────────────────
                  const SizedBox(height: 24),
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mes cotisations',
                          style: GoogleFonts.dmSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/member/deposit'),
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
                  depositsAsync.when(
                    loading: () => const _DepositListSkeleton(),
                    error:
                        (e, _) => _ErrorCard(
                          message: 'Impossible de charger les cotisations',
                          onRetry: () => ref.invalidate(myDepositsProvider),
                        ),
                    data:
                        (deposits) =>
                            deposits.isEmpty
                                ? _EmptyState(
                                  icon: Icons.savings_outlined,
                                  message: 'Aucune cotisation enregistrée',
                                  actionLabel:
                                      'Effectuer ma première cotisation',
                                  onAction: () => context.go('/member/deposit'),
                                )
                                : Column(
                                  children:
                                      deposits
                                          .take(5)
                                          .map(
                                            (d) => FadeInLeft(
                                              child: DepositListTile(
                                                deposit: d,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                  ),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS INTERNES
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final dynamic summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Épargne totale',
            style: GoogleFonts.dmSans(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatAmount(summary.totalSaved)} FCFA',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryMiniStat(
                  label: 'Ce mois',
                  value: '${_formatAmount(summary.currentMonth.total)} F',
                  sub: '${summary.currentMonth.depositCount} dépôts',
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _SummaryMiniStat(
                  label: 'Mois dernier',
                  value: '${_formatAmount(summary.previousMonth.total)} F',
                  sub: summary.progression,
                  subColor:
                      summary.progression.startsWith('-')
                          ? Colors.redAccent
                          : Colors.greenAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }
}

class _SummaryMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color? subColor;

  const _SummaryMiniStat({
    required this.label,
    required this.value,
    this.sub,
    this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (sub != null)
            Text(
              sub!,
              style: GoogleFonts.dmSans(
                color: subColor ?? Colors.white70,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCardSkeleton extends StatelessWidget {
  const _SummaryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _ActiveFundBanner extends StatelessWidget {
  final dynamic fund;
  const _ActiveFundBanner({required this.fund});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/member/solidarity'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                color: AppColors.success,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cagnotte active 🟢',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    fund.title,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepositListSkeleton extends StatelessWidget {
  const _DepositListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 56, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.danger),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Réessayer',
              style: GoogleFonts.dmSans(
                fontSize: 12,
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

// Dans member_dashboard_screen.dart - Ajouter un indicateur
class _SyncStatusWidget extends ConsumerStatefulWidget {
  const _SyncStatusWidget({super.key});

  @override
  ConsumerState<_SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends ConsumerState<_SyncStatusWidget> {
  bool _isSyncing = false;
  bool _hasSynced = false;

  @override
  void initState() {
    super.initState();
    _checkSyncStatus();
  }

  Future<void> _checkSyncStatus() async {
    final memberId = await SecureStorageService.getUserId();
    if (memberId != null) {
      final response = await ApiClient.instance.get(
        '/api/member/sync-status/${int.parse(memberId)}',
      );
      final data = response.data['data'] as Map<String, dynamic>?;
      if (mounted) {
        setState(() {
          _hasSynced = data?['dataSynced'] == true;
        });
      }
    }
  }

  Future<void> _forceSync() async {
    setState(() => _isSyncing = true);
    try {
      final response = await ApiClient.instance.post('/api/member/sync-data');
      if (response.data['success'] == true) {
        setState(() => _hasSynced = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Données synchronisées avec succès!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSynced) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(_isSyncing ? Icons.sync : Icons.cloud_download, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isSyncing
                  ? 'Synchronisation de vos données historiques...'
                  : 'Synchronisez vos données d\'épargne',
              style: GoogleFonts.dmSans(fontSize: 13),
            ),
          ),
          if (!_isSyncing)
            TextButton(
              onPressed: _forceSync,
              child: const Text('SYNCHRONISER'),
            ),
        ],
      ),
    );
  }
}
