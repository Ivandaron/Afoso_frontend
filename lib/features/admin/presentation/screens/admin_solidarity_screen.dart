import 'package:afoso1/core/widgets/animations.dart';
import 'package:afoso1/core/widgets/custom_button.dart';
import 'package:afoso1/core/widgets/custom_text_field.dart';
import 'package:afoso1/core/widgets/loading_overlay.dart';
import 'package:afoso1/features/admin/data/models/admin_model.dart';
import 'package:afoso1/features/admin/presentation/providers/admin_provider.dart';
import 'package:afoso1/features/member/presentation/providers/member_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:afoso1/core/constants/app_colors.dart';

class AdminSolidarityScreen extends ConsumerStatefulWidget {
  const AdminSolidarityScreen({super.key});

  @override
  ConsumerState<AdminSolidarityScreen> createState() =>
      _AdminSolidarityScreenState();
}

class _AdminSolidarityScreenState extends ConsumerState<AdminSolidarityScreen> {
  bool _showCreateForm = false;

  @override
  Widget build(BuildContext context) {
    final fundAsync = ref.watch(activeFundProvider);
    final allAsync = ref.watch(allFundsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cagnottes solidaires'),
        actions: [
          if (!_showCreateForm)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _showCreateForm = true),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Créer'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Formulaire de création ─────────────────────────────────────
            if (_showCreateForm) ...[
              FadeInDown(
                child: _CreateFundForm(
                  onClose: () {
                    setState(() => _showCreateForm = false);
                    ref.invalidate(activeFundProvider);
                    ref.invalidate(allFundsProvider);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Cagnotte active ────────────────────────────────────────────
            Text(
              'Cagnotte active',
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            fundAsync.when(
              loading:
                  () => Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
              error:
                  (_, __) => _EmptyCard(
                    icon: Icons.volunteer_activism_outlined,
                    message: 'Aucune cagnotte active',
                  ),
              data:
                  (fund) =>
                      fund == null
                          ? _EmptyCard(
                            icon: Icons.volunteer_activism_outlined,
                            message: 'Aucune cagnotte active',
                          )
                          : FadeInUp(
                            child: _ActiveFundCard(fund: fund, ref: ref),
                          ),
            ),

            const SizedBox(height: 24),

            // ── Historique ─────────────────────────────────────────────────
            Text(
              'Historique des cagnottes',
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            allAsync.when(
              loading:
                  () => Column(
                    children: List.generate(
                      2,
                      (_) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              error: (_, __) => const Text('Erreur de chargement'),
              data:
                  (funds) =>
                      funds.isEmpty
                          ? const _EmptyCard(
                            icon: Icons.history_rounded,
                            message: 'Aucun historique',
                          )
                          : Column(
                            children:
                                funds
                                    .map((f) => _FundHistoryCard(fund: f))
                                    .toList(),
                          ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _CreateFundForm extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  const _CreateFundForm({required this.onClose});

  @override
  ConsumerState<_CreateFundForm> createState() => _CreateFundFormState();
}

class _CreateFundFormState extends ConsumerState<_CreateFundForm> {
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  DateTime? _deadlineDate;

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _deadlineDate = picked);
    }
  }

  Future<void> _create() async {
    if (_descCtrl.text.trim().length < 10) {
      _showSnack('La description doit contenir au moins 10 caractères', isError: true);
      return;
    }

    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount < 3) {
      _showSnack('Montant invalide (minimum 100 FCFA)', isError: true);
      return;
    }

    if (_deadlineDate == null) {
      _showSnack('Veuillez sélectionner une date limite', isError: true);
      return;
    }

    await ref
        .read(createFundProvider.notifier)
        .create(
          CreateSolidarityFundRequest(
            description: _descCtrl.text.trim(),
            amountPerMember: amount,
            deadlineDate: _deadlineDate!,
            messageToMembers:
                _messageCtrl.text.trim().isNotEmpty
                    ? _messageCtrl.text.trim()
                    : null,
          ),
        );

    final state = ref.read(createFundProvider);
    if (state.status == CreateFundStatus.success) {
      _showSnack('Cagnotte créée avec succès !');
      widget.onClose();
    } else if (state.status == CreateFundStatus.error) {
      _showSnack(state.error ?? 'Erreur', isError: true);
    }
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
    final state = ref.watch(createFundProvider);
    final isLoading = state.status == CreateFundStatus.loading;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Créer une cagnotte',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textHint,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AfosoTextField(
            label: 'Description *',
            hint: 'Détails de la situation (minimum 10 caractères)...',
            controller: _descCtrl,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AfosoTextField(
                  label: 'Montant par membre (FCFA) *',
                  hint: '5000',
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(
                    Icons.account_balance_wallet,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _pickDeadline,
                  child: AbsorbPointer(
                    child: AfosoTextField(
                      label: 'Date limite *',
                      hint: 'Sélectionner une date',
                      controller: TextEditingController(
                        text: _deadlineDate != null
                            ? '${_deadlineDate!.day}/${_deadlineDate!.month}/${_deadlineDate!.year}'
                            : '',
                      ),
                      suffixIcon: const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AfosoTextField(
            label: 'Message aux membres (optionnel)',
            hint: 'Message à envoyer aux membres...',
            controller: _messageCtrl,
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          AfosoButton(
            label: 'Créer la cagnotte',
            isLoading: isLoading,
            onPressed: _create,
            icon: const Icon(Icons.volunteer_activism_outlined, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ActiveFundCard extends StatelessWidget {
  final dynamic fund;
  final WidgetRef ref;
  const _ActiveFundCard({required this.fund, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.4), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '● Active',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${fund.contributionCount} contrib.',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            fund.title,
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (fund.beneficiaryName != null) ...[
            const SizedBox(height: 6),
            Text(
              'Bénéficiaire : ${fund.beneficiaryName}',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${fund.collectedAmount.toStringAsFixed(0)} FCFA',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
              Text(
                '/ ${fund.targetAmount.toStringAsFixed(0)} FCFA',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fund.progressPercent,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.success),
            ),
          ),
          const SizedBox(height: 16),
          // Action fermer
          OutlinedButton.icon(
            onPressed: () => _confirmClose(context),
            icon: const Icon(Icons.lock_rounded, size: 16),
            label: const Text('Fermer la cagnotte'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClose(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Fermer la cagnotte',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir fermer "${fund.title}" ?\nCette action est irréversible.',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      try {
        await ref.read(adminRepositoryProvider).closeFund(fund.id as int);
        ref.invalidate(activeFundProvider);
        ref.invalidate(allFundsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cagnotte fermée'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }
}

class _FundHistoryCard extends StatelessWidget {
  final dynamic fund;
  const _FundHistoryCard({required this.fund});

  @override
  Widget build(BuildContext context) {
    final statusColor =
        fund.isActive
            ? AppColors.success
            : fund.status == 'DISBURSED'
            ? AppColors.primary
            : AppColors.textHint;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                  '${fund.collectedAmount.toStringAsFixed(0)} / ${fund.targetAmount.toStringAsFixed(0)} FCFA',
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
              const SizedBox(height: 4),
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

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyCard({required this.icon, required this.message});

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
          Icon(icon, color: AppColors.textHint, size: 28),
          const SizedBox(width: 14),
          Text(
            message,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
