import 'dart:async';
import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/core/utils/validators.dart';
import 'package:afoso1/core/widgets/animations.dart';
import 'package:afoso1/core/widgets/custom_button.dart';
import 'package:afoso1/core/widgets/custom_text_field.dart';
import 'package:afoso1/core/widgets/loading_overlay.dart';
import 'package:afoso1/features/member/data/models/deposit.dart';
import 'package:afoso1/features/auth/data/models/PaymentStatusResponse.dart';
import 'package:afoso1/features/member/presentation/providers/deposit_list_tile.dart';
import 'package:afoso1/features/member/presentation/providers/member_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _paymentPhoneController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.orangeMoney;
  double _amount = 5000;
  final _amountController = TextEditingController(text: '5000');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _paymentPhoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleDeposit() async {
    if (_paymentPhoneController.text.trim().isEmpty) {
      _showSnack('Numéro de paiement requis', isError: true);
      return;
    }
    if (Validators.phone(_paymentPhoneController.text) != null) {
      _showSnack('Numéro invalide', isError: true);
      return;
    }
    final parsedAmount = double.tryParse(_amountController.text);
    if (parsedAmount == null || parsedAmount < 1) {
      _showSnack('Montant invalide (minimum 1 FCFA)', isError: true);
      return;
    }

    await ref
        .read(depositFormProvider.notifier)
        .initiateDeposit(
          InitiateDepositRequest(
            amount: parsedAmount,
            paymentPhone: _paymentPhoneController.text.trim(),
            paymentMethod: _paymentMethod.value,
          ),
        );

    final state = ref.read(depositFormProvider);
    if (mounted && state.status == DepositFormStatus.success) {
      _showDepositConfirmSheet(state.transaction!);
    } else if (mounted && state.status == DepositFormStatus.error) {
      _showSnack(state.error ?? 'Erreur', isError: true);
    }
  }

  void _showDepositConfirmSheet(DepositTransaction tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _PaymentConfirmSheet(
            transaction: tx,
            onClose: () {
              Navigator.pop(context);
              ref.read(depositFormProvider.notifier).reset();
              ref.invalidate(depositSummaryProvider);
              ref.invalidate(myDepositsProvider);
            },
          ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
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
    final formState = ref.watch(depositFormProvider);
    final depositsAsync = ref.watch(myDepositsProvider);
    final isLoading = formState.status == DepositFormStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cotisation mensuelle'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Nouvelle cotisation'),
            Tab(text: 'Historique'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Onglet 1 : Nouvelle cotisation ─────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carte info mois en cours
                FadeInDown(child: _CurrentMonthCard()),
                const SizedBox(height: 24),
                // Formulaire
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: Container(
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
                          'Détails du paiement',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Montant
                        AfosoTextField(
                          label: 'Montant (FCFA)',
                          hint: '5000',
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: false,
                          ),
                          prefixIcon: const Icon(
                            Icons.attach_money_rounded,
                            size: 20,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Méthode de paiement
                        AfosoSection(
                          title: 'MÉTHODE',
                          icon: Icons.payment_rounded,
                        ),
                        const SizedBox(height: 10),
                        ...PaymentMethod.values.map((method) {
                          final isSelected = _paymentMethod == method;
                          return GestureDetector(
                            onTap:
                                () => setState(() => _paymentMethod = method),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? AppColors.primarySurface
                                        : AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                  width: isSelected ? 2 : 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    method.emoji,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      method.label,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                        color:
                                            isSelected
                                                ? AppColors.primary
                                                : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
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
                        // Numéro de paiement
                        AfosoTextField(
                          label: 'Numéro de paiement',
                          hint: '6XX XXX XXX',
                          controller: _paymentPhoneController,
                          keyboardType: TextInputType.phone,
                          validator: Validators.phone,
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            size: 20,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 24),
                        AfosoButton(
                          label: 'Initier le paiement',
                          isLoading: isLoading,
                          onPressed: _handleDeposit,
                          icon: const Icon(Icons.send_rounded, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Onglet 2 : Historique ─────────────────────────────────────
          depositsAsync.when(
            loading:
                () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
            error:
                (e, _) => Center(
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
                        'Erreur de chargement',
                        style: GoogleFonts.dmSans(color: AppColors.danger),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(myDepositsProvider),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
            data:
                (deposits) =>
                    deposits.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.savings_outlined,
                                size: 56,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune cotisation',
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                        : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh:
                              () async => ref.invalidate(myDepositsProvider),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: deposits.length,
                            itemBuilder:
                                (_, i) => DepositListTile(deposit: deposits[i]),
                          ),
                        ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets internes
// ─────────────────────────────────────────────────────────────────────────────

class _CurrentMonthCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(depositSummaryProvider);
    return summaryAsync.when(
      loading:
          () => Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
      error: (_, __) => const SizedBox.shrink(),
      data:
          (summary) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.currentMonth.month,
                        style: GoogleFonts.dmSans(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${summary.currentMonth.total.toStringAsFixed(0)} FCFA cotisés',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${summary.currentMonth.depositCount} dépôt(s)',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _PaymentConfirmSheet extends StatefulWidget {
  final DepositTransaction transaction;
  final VoidCallback onClose;

  const _PaymentConfirmSheet({
    required this.transaction,
    required this.onClose,
  });

  @override
  State<_PaymentConfirmSheet> createState() => _PaymentConfirmSheetState();
}

class _PaymentConfirmSheetState extends State<_PaymentConfirmSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(36),
            ),
            child: const Icon(
              Icons.phone_android_rounded,
              color: AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Confirmez sur votre téléphone',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Un message de confirmation a été envoyé à\n${widget.transaction.paymentPhone}',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // Détails transaction
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _Row(
                  'Montant',
                  '${widget.transaction.amount.toStringAsFixed(0)} FCFA',
                ),
                const Divider(height: 20),
                _Row('Référence', widget.transaction.transactionReference),
                const Divider(height: 20),
                _Row('Méthode', widget.transaction.paymentMethod),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onClose,
            child: const Text('Compris, je vais confirmer'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
