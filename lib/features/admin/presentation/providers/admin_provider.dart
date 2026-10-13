import 'package:afoso1/core/storage/secure_storage.dart';
import 'package:afoso1/features/admin/data/admin_repository.dart';
import 'package:afoso1/features/admin/data/models/admin_model.dart';
import 'package:afoso1/features/member/data/models/solidarity.dart';
import 'package:afoso1/features/member/data/models/alert.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (_) => AdminRepository(),
);

// ═══════════════════════════════════════════════════════════════════════════
// DASHBOARD STATS
// ═══════════════════════════════════════════════════════════════════════════

final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((
  ref,
) {
  return ref.read(adminRepositoryProvider).getDashboardStats();
});

// ═══════════════════════════════════════════════════════════════════════════
// PENDING REGISTRATIONS
// ═══════════════════════════════════════════════════════════════════════════

final pendingRegistrationsProvider =
    FutureProvider.autoDispose<List<PendingRegistration>>((ref) {
      return ref.read(adminRepositoryProvider).getPendingRegistrations();
    });

// ═══════════════════════════════════════════════════════════════════════════
// CLASSEMENT DÉPÔTS PAR MEMBRE
// ═══════════════════════════════════════════════════════════════════════════

final depositsSummaryProvider =
    FutureProvider.autoDispose<List<DepositsSummaryItem>>((ref) {
      return ref.read(adminRepositoryProvider).getMembersDepositsSummary();
    });

// ═══════════════════════════════════════════════════════════════════════════
// RÉSUMÉ FINANCIER PAR PÉRIODE
// ═══════════════════════════════════════════════════════════════════════════

enum PeriodPreset { thisMonth, lastMonth, last3Months, thisYear }

extension PeriodPresetX on PeriodPreset {
  String get label {
    switch (this) {
      case PeriodPreset.thisMonth:
        return 'Ce mois';
      case PeriodPreset.lastMonth:
        return 'Mois dernier';
      case PeriodPreset.last3Months:
        return '3 derniers mois';
      case PeriodPreset.thisYear:
        return 'Cette année';
    }
  }

  (DateTime start, DateTime end) get dates {
    final now = DateTime.now();
    switch (this) {
      case PeriodPreset.thisMonth:
        return (DateTime(now.year, now.month, 1), now);
      case PeriodPreset.lastMonth:
        final first = DateTime(now.year, now.month - 1, 1);
        final last = DateTime(
          now.year,
          now.month,
          1,
        ).subtract(const Duration(days: 1));
        return (first, last);
      case PeriodPreset.last3Months:
        return (DateTime(now.year, now.month - 2, 1), now);
      case PeriodPreset.thisYear:
        return (DateTime(now.year, 1, 1), now);
    }
  }
}

class PeriodState {
  final PeriodPreset preset;
  final DateTime startDate;
  final DateTime endDate;

  PeriodState({
    this.preset = PeriodPreset.thisMonth,
    required this.startDate,
    required this.endDate,
  });

  factory PeriodState.fromPreset(PeriodPreset preset) {
    final (start, end) = preset.dates;
    return PeriodState(preset: preset, startDate: start, endDate: end);
  }
}

class PeriodNotifier extends StateNotifier<PeriodState> {
  PeriodNotifier() : super(PeriodState.fromPreset(PeriodPreset.thisMonth));

  void selectPreset(PeriodPreset preset) {
    state = PeriodState.fromPreset(preset);
  }

  void selectCustom(DateTime start, DateTime end) {
    state = PeriodState(
      preset: PeriodPreset.thisMonth,
      startDate: start,
      endDate: end,
    );
  }
}

final periodNotifierProvider =
    StateNotifierProvider<PeriodNotifier, PeriodState>((_) => PeriodNotifier());

final periodOverviewProvider = FutureProvider.autoDispose<PeriodOverview>((
  ref,
) {
  final period = ref.watch(periodNotifierProvider);
  return ref
      .read(adminRepositoryProvider)
      .getFinancialOverviewByPeriod(
        startDate: period.startDate,
        endDate: period.endDate,
      );
});

// ═══════════════════════════════════════════════════════════════════════════
// ADMIN ALERT MESSAGE
// ═══════════════════════════════════════════════════════════════════════════

final adminAlertProvider = StateNotifierProvider<AdminAlertNotifier, String>(
  (ref) => AdminAlertNotifier(ref.watch(adminRepositoryProvider)),
);

class AdminAlertNotifier extends StateNotifier<String> {
  final AdminRepository _repo;
  AdminAlertNotifier(this._repo) : super('') {
    loadAlert();
  }

  Future<void> loadAlert() async {
    final alert = await SecureStorageService.getAdminAlertMessage();
    state = alert ?? '';
  }

  Future<void> setAlert(String message) async {
    await SecureStorageService.saveAdminAlertMessage(message);
    state = message;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SEND MEMBER ALERTS
// ═══════════════════════════════════════════════════════════════════════════

enum SendAlertStatus { idle, loading, success, error }

class SendAlertState {
  final SendAlertStatus status;
  final Map<String, dynamic>? result;
  final String? error;

  const SendAlertState({
    this.status = SendAlertStatus.idle,
    this.result,
    this.error,
  });

  SendAlertState copyWith({
    SendAlertStatus? status,
    Map<String, dynamic>? result,
    String? error,
  }) => SendAlertState(
    status: status ?? this.status,
    result: result ?? this.result,
    error: error,
  );
}

class SendAlertNotifier extends StateNotifier<SendAlertState> {
  final AdminRepository _repo;
  SendAlertNotifier(this._repo) : super(const SendAlertState());

  Future<void> sendAlert(SendAlertRequest request) async {
    state = state.copyWith(status: SendAlertStatus.loading, error: null);
    try {
      final result = await _repo.sendMemberAlert(request);
      state = state.copyWith(status: SendAlertStatus.success, result: result);
    } catch (e) {
      state = state.copyWith(
        status: SendAlertStatus.error,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() => state = const SendAlertState();
}

final sendAlertProvider =
    StateNotifierProvider.autoDispose<SendAlertNotifier, SendAlertState>((ref) {
      return SendAlertNotifier(ref.read(adminRepositoryProvider));
    });

// ═══════════════════════════════════════════════════════════════════════════
// MEMBERS SEARCH
// ═══════════════════════════════════════════════════════════════════════════

class MembersSearchState {
  final List<AdminMember> members;
  final bool isLoading;
  final String? error;
  final String query;

  const MembersSearchState({
    this.members = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
  });

  MembersSearchState copyWith({
    List<AdminMember>? members,
    bool? isLoading,
    String? error,
    String? query,
  }) => MembersSearchState(
    members: members ?? this.members,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    query: query ?? this.query,
  );
}

class MembersSearchNotifier extends StateNotifier<MembersSearchState> {
  final AdminRepository _repo;
  MembersSearchNotifier(this._repo) : super(const MembersSearchState()) {
    search('');
  }

  Future<void> search(String query) async {
    state = state.copyWith(isLoading: true, error: null, query: query);
    try {
      final members = await _repo.searchMembers(
        name: query.isNotEmpty ? query : null,
      );
      state = state.copyWith(isLoading: false, members: members);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> toggleStatus(int memberId, bool active) async {
    try {
      await _repo.toggleMemberStatus(memberId, active: active);
      final updated =
          state.members.map((m) {
            if (m.id == memberId) {
              return AdminMember.fromJson({
                'id': m.id,
                'fullName': m.fullName,
                'phone': m.phone,
                'email': m.email,
                'matricule': m.matricule,
                'status': active ? 'ACTIVE' : 'INACTIVE',
                'active': active,
                'city': m.city,
                'createdAt': m.createdAt,
                'balance': m.balance,
                'hasAdvancePayment': m.hasAdvancePayment,
                'advanceMonthsCount': m.advanceMonthsCount,
                'advanceAmount': m.advanceAmount,
                'currentMonthPaid': m.currentMonthPaid,
                'lastPaymentDate': m.lastPaymentDate,
                'currentMonthStatus': m.currentMonthStatus,
              });
            }
            return m;
          }).toList();
      state = state.copyWith(members: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final membersSearchProvider = StateNotifierProvider.autoDispose<
  MembersSearchNotifier,
  MembersSearchState
>((ref) => MembersSearchNotifier(ref.read(adminRepositoryProvider)));

// ═══════════════════════════════════════════════════════════════════════════
// REGISTRATION ACTIONS
// ═══════════════════════════════════════════════════════════════════════════

enum RegistrationActionStatus { idle, loading, success, error }

class RegistrationActionState {
  final RegistrationActionStatus status;
  final int? processedId;
  final String? error;

  const RegistrationActionState({
    this.status = RegistrationActionStatus.idle,
    this.processedId,
    this.error,
  });
}

class RegistrationActionNotifier
    extends StateNotifier<RegistrationActionState> {
  final AdminRepository _repo;
  RegistrationActionNotifier(this._repo)
    : super(const RegistrationActionState());

  Future<bool> approve(int id, {String? notes}) async {
    state = RegistrationActionState(
      status: RegistrationActionStatus.loading,
      processedId: id,
    );
    try {
      await _repo.approveRegistration(id, notes: notes);
      state = RegistrationActionState(
        status: RegistrationActionStatus.success,
        processedId: id,
      );
      return true;
    } catch (e) {
      state = RegistrationActionState(
        status: RegistrationActionStatus.error,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> reject(int id, {required String reason}) async {
    state = RegistrationActionState(
      status: RegistrationActionStatus.loading,
      processedId: id,
    );
    try {
      await _repo.rejectRegistration(id, reason: reason);
      state = RegistrationActionState(
        status: RegistrationActionStatus.success,
        processedId: id,
      );
      return true;
    } catch (e) {
      state = RegistrationActionState(
        status: RegistrationActionStatus.error,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void reset() => state = const RegistrationActionState();
}

final registrationActionProvider = StateNotifierProvider.autoDispose<
  RegistrationActionNotifier,
  RegistrationActionState
>((ref) {
  return RegistrationActionNotifier(ref.read(adminRepositoryProvider));
});

// ═══════════════════════════════════════════════════════════════════════════
// CREATE SOLIDARITY FUND
// ═══════════════════════════════════════════════════════════════════════════

enum CreateFundStatus { idle, loading, success, error }

class CreateFundState {
  final CreateFundStatus status;
  final SolidarityFund? fund;
  final String? error;
  const CreateFundState({
    this.status = CreateFundStatus.idle,
    this.fund,
    this.error,
  });
}

class CreateFundNotifier extends StateNotifier<CreateFundState> {
  final AdminRepository _repo;
  CreateFundNotifier(this._repo) : super(const CreateFundState());

  Future<void> create(CreateSolidarityFundRequest req) async {
    state = const CreateFundState(status: CreateFundStatus.loading);
    try {
      final fund = await _repo.createFund(req);
      state = CreateFundState(status: CreateFundStatus.success, fund: fund);
    } catch (e) {
      state = CreateFundState(
        status: CreateFundStatus.error,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() => state = const CreateFundState();
}

final createFundProvider =
    StateNotifierProvider.autoDispose<CreateFundNotifier, CreateFundState>(
      (ref) => CreateFundNotifier(ref.read(adminRepositoryProvider)),
    );

// ═══════════════════════════════════════════════════════════════════════════
// MEMBER CONTRIBUTION HISTORY
// ═══════════════════════════════════════════════════════════════════════════

class MemberContributionHistoryState {
  final MemberContributionHistory? history;
  final bool isLoading;
  final String? error;

  const MemberContributionHistoryState({
    this.history,
    this.isLoading = false,
    this.error,
  });

  MemberContributionHistoryState copyWith({
    MemberContributionHistory? history,
    bool? isLoading,
    String? error,
  }) => MemberContributionHistoryState(
    history: history ?? this.history,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class MemberContributionHistoryNotifier
    extends StateNotifier<MemberContributionHistoryState> {
  final AdminRepository _repo;

  MemberContributionHistoryNotifier(this._repo)
    : super(const MemberContributionHistoryState());

  Future<void> load(int memberId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final history = await _repo.getMemberContributionHistory(memberId);
      state = state.copyWith(isLoading: false, history: history);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final memberContributionHistoryProvider = StateNotifierProvider.autoDispose
    .family<
      MemberContributionHistoryNotifier,
      MemberContributionHistoryState,
      int
    >((ref, memberId) {
      return MemberContributionHistoryNotifier(
        ref.read(adminRepositoryProvider),
      );
    });

// ═══════════════════════════════════════════════════════════════════════════
// 🔥 NOUVEAU : PAIEMENTS ANTICIPÉS — STATS GLOBALES
// ═══════════════════════════════════════════════════════════════════════════

/// Statistiques globales des paiements anticipés (pour le dashboard).
final advancePaymentStatsProvider =
    FutureProvider.autoDispose<AdvancePaymentStats>((ref) {
      return ref.read(adminRepositoryProvider).getAdvancePaymentStats();
    });

// ═══════════════════════════════════════════════════════════════════════════
// 🔥 NOUVEAU : LISTE PAGINÉE DES PAIEMENTS ANTICIPÉS
// ═══════════════════════════════════════════════════════════════════════════

/// État pour les filtres de la liste des paiements anticipés.
class AdvancePaymentsFilter {
  final int? memberId;
  final int? year;
  final int? month;
  final int page;
  final int size;
  final String sortBy;
  final String sortDirection;

  const AdvancePaymentsFilter({
    this.memberId,
    this.year,
    this.month,
    this.page = 0,
    this.size = 20,
    this.sortBy = 'paymentDate',
    this.sortDirection = 'desc',
  });

  AdvancePaymentsFilter copyWith({
    int? memberId,
    int? year,
    int? month,
    int? page,
    int? size,
    String? sortBy,
    String? sortDirection,
    bool clearMember = false,
    bool clearYear = false,
    bool clearMonth = false,
  }) {
    return AdvancePaymentsFilter(
      memberId: clearMember ? null : (memberId ?? this.memberId),
      year: clearYear ? null : (year ?? this.year),
      month: clearMonth ? null : (month ?? this.month),
      page: page ?? this.page,
      size: size ?? this.size,
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
    );
  }
}

class AdvancePaymentsFilterNotifier
    extends StateNotifier<AdvancePaymentsFilter> {
  AdvancePaymentsFilterNotifier() : super(const AdvancePaymentsFilter());

  void setMember(int? memberId) {
    state = state.copyWith(
      memberId: memberId,
      page: 0,
      clearMember: memberId == null,
    );
  }

  void setYear(int? year) {
    state = state.copyWith(year: year, page: 0, clearYear: year == null);
  }

  void setMonth(int? month) {
    state = state.copyWith(month: month, page: 0, clearMonth: month == null);
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
  }

  void setSort(String sortBy, String direction) {
    state = state.copyWith(sortBy: sortBy, sortDirection: direction, page: 0);
  }

  void reset() => state = const AdvancePaymentsFilter();
}

final advancePaymentsFilterProvider =
    StateNotifierProvider<AdvancePaymentsFilterNotifier, AdvancePaymentsFilter>(
      (ref) => AdvancePaymentsFilterNotifier(),
    );

/// Liste paginée des paiements anticipés — se recharge à chaque changement de filtre.
final advancePaymentsPageProvider =
    FutureProvider.autoDispose<AdvancePaymentPage>((ref) {
      final filter = ref.watch(advancePaymentsFilterProvider);
      return ref
          .read(adminRepositoryProvider)
          .getAdvancePayments(
            memberId: filter.memberId,
            year: filter.year,
            month: filter.month,
            page: filter.page,
            size: filter.size,
            sortBy: filter.sortBy,
            sortDirection: filter.sortDirection,
          );
    });

// ═══════════════════════════════════════════════════════════════════════════
// 🔥 NOUVEAU : TOP MEMBRES PAR AVANCE
// ═══════════════════════════════════════════════════════════════════════════

/// Top N des membres avec le plus de mois d'avance.
final topAdvanceMembersProvider =
    FutureProvider.autoDispose<List<TopAdvanceMember>>((ref) {
      return ref.read(adminRepositoryProvider).getTopAdvanceMembers(limit: 10);
    });

// ═══════════════════════════════════════════════════════════════════════════
// 🔥 NOUVEAU : CYCLE PARFAIT
// ═══════════════════════════════════════════════════════════════════════════

/// Année sélectionnée pour l'écran cycle parfait.
final perfectCycleYearProvider = StateProvider<int>((ref) {
  return DateTime.now().year;
});

/// Liste des membres avec cycle parfait pour l'année sélectionnée.
final perfectCycleMembersProvider =
    FutureProvider.autoDispose<List<PerfectCycleMember>>((ref) {
      final year = ref.watch(perfectCycleYearProvider);
      return ref.read(adminRepositoryProvider).getPerfectCycleMembers(year);
    });

/// Vérification du cycle parfait pour un membre spécifique.
final memberPerfectCycleProvider = FutureProvider.autoDispose
    .family<PerfectCycleCheck, ({int memberId, int year})>((ref, params) {
      return ref
          .read(adminRepositoryProvider)
          .getMemberPerfectCycle(memberId: params.memberId, year: params.year);
    });

// ═══════════════════════════════════════════════════════════════════════════
// 🔥 NOUVEAU : DASHBOARD COMPLET
// ═══════════════════════════════════════════════════════════════════════════

/// Dashboard complet enrichi (stats + cycle parfait + top avances).
final fullDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) {
  return ref.read(adminRepositoryProvider).getFullDashboard();
});

// ═══════════════════════════════════════════════════════════════════════════
// 🔥 NOUVEAU : ANALYTIQUE AVANCES (graphiques)
// ═══════════════════════════════════════════════════════════════════════════

/// Distribution détaillée des paiements anticipés (par année/mois).
final advanceDistributionProvider =
    FutureProvider.autoDispose<List<AdvanceDistributionItem>>((ref) {
      return ref.read(adminRepositoryProvider).getAdvanceDistribution();
    });

/// Agrégats annuels des paiements anticipés.
final advanceByYearProvider =
    FutureProvider.autoDispose<List<AdvanceByYearItem>>((ref) {
      return ref.read(adminRepositoryProvider).getAdvancePaymentsByYear();
    });
