import 'dart:async';

import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/core/utils/validators.dart';
import 'package:afoso1/core/widgets/animations.dart';
import 'package:afoso1/core/widgets/custom_button.dart';
import 'package:afoso1/core/widgets/custom_text_field.dart';
import 'package:afoso1/features/member/data/models/deposit.dart';
import 'package:afoso1/features/member/presentation/providers/deposit_list_tile.dart';
import 'package:afoso1/features/member/presentation/providers/member_provider.dart';
import 'package:afoso1/features/member/presentation/widgets/month_calendar_selector.dart';
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

  final _amountController = TextEditingController(text: '5000');
  double _amountPerMonth = 5000;

  final Set<MonthYear> _selectedMonths = {};

  final _paymentPhoneController = TextEditingController();
  int? _preselectedYear; // 🔥 NOUVEAU : évite de re-préselectionner
  Timer? _pollingTimer;
  int _pollingAttempts = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 🔥 Plus de preselection ici — elle se fera quand la donnée sera chargée
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    _amountController.dispose();
    _paymentPhoneController.dispose();
    super.dispose();
  }

  /// 🔥 Pré-sélectionne les mois la 1ère fois que le calendrier est chargé,
  /// ou quand l'année change. Ne fait rien si déjà pré-sélectionné.
  void _maybePreselect(DepositCalendar calendar) {
    if (_preselectedYear == calendar.year) return;
    _preselectedYear = calendar.year;

    _selectedMonths.clear();

    final overdue = orderedOverdueMonths(calendar.overdueMonths);
    if (overdue.isNotEmpty) {
      _selectedMonths.add(overdue.first.monthYear);
      return;
    }

    if (calendar.canPayFutureMonths) {
      final now = DateTime.now();
      for (final m in calendar.months) {
        if (m.month == now.month && m.year == now.year && m.selectable) {
          _selectedMonths.add(m.monthYear);
          break;
        }
      }
    }
  }

  double get _totalAmount => _amountPerMonth * _selectedMonths.length;

  bool get _isFormValid {
    if (_selectedMonths.isEmpty) return false;
    if (_amountPerMonth < 5) return false;
    if (_paymentPhoneController.text.trim().isEmpty) return false;
    if (Validators.phone(_paymentPhoneController.text) != null) return false;

    final calendar = ref.read(depositCalendarProvider).valueOrNull;
    if (calendar != null) {
      final error = overdueSelectionError(
        calendar.overdueMonths,
        _selectedMonths,
      );
      if (error != null) return false;
    }

    return true;
  }

  Future<void> _handleDeposit() async {
    if (_selectedMonths.isEmpty) {
      _showSnack('Sélectionnez au moins un mois', isError: true);
      return;
    }
    if (_amountPerMonth < 5) {
      _showSnack('Le montant minimum par mois est de 5 FCFA', isError: true);
      return;
    }
    if (_paymentPhoneController.text.trim().isEmpty) {
      _showSnack('Numéro de paiement requis', isError: true);
      return;
    }
    if (Validators.phone(_paymentPhoneController.text) != null) {
      _showSnack('Numéro invalide', isError: true);
      return;
    }

    final calendar = ref.read(depositCalendarProvider).valueOrNull;
    if (calendar != null) {
      final error = overdueSelectionError(
        calendar.overdueMonths,
        _selectedMonths,
      );
      if (error != null) {
        _showSnack(error, isError: true);
        return;
      }
    }

    final sortedMonths =
        _selectedMonths.toList()..sort((a, b) {
          final cmpYear = a.year.compareTo(b.year);
          return cmpYear != 0 ? cmpYear : a.month.compareTo(b.month);
        });

    final request = MultiMonthDepositRequest(
      months: sortedMonths,
      amountPerMonth: _amountPerMonth,
      paymentPhone: _paymentPhoneController.text.trim(),
    );

    await ref.read(depositFormProvider.notifier).initiateDeposit(request);

    if (!mounted) return;
    final state = ref.read(depositFormProvider);
    if (state.status == DepositFormStatus.success) {
      _showDepositConfirmSheet(state.transaction!);
    } else if (state.status == DepositFormStatus.error) {
      _showSnack(state.error ?? 'Erreur', isError: true);
    }
  }

  Future<void> _showDepositConfirmSheet(MultiMonthDepositTransaction tx) async {
    _startPolling(tx.transactionReference);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _PaymentConfirmSheet(
            transaction: tx,
            onClose: () => Navigator.pop(context, true),
          ),
    );

    if (mounted && result == true) {
      ref.read(depositFormProvider.notifier).reset();
      setState(() => _selectedMonths.clear());
      ref.invalidate(depositSummaryProvider);
      ref.invalidate(myDepositsProvider);
      ref.invalidate(depositCalendarProvider);
      ref.invalidate(memberSituationProvider);
    }
  }

  void _startPolling(String reference) {
    _pollingTimer?.cancel();
    _pollingAttempts = 0;

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      _pollingAttempts++;
      try {
        final result = await ref.read(memberRepositoryProvider).verifyPayment(reference);

        if (result.isCompleted) {
          timer.cancel();
          ref.invalidate(myDepositsProvider);
          ref.invalidate(depositCalendarProvider);
          ref.invalidate(memberSituationProvider);
          ref.invalidate(depositSummaryProvider);
          if (mounted) _showSnack('✅ Paiement confirmé !');
          return;
        }

        if (_pollingAttempts >= 24) {
          timer.cancel();
          if (mounted) {
            _showSnack(
              '⏳ Le paiement prend du temps. Vérifiez dans quelques minutes.',
              isError: true,
            );
          }
        }
      } catch (_) {}
    });
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

  void _cascadeUnselect(DepositCalendar calendar, MonthYear removed) {
    final overdue = orderedOverdueMonths(calendar.overdueMonths);
    bool found = false;

    for (final month in overdue) {
      if (found) {
        _selectedMonths.remove(month.monthYear);
      }
      if (month.month == removed.month && month.year == removed.year) {
        found = true;
      }
    }
  }

  CalendarMonthItem? _firstPendingOverdue(DepositCalendar calendar) {
    for (final month in orderedOverdueMonths(calendar.overdueMonths)) {
      if (!_selectedMonths.contains(month.monthYear)) {
        return month;
      }
    }
    return null;
  }

  (bool, String?) _canAddOverdue(DepositCalendar calendar, MonthYear target) {
    final overdue = orderedOverdueMonths(calendar.overdueMonths);
    final targetIndex = overdue.indexWhere(
      (m) => m.month == target.month && m.year == target.year,
    );

    if (targetIndex < 0) {
      final firstPending = _firstPendingOverdue(calendar);
      if (firstPending != null) {
        return (false, 'Sélectionnez ${firstPending.monthName} d\'abord');
      }
      return (true, null);
    }

    int firstPendingIndex = -1;
    for (int i = 0; i < overdue.length; i++) {
      if (!_selectedMonths.contains(overdue[i].monthYear)) {
        firstPendingIndex = i;
        break;
      }
    }

    if (firstPendingIndex == -1) return (true, null);

    final firstPending = overdue[firstPendingIndex];
    if (targetIndex > firstPendingIndex) {
      return (false, 'Sélectionnez ${firstPending.monthName} d\'abord');
    }

    return (true, null);
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(depositFormProvider);
    final depositsAsync = ref.watch(myDepositsProvider);
    final calendarAsync = ref.watch(depositCalendarProvider);
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
                FadeInDown(child: const _SituationCard()),
                const SizedBox(height: 20),
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: calendarAsync.when(
                    loading: () => const _CalendarSkeleton(),
                    error:
                        (e, _) => _ErrorCard(
                          message: e.toString(),
                          onRetry:
                              () => ref.invalidate(depositCalendarProvider),
                        ),
                    data: (calendar) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        if (_preselectedYear != calendar.year) {
                          setState(() => _maybePreselect(calendar));
                        }
                      });

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (calendar.hasBlockingOverdue) ...[
                            _BlockingOverdueBanner(calendar: calendar),
                            const SizedBox(height: 16),
                          ],
                          _QuickShortcuts(
                            calendar: calendar,
                            onSelectOverdue: () {
                              final overdue = orderedOverdueMonths(
                                calendar.overdueMonths,
                              );
                              if (overdue.isEmpty) return;
                              setState(() {
                                _selectedMonths.clear();
                                _selectedMonths.add(overdue.first.monthYear);
                              });
                            },
                            onSelectCurrent: () {
                              final firstPending = _firstPendingOverdue(
                                calendar,
                              );
                              if (firstPending != null) {
                                _showSnack(
                                  'Sélectionnez ${firstPending.monthName} d\'abord',
                                  isError: true,
                                );
                                return;
                              }

                              final now = DateTime.now();
                              setState(() {
                                for (final m in calendar.months) {
                                  if (m.month == now.month &&
                                      m.year == now.year &&
                                      m.selectable) {
                                    _selectedMonths.add(m.monthYear);
                                    break;
                                  }
                                }
                              });
                            },
                            onSelectNext3: () {
                              final firstPending = _firstPendingOverdue(
                                calendar,
                              );
                              if (firstPending != null) {
                                _showSnack(
                                  'Sélectionnez ${firstPending.monthName} d\'abord',
                                  isError: true,
                                );
                                return;
                              }

                              setState(() {
                                final now = DateTime.now();
                                int added = 0;
                                for (final m in calendar.months) {
                                  if (!m.selectable) continue;
                                  if (m.year < now.year) continue;
                                  if (m.year == now.year &&
                                      m.month < now.month) {
                                    continue;
                                  }
                                  _selectedMonths.add(m.monthYear);
                                  added++;
                                  if (added >= 3) break;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          MonthCalendarSelector(
                            calendar: calendar,
                            selectedMonths: _selectedMonths.toList(),
                            onToggle: (my) {
                              final overdue = orderedOverdueMonths(
                                calendar.overdueMonths,
                              );
                              final isOverdue = overdue.any(
                                (m) => m.month == my.month && m.year == my.year,
                              );

                              setState(() {
                                if (_selectedMonths.contains(my)) {
                                  _selectedMonths.remove(my);
                                  if (isOverdue) {
                                    _cascadeUnselect(calendar, my);
                                  }
                                  return;
                                }

                                if (isOverdue) {
                                  final canAdd = _canAddOverdue(calendar, my);
                                  if (!canAdd.$1) {
                                    _showSnack(
                                      canAdd.$2 ?? 'Sélection invalide',
                                      isError: true,
                                    );
                                    return;
                                  }
                                } else {
                                  final firstPending = _firstPendingOverdue(
                                    calendar,
                                  );
                                  if (firstPending != null) {
                                    _showSnack(
                                      'Sélectionnez ${firstPending.monthName} d\'abord',
                                      isError: true,
                                    );
                                    return;
                                  }
                                }

                                _selectedMonths.add(my);
                              });
                            },
                            onPrevYear: () {
                              ref
                                  .read(depositCalendarYearProvider.notifier)
                                  .state--;
                              setState(() {
                                _selectedMonths.clear();
                                _preselectedYear = null;
                              });
                            },
                            onNextYear: () {
                              ref
                                  .read(depositCalendarYearProvider.notifier)
                                  .state++;
                              setState(() {
                                _selectedMonths.clear();
                                _preselectedYear = null;
                              });
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _PaymentForm(
                    amountController: _amountController,
                    onAmountChanged: (v) {
                      final parsed = double.tryParse(v);
                      if (parsed != null) {
                        setState(() => _amountPerMonth = parsed);
                      }
                    },
                    phoneController: _paymentPhoneController,
                    onPhoneChanged: () => setState(() {}),
                  ),
                ),
                const SizedBox(height: 20),
                if (_selectedMonths.isNotEmpty)
                  FadeInUp(
                    delay: const Duration(milliseconds: 250),
                    child: _SelectionSummary(
                      selectedMonths:
                          _selectedMonths.toList()..sort((a, b) {
                            final cmpYear = a.year.compareTo(b.year);
                            return cmpYear != 0
                                ? cmpYear
                                : a.month.compareTo(b.month);
                          }),
                      amountPerMonth: _amountPerMonth,
                      totalAmount: _totalAmount,
                      onRemove:
                          (my) => setState(() => _selectedMonths.remove(my)),
                    ),
                  ),
                const SizedBox(height: 20),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: AfosoButton(
                    label:
                        _selectedMonths.isEmpty
                            ? 'Sélectionnez des mois'
                            : 'Payer ${_totalAmount.toInt()} FCFA',
                    isLoading: isLoading,
                    onPressed: _isFormValid ? _handleDeposit : null,
                    icon: const Icon(Icons.send_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 20),
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
                (_, __) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(myDepositsProvider),
                    child: const Text('Réessayer'),
                  ),
                ),
            data:
                (deposits) =>
                    deposits.isEmpty
                        ? const Center(child: Text('Aucune cotisation'))
                        : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: deposits.length,
                          itemBuilder:
                              (_, i) => DepositListTile(deposit: deposits[i]),
                        ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔥 Bandeau de blocage
// ═══════════════════════════════════════════════════════════════════════════

class _BlockingOverdueBanner extends StatelessWidget {
  final DepositCalendar calendar;

  const _BlockingOverdueBanner({required this.calendar});

  @override
  Widget build(BuildContext context) {
    final monthsLabel = calendar.blockingOverdueMonths.join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.danger.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: AppColors.danger,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cotisation bloquée',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            calendar.blockReason ??
                'Vous avez des mois en retard à régulariser.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'À régler : $monthsLabel',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ces mois sont automatiquement pré-sélectionnés. '
            'Réglez-les en priorité, puis vous pourrez à nouveau cotiser normalement.',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Widgets internes
// ═══════════════════════════════════════════════════════════════════════════

class _SituationCard extends ConsumerWidget {
  const _SituationCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final situationAsync = ref.watch(memberSituationProvider);

    return situationAsync.when(
      loading:
          () => Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
      error: (_, __) => const SizedBox.shrink(),
      data: (situation) {
        Color color;
        IconData icon;
        switch (situation.situation) {
          case 'EN_RETARD':
            color = AppColors.danger;
            icon = Icons.error_rounded;
            break;
          case 'EN_AVANCE':
            color = const Color(0xFF7C3AED);
            icon = Icons.rocket_launch_rounded;
            break;
          case 'A_JOUR':
            color = AppColors.success;
            icon = Icons.check_circle_rounded;
            break;
          default:
            color = AppColors.warning;
            icon = Icons.pending_rounded;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ma situation',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      situation.situationLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${situation.totalPaid.toInt()} F',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _QuickShortcuts extends StatelessWidget {
  final DepositCalendar calendar;
  final VoidCallback onSelectOverdue;
  final VoidCallback onSelectCurrent;
  final VoidCallback onSelectNext3;

  const _QuickShortcuts({
    required this.calendar,
    required this.onSelectOverdue,
    required this.onSelectCurrent,
    required this.onSelectNext3,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (calendar.overdueMonths.isNotEmpty)
            _ShortcutChip(
              icon: Icons.error_rounded,
              label: '${calendar.overdueMonths.length} en retard',
              color: AppColors.danger,
              onTap: onSelectOverdue,
            ),
          if (calendar.overdueMonths.isNotEmpty) const SizedBox(width: 8),
          _ShortcutChip(
            icon: Icons.today_rounded,
            label: 'Mois courant',
            color: AppColors.warning,
            onTap: onSelectCurrent,
          ),
          const SizedBox(width: 8),
          _ShortcutChip(
            icon: Icons.rocket_launch_rounded,
            label: '3 mois d\'avance',
            color: AppColors.primary,
            onTap: onSelectNext3,
          ),
        ],
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShortcutChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PaymentForm extends StatelessWidget {
  final TextEditingController amountController;
  final ValueChanged<String> onAmountChanged;
  final TextEditingController phoneController;
  final VoidCallback onPhoneChanged;

  const _PaymentForm({
    required this.amountController,
    required this.onAmountChanged,
    required this.phoneController,
    required this.onPhoneChanged,
  });

  @override
  Widget build(BuildContext context) {
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
          AfosoTextField(
            label: 'Montant par mois (FCFA)',
            hint: '5000',
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            onChanged: onAmountChanged,
            prefixIcon: const Icon(
              Icons.attach_money_rounded,
              size: 20,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 16),
          AfosoTextField(
            label: 'Numéro Mobile Money',
            hint: '6XX XXX XXX',
            controller: phoneController,
            keyboardType: TextInputType.phone,
            onChanged: (_) => onPhoneChanged(),
            prefixIcon: const Icon(
              Icons.phone_outlined,
              size: 20,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SelectionSummary extends StatelessWidget {
  final List<MonthYear> selectedMonths;
  final double amountPerMonth;
  final double totalAmount;
  final ValueChanged<MonthYear> onRemove;

  const _SelectionSummary({
    required this.selectedMonths,
    required this.amountPerMonth,
    required this.totalAmount,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Ma sélection (${selectedMonths.length})',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...selectedMonths.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      m.label,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${amountPerMonth.toInt()} F',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => onRemove(m),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textHint,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: AppColors.primary),
          Row(
            children: [
              Text(
                'Total à payer',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${totalAmount.toInt()} FCFA',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
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

class _PaymentConfirmSheet extends StatelessWidget {
  final MultiMonthDepositTransaction transaction;
  final VoidCallback onClose;

  const _PaymentConfirmSheet({
    required this.transaction,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final monthsLabel = transaction.months.map((m) => m.label).join(', ');

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
            'Paiement initié',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Confirmez la transaction sur votre téléphone.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _ConfirmRow(
                  'Montant total',
                  '${transaction.totalAmount.toInt()} FCFA',
                ),
                const Divider(height: 20),
                _ConfirmRow('Mois', monthsLabel),
                const Divider(height: 20),
                _ConfirmRow('Référence', transaction.transactionReference),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onClose, child: const Text('Compris')),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfirmRow(this.label, this.value);

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
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CalendarSkeleton extends StatelessWidget {
  const _CalendarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(16),
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
}
