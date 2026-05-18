import 'package:afoso1/core/storage/secure_storage.dart';
import 'package:afoso1/features/admin/data/admin_repository.dart';
import 'package:afoso1/features/admin/data/models/admin_model.dart';
import 'package:afoso1/features/member/data/models/solidarity.dart';
import 'package:afoso1/features/member/data/models/alert.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (_) => AdminRepository(),
);

// ── DASHBOARD STATS ───────────────────────────────────────────────────────────
final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((
  ref,
) {
  return ref.read(adminRepositoryProvider).getDashboardStats();
});

// ── PENDING REGISTRATIONS ─────────────────────────────────────────────────────
final pendingRegistrationsProvider =
    FutureProvider.autoDispose<List<PendingRegistration>>((ref) {
      return ref.read(adminRepositoryProvider).getPendingRegistrations();
    });

// ── CLASSEMENT DÉPÔTS PAR MEMBRE ─────────────────────────────────────────────
final depositsSummaryProvider =
    FutureProvider.autoDispose<List<DepositsSummaryItem>>((ref) {
      return ref.read(adminRepositoryProvider).getMembersDepositsSummary();
    });

// ── RÉSUMÉ FINANCIER PAR PÉRIODE ─────────────────────────────────────────────
// Sélecteur de période prédéfinie
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

// State du sélecteur de période
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
      preset: PeriodPreset.thisMonth, // ignoré pour custom
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

// ── SEND MEMBER ALERTS ─────────────────────────────────────────────────────────
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

// ── MEMBERS SEARCH ────────────────────────────────────────────────────────────
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

// ── REGISTRATION ACTIONS ──────────────────────────────────────────────────────
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

// ── CREATE SOLIDARITY FUND ────────────────────────────────────────────────────
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

// ── MEMBER CONTRIBUTION HISTORY ──────────────────────────────────────────────
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
