import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/features/admin/data/models/admin_model.dart';
import 'package:afoso1/features/admin/presentation/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class MemberContributionHistoryScreen extends ConsumerStatefulWidget {
  final int memberId;
  final String memberName;

  const MemberContributionHistoryScreen({
    super.key,
    required this.memberId,
    required this.memberName,
  });

  @override
  ConsumerState<MemberContributionHistoryScreen> createState() =>
      _MemberContributionHistoryScreenState();
}

class _MemberContributionHistoryScreenState
    extends ConsumerState<MemberContributionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(memberContributionHistoryProvider(widget.memberId).notifier)
          .load(widget.memberId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memberContributionHistoryProvider(widget.memberId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Détails - ${widget.memberName}'),
        actions: [
          IconButton(
            onPressed: () {
              ref
                  .read(
                    memberContributionHistoryProvider(widget.memberId).notifier,
                  )
                  .load(widget.memberId);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body:
          state.isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
              : state.error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.danger,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.error!,
                      style: GoogleFonts.dmSans(
                        color: AppColors.danger,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(
                              memberContributionHistoryProvider(
                                widget.memberId,
                              ).notifier,
                            )
                            .load(widget.memberId);
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
              : state.history == null
              ? const Center(child: Text('Aucun détail disponible'))
              : _MemberContributionHistoryContent(history: state.history!),
    );
  }
}

class _MemberContributionHistoryContent extends StatelessWidget {
  final MemberContributionHistory history;

  const _MemberContributionHistoryContent({required this.history});

  String _formatDate(String raw) {
    try {
      final parsed = DateTime.parse(raw);
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }

  String _formatAmount(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M FCFA';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K FCFA';
    }
    return '${value.toStringAsFixed(0)} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            title: 'Informations du membre',
            children: [
              _InfoItem(label: 'Nom', value: history.fullName),
              _InfoItem(label: 'Téléphone', value: history.phone),
              if (history.email != null)
                _InfoItem(label: 'Email', value: history.email!),
              if (history.matricule != null)
                _InfoItem(label: 'Matricule', value: history.matricule!),
              if (history.city != null)
                _InfoItem(label: 'Ville', value: history.city!),
              _InfoItem(label: 'Statut', value: history.status),
              _InfoItem(label: 'Actif', value: history.active ? 'Oui' : 'Non'),
              _InfoItem(
                label: 'Inscrit le',
                value: _formatDate(history.createdAt),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Résumé financier',
            children: [
              _InfoItem(
                label: 'Solde compte',
                value: _formatAmount(history.accountBalance),
                valueColor: AppColors.primary,
              ),
              _InfoItem(
                label: 'Total déposé',
                value: _formatAmount(history.totalDeposited),
                valueColor: AppColors.primary,
              ),
              _InfoItem(
                label: 'Total cotisé',
                value: _formatAmount(history.totalContributed),
                valueColor: AppColors.primary,
              ),
              _InfoItem(
                label: 'Dépôts complétés',
                value: history.totalCompletedPayments.toString(),
              ),
              _InfoItem(
                label: 'Dépôts en attente',
                value: history.totalPendingPayments.toString(),
              ),
              _InfoItem(
                label: 'Dépôts partiels',
                value: history.totalPartialPayments.toString(),
              ),
              _InfoItem(
                label: 'Dépôts en retard',
                value: history.totalLatePayments.toString(),
                valueColor: AppColors.warning,
              ),
              _InfoItem(
                label: 'Paiements anticipés',
                value: history.advancePaymentCount.toString(),
                valueColor: AppColors.primary,
              ),
              _InfoItem(
                label: 'Mois couverts en avance',
                value: history.totalAdvanceMonths.toString(),
                valueColor: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _HistorySection(
            title: 'Historique des dépôts',
            items: history.contributions,
            emptyMessage: 'Aucun dépôt trouvé',
            showDate: false,
            formatDate: _formatDate,
          ),
          const SizedBox(height: 16),
          _HistorySection(
            title: 'Tous les paiements',
            items: history.monthlyDeposits,
            emptyMessage: 'Aucun paiement trouvé',
            showDate: true,
            formatDate: _formatDate,
          ),
          if (history.missingMonths.isNotEmpty) ...[
            const SizedBox(height: 16),
            _MissingMonthsCard(missingMonths: history.missingMonths),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '$label :',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final String title;
  final List<MonthlyContribution> items;
  final String emptyMessage;
  final bool showDate;
  final String Function(String) formatDate;

  const _HistorySection({
    required this.title,
    required this.items,
    required this.emptyMessage,
    this.showDate = false,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                emptyMessage,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.textHint,
                ),
              ),
            )
          else
            Column(
              children:
                  items.map((item) {
                    final statusColor =
                        item.status == 'COMPLETED'
                            ? AppColors.success
                            : item.status == 'PENDING'
                            ? AppColors.warning
                            : AppColors.danger;
                    final displayText =
                        showDate ? formatDate(item.createdAt) : item.monthLabel;
                    final itemTitle = showDate ? 'Dépôt' : item.title;
                    final itemSubtitle =
                        showDate
                            ? (item.isAdvancePayment
                                ? item.advanceLabel
                                : (item.paidAmount > 0
                                    ? 'Dépôt effectué'
                                    : item.status))
                            : (item.paidAmount > 0
                                ? (item.isAdvancePayment
                                    ? '${item.advanceLabel} • ${item.paidAmount.toStringAsFixed(0)} FCFA'
                                    : 'Dépôt effectué • ${item.paidAmount.toStringAsFixed(0)} FCFA')
                                : item.status);
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              displayText,
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  itemTitle,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  itemSubtitle,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            showDate
                                ? item.amountLabel
                                : (item.paidAmount > 0
                                    ? item.amountLabel
                                    : '${item.amount.toStringAsFixed(0)} FCFA'),
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
        ],
      ),
    );
  }
}

class _MissingMonthsCard extends StatelessWidget {
  final List<MissingMonth> missingMonths;

  const _MissingMonthsCard({required this.missingMonths});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_outlined,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 10),
                Text(
                  'Mois manquants',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  missingMonths
                      .map(
                        (month) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            month.formattedMonth,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
