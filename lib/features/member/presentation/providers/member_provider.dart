import 'package:afoso1/features/member/data/member_repository.dart';
import 'package:afoso1/features/member/data/models/deposit.dart';
import 'package:afoso1/features/member/data/models/solidarity.dart';
import 'package:afoso1/features/member/data/models/alert.dart';
import 'package:afoso1/features/auth/presentation/providers/provider.dart';
import 'package:afoso1/core/storage/secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final memberRepositoryProvider = Provider<MemberRepository>(
  (_) => MemberRepository(),
);

// ── DEPOSIT SUMMARY ───────────────────────────────────────────────────────────
final depositSummaryProvider = FutureProvider.autoDispose<DepositSummary>((
  ref,
) async {
  return ref.read(memberRepositoryProvider).getDepositSummary();
});

// ── MY DEPOSITS LIST ──────────────────────────────────────────────────────────
final myDepositsProvider = FutureProvider.autoDispose<List<Deposit>>((
  ref,
) async {
  return ref.read(memberRepositoryProvider).getMyDeposits();
});

// ── DEPOSIT FORM STATE (pour paiement unifié) ────────────────────────────────
enum DepositFormStatus { idle, loading, success, error }

class DepositFormState {
  final DepositFormStatus status;
  final MultipleDepositTransaction? transaction;
  final String? error;

  const DepositFormState({
    this.status = DepositFormStatus.idle,
    this.transaction,
    this.error,
  });

  DepositFormState copyWith({
    DepositFormStatus? status,
    MultipleDepositTransaction? transaction,
    String? error,
  }) => DepositFormState(
    status: status ?? this.status,
    transaction: transaction ?? this.transaction,
    error: error,
  );
}

class DepositFormNotifier extends StateNotifier<DepositFormState> {
  final MemberRepository _repo;
  DepositFormNotifier(this._repo) : super(const DepositFormState());

  Future<void> initiateDeposit(UnifiedDepositRequest req) async {
    state = state.copyWith(status: DepositFormStatus.loading, error: null);
    try {
      final tx = await _repo.initiateUnifiedDeposit(req);
      state = state.copyWith(
        status: DepositFormStatus.success,
        transaction: tx,
      );
    } catch (e) {
      state = state.copyWith(
        status: DepositFormStatus.error,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() => state = const DepositFormState();
}

final depositFormProvider = StateNotifierProvider.autoDispose<DepositFormNotifier, DepositFormState>((ref) {
  return DepositFormNotifier(ref.read(memberRepositoryProvider));
});

// Provider pour les mois à payer (helper)
final monthsToPayProvider = Provider<List<String>>((ref) {
  final now = DateTime.now();
  final months = <String>[];
  for (int i = 0; i < 12; i++) {
    final date = DateTime(now.year, now.month + i);
    months.add('${_monthNames[date.month]} ${date.year}');
  }
  return months;
});

const _monthNames = [
  '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
];

// ── ACTIVE SOLIDARITY FUND ────────────────────────────────────────────────────
final activeFundProvider = FutureProvider.autoDispose<SolidarityFund?>((
  ref,
) async {
  return ref.read(memberRepositoryProvider).getActiveFund();
});

// ── ALL SOLIDARITY FUNDS ──────────────────────────────────────────────────────
final allFundsProvider = FutureProvider.autoDispose<List<SolidarityFund>>((
  ref,
) async {
  return ref.read(memberRepositoryProvider).getAllFunds();
});

// ── MY SOLIDARITY HISTORY ─────────────────────────────────────────────────────
final mySolidarityHistoryProvider =
    FutureProvider.autoDispose<List<SolidarityFund>>((ref) async {
      return ref.read(memberRepositoryProvider).getMySolidarityHistory();
    });

// ── SOLIDARITY CONTRIBUTE STATE ───────────────────────────────────────────────
enum ContributeStatus { idle, loading, success, error }

class ContributeState {
  final ContributeStatus status;
  final SolidarityContribution? contribution;
  final String? error;

  const ContributeState({
    this.status = ContributeStatus.idle,
    this.contribution,
    this.error,
  });

  ContributeState copyWith({
    ContributeStatus? status,
    SolidarityContribution? contribution,
    String? error,
  }) => ContributeState(
    status: status ?? this.status,
    contribution: contribution ?? this.contribution,
    error: error,
  );
}

class ContributeNotifier extends StateNotifier<ContributeState> {
  final MemberRepository _repo;
  ContributeNotifier(this._repo) : super(const ContributeState());

  Future<void> contribute(int fundId, ContributeSolidarityRequest req) async {
    state = state.copyWith(status: ContributeStatus.loading, error: null);
    try {
      final contrib = await _repo.contribute(fundId, req);
      state = state.copyWith(
        status: ContributeStatus.success,
        contribution: contrib,
      );
    } catch (e) {
      state = state.copyWith(
        status: ContributeStatus.error,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() => state = const ContributeState();
}

final contributeProvider =
    StateNotifierProvider.autoDispose<ContributeNotifier, ContributeState>((
      ref,
    ) {
      return ContributeNotifier(ref.read(memberRepositoryProvider));
    });

// ── MEMBER UNREAD ALERTS ──────────────────────────────────────────────────────
final memberUnreadAlertsProvider =
    FutureProvider.autoDispose<List<MemberAlert>>((ref) async {
      try {
        // Get current user's ID from secure storage
        final userId = await SecureStorageService.getUserId();
        if (userId == null || userId.isEmpty) return [];

        final memberId = int.parse(userId);
        return ref.read(memberRepositoryProvider).getUnreadAlerts(memberId);
      } catch (e) {
        return [];
      }
    });
