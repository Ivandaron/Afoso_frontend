import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/core/utils/validators.dart';
import 'package:afoso1/core/widgets/animations.dart';
import 'package:afoso1/core/widgets/custom_button.dart';
import 'package:afoso1/core/widgets/custom_text_field.dart';
import 'package:afoso1/features/auth/data/models/PaymentStatusResponse.dart';
import 'package:afoso1/features/member/data/models/solidarity.dart';
import 'package:afoso1/features/member/presentation/providers/member_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';


class SolidarityScreen extends ConsumerStatefulWidget {
  const SolidarityScreen({super.key});

  @override
  ConsumerState<SolidarityScreen> createState() => _SolidarityScreenState();
}

class _SolidarityScreenState extends ConsumerState<SolidarityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fundAsync = ref.watch(activeFundProvider);
    final allAsync = ref.watch(allFundsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cagnottes solidaires'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [Tab(text: 'Cagnotte active'), Tab(text: 'Historique')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // ── Cagnotte active ───────────────────────────────────────────────
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(activeFundProvider);
              ref.invalidate(allFundsProvider);
            },
            child: fundAsync.when(
              loading:
                  () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
              error: (_, __) => _NoActiveFund(),
              data:
                  (fund) =>
                      fund == null
                          ? _NoActiveFund()
                          : SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                FadeInDown(child: _FundDetailCard(fund: fund)),
                                const SizedBox(height: 20),
                                FadeInUp(
                                  delay: const Duration(milliseconds: 150),
                                  child: _ContributeForm(fund: fund),
                                ),
                              ],
                            ),
                          ),
            ),
          ),

          // ── Historique des cagnottes ─────────────────────────────────────
          allAsync.when(
            loading:
                () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
            error:
                (_, __) => Center(
                  child: Text(
                    'Erreur de chargement',
                    style: GoogleFonts.dmSans(color: AppColors.danger),
                  ),
                ),
            data:
                (funds) =>
                    funds.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.volunteer_activism_outlined,
                                size: 56,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune cagnotte',
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: funds.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 12),
                          itemBuilder:
                              (_, i) => _FundHistoryTile(fund: funds[i]),
                        ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _FundDetailCard extends StatelessWidget {
  final SolidarityFund fund;
  const _FundDetailCard({required this.fund});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header vert
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.volunteer_activism_rounded,
                    color: AppColors.success,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fund.title,
                        style: GoogleFonts.dmSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '● Active',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Contenu
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bénéficiaire
                if (fund.beneficiaryName != null) ...[
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Bénéficiaire',
                    value: fund.beneficiaryName!,
                  ),
                  const SizedBox(height: 12),
                ],
                if (fund.beneficiaryReason != null) ...[
                  _InfoRow(
                    icon: Icons.info_outline,
                    label: 'Motif',
                    value: fund.beneficiaryReason!,
                  ),
                  const SizedBox(height: 16),
                ],
                if (fund.description != null) ...[
                  Text(
                    fund.description!,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Progression
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Collecté',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${fund.collectedAmount.toStringAsFixed(0)} / ${fund.targetAmount.toStringAsFixed(0)} FCFA',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: fund.progressPercent,
                    minHeight: 10,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.success),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(fund.progressPercent * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      '${fund.contributionCount} contributeur(s)',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Montant de contribution fixe
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.attach_money_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Contribution: ${fund.contributionAmount.toStringAsFixed(0)} FCFA',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 8),
        Text(
          '$label : ',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContributeForm extends ConsumerStatefulWidget {
  final SolidarityFund fund;
  const _ContributeForm({required this.fund});

  @override
  ConsumerState<_ContributeForm> createState() => _ContributeFormState();
}

class _ContributeFormState extends ConsumerState<_ContributeForm> {
  final _phoneController = TextEditingController();
  PaymentMethod _method = PaymentMethod.orangeMoney;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _contribute() async {
    if (Validators.phone(_phoneController.text) != null) {
      _show('Numéro invalide', isError: true);
      return;
    }
    await ref
        .read(contributeProvider.notifier)
        .contribute(
          widget.fund.id,
          ContributeSolidarityRequest(
            paymentPhone: _phoneController.text.trim(),
            paymentMethod: _method.value,
          ),
        );
    final s = ref.read(contributeProvider);
    if (mounted && s.status == ContributeStatus.success) {
      _show('Contribution initiée ! Confirmez sur votre téléphone.');
      ref.invalidate(activeFundProvider);
    } else if (mounted && s.status == ContributeStatus.error) {
      _show(s.error ?? 'Erreur', isError: true);
    }
  }

  void _show(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contributeProvider);
    final isLoading = state.status == ContributeStatus.loading;
    final hasContributed = state.status == ContributeStatus.success;

    if (hasContributed) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Contribution envoyée !',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Confirmez le paiement sur votre téléphone.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contribuer à la cagnotte',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Méthode de paiement
          ...PaymentMethod.values.map((m) {
            final sel = _method == m;
            return GestureDetector(
              onTap: () => setState(() => _method = m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primarySurface : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel ? AppColors.primary : AppColors.border,
                    width: sel ? 2 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Text(m.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        m.label,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                          color:
                              sel ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (sel)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          AfosoTextField(
            label: 'Numéro de paiement',
            hint: '6XX XXX XXX',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(
              Icons.phone_outlined,
              size: 20,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 20),
          AfosoButton(
            label:
                'Contribuer ${widget.fund.contributionAmount.toStringAsFixed(0)} FCFA',
            isLoading: isLoading,
            onPressed: _contribute,
            icon: const Icon(Icons.volunteer_activism_outlined, size: 18),
          ),
        ],
      ),
    );
  }
}

class _NoActiveFund extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              size: 72,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 20),
            Text(
              'Pas de cagnotte active',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Aucune cagnotte solidaire n'est active en ce moment.\nL'admin en lancera une prochainement.",
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FundHistoryTile extends StatelessWidget {
  final SolidarityFund fund;
  const _FundHistoryTile({required this.fund});

  @override
  Widget build(BuildContext context) {
    final statusColor =
        fund.isActive
            ? AppColors.success
            : fund.status == 'DISBURSED'
            ? AppColors.primary
            : AppColors.textHint;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.volunteer_activism_outlined,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fund.title,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${fund.contributionCount} contributeur(s)',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${fund.collectedAmount.toStringAsFixed(0)} FCFA',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  fund.status,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
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
