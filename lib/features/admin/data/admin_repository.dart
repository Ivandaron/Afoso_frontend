import 'dart:developer' as dev;
import 'package:afoso1/core/network/api_client.dart';
import 'package:afoso1/core/network/api_responses.dart';
import 'package:afoso1/features/admin/data/models/admin_model.dart';
import 'package:afoso1/features/member/data/models/solidarity.dart';
import 'package:afoso1/features/member/data/models/alert.dart';

class AdminRepository {
  final ApiClient _api = ApiClient.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // DASHBOARD STATS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<DashboardStats> getDashboardStats() async {
    // Appel séquentiel — évite les race conditions sur le token
    final statsResp = await _api.get('/api/admin/dashboard/stats');
    final statsRaw = statsResp.data as Map<String, dynamic>;
    var stats = DashboardStats.fromJson(
      statsRaw['data'] as Map<String, dynamic>? ?? statsRaw,
    );

    // Frais d'inscription en 2ème appel indépendant — ne bloque pas si erreur
    try {
      final feesResp = await _api.get('/api/admin/registration-fees/total');
      final feesRaw = feesResp.data as Map<String, dynamic>;
      final fees =
          (feesRaw['data']?['totalRegistrationFees'] as num?)?.toDouble() ??
          0.0;
      stats = stats.withRegistrationFees(fees);
    } catch (_) {
      // Endpoint optionnel — on garde stats sans les frais
    }

    return stats;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RÉSUMÉ FINANCIER PAR PÉRIODE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<PeriodOverview> getFinancialOverviewByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final response = await _api.get(
      '/api/admin/financial-overview/period',
      queryParameters: {'startDate': fmt(startDate), 'endDate': fmt(endDate)},
    );

    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? {};
    return PeriodOverview.fromJson(data);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLASSEMENT DÉPÔTS PAR MEMBRE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<DepositsSummaryItem>> getMembersDepositsSummary({
    int page = 0,
    int size = 50,
    String sortBy = 'totalDeposits',
    String sortDirection = 'desc',
  }) async {
    final response = await _api.get(
      '/api/admin/members/deposits-summary',
      queryParameters: {
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortDirection': sortDirection,
      },
    );

    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? {};
    final content = (data['content'] as List<dynamic>?) ?? [];

    dev.log(
      '💰 deposits-summary: ${content.length} membres',
      name: 'AdminRepository',
    );
    return content
        .map((e) => DepositsSummaryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INSCRIPTIONS EN ATTENTE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<PendingRegistration>> getPendingRegistrations({
    int page = 0,
    int size = 50,
  }) async {
    final response = await _api.get(
      '/api/admin/pending-registrations',
      queryParameters: {'page': page, 'size': size},
    );
    final raw = response.data as Map<String, dynamic>;
    final content = (raw['data']?['content'] as List<dynamic>?) ?? [];

    if (content.isNotEmpty) {
      dev.log(
        '📋 Pending keys: ${(content.first as Map).keys.toList()}',
        name: 'AdminRepository',
      );
    }
    return content
        .map((e) => PendingRegistration.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveRegistration(int id, {String? notes}) async {
    await _api.post(
      '/api/admin/registration/$id/approve',
      data: {'notes': notes ?? 'Approuvé'},
    );
  }

  Future<void> rejectRegistration(int id, {required String reason}) async {
    await _api.post(
      '/api/admin/registration/$id/reject',
      data: {'notes': reason},
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MEMBRES
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<AdminMember>> searchMembers({
    String? name,
    String? phone,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _api.get(
      '/api/admin/members/search',
      queryParameters: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        'page': page,
        'size': size,
      },
    );
    final apiResp = response.data as Map<String, dynamic>;
    final content = (apiResp['data']?['content'] as List<dynamic>?) ?? [];
    return content
        .map((e) => AdminMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> toggleMemberStatus(
    int id, {
    required bool active,
    String? reason,
  }) async {
    await _api.post(
      '/api/admin/members/$id/toggle-status',
      data: {'active': active, 'reason': reason ?? ''},
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CAGNOTTES
  // ═══════════════════════════════════════════════════════════════════════════

  Future<SolidarityFund> createFund(CreateSolidarityFundRequest req) async {
    final response = await _api.post(
      '/api/solidarity-funds',
      data: req.toJson(),
    );
    final apiResp = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => SolidarityFund.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResp.isSuccess || apiResp.data == null) {
      throw ApiException(message: apiResp.errorMessage);
    }
    return apiResp.data!;
  }

  Future<void> closeFund(int id, {String? notes}) async {
    await _api.post(
      '/api/solidarity-funds/$id/close',
      data: {'notes': notes ?? ''},
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HISTORIQUE D'UN MEMBRE
  // ═══════════════════════════════════════════════════════════════════════════

  /// GET /api/admin/members/{id}/contribution-history
  Future<MemberContributionHistory> getMemberContributionHistory(
    int memberId,
  ) async {
    final response = await _api.get(
      '/api/admin/members/$memberId/contribution-history',
    );
    final apiResp = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) =>
          MemberContributionHistory.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResp.isSuccess || apiResp.data == null) {
      throw ApiException(message: apiResp.errorMessage);
    }
    return apiResp.data!;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ALERTES
  // ═══════════════════════════════════════════════════════════════════════════

  /// POST /api/admin/alerts/send
  Future<Map<String, dynamic>> sendMemberAlert(SendAlertRequest request) async {
    final response = await _api.post(
      '/api/admin/alerts/send',
      data: request.toJson(),
    );
    final json = response.data as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return data;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔥 NOUVEAU : PAIEMENTS ANTICIPÉS
  // ═══════════════════════════════════════════════════════════════════════════

  /// GET /api/admin/payments/advance
  /// Liste des paiements anticipés avec filtres (pagination mémoire côté backend).
  Future<AdvancePaymentPage> getAdvancePayments({
    int? memberId,
    int? year,
    int? month,
    int page = 0,
    int size = 20,
    String sortBy = 'paymentDate',
    String sortDirection = 'desc',
  }) async {
    final response = await _api.get(
      '/api/admin/payments/advance',
      queryParameters: {
        if (memberId != null) 'memberId': memberId,
        if (year != null) 'year': year,
        if (month != null) 'month': month,
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortDirection': sortDirection,
      },
    );

    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? {};
    final paymentsRaw = (data['payments'] as List<dynamic>?) ?? [];

    return AdvancePaymentPage(
      payments:
          paymentsRaw
              .map((e) => AdvancePayment.fromJson(e as Map<String, dynamic>))
              .toList(),
      page: (data['page'] as num?)?.toInt() ?? page,
      size: (data['size'] as num?)?.toInt() ?? size,
      totalElements: (data['totalElements'] as num?)?.toInt() ?? 0,
      totalAdvancePayments:
          (data['totalAdvancePayments'] as num?)?.toInt() ?? 0,
      totalAdvanceMonths: (data['totalAdvanceMonths'] as num?)?.toInt() ?? 0,
    );
  }

  /// GET /api/admin/payments/advance/paged
  /// Version paginée SQL (recommandée pour les gros volumes).
  Future<AdvancePaymentPage> getAdvancePaymentsPaged({
    int page = 0,
    int size = 20,
    String sortBy = 'createdAt',
    String sortDirection = 'desc',
  }) async {
    final response = await _api.get(
      '/api/admin/payments/advance/paged',
      queryParameters: {
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortDirection': sortDirection,
      },
    );

    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? {};
    final contentRaw = (data['content'] as List<dynamic>?) ?? [];

    return AdvancePaymentPage(
      payments:
          contentRaw
              .map((e) => AdvancePayment.fromJson(e as Map<String, dynamic>))
              .toList(),
      page: (data['page'] as num?)?.toInt() ?? page,
      size: (data['size'] as num?)?.toInt() ?? size,
      totalElements: (data['totalElements'] as num?)?.toInt() ?? 0,
      totalAdvancePayments: (data['totalElements'] as num?)?.toInt() ?? 0,
      totalAdvanceMonths: (data['totalAdvanceMonths'] as num?)?.toInt() ?? 0,
    );
  }

  /// GET /api/admin/payments/advance/stats
  /// Statistiques globales des paiements anticipés.
  Future<AdvancePaymentStats> getAdvancePaymentStats() async {
    final response = await _api.get('/api/admin/payments/advance/stats');
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? {};
    return AdvancePaymentStats.fromJson(data);
  }

  /// GET /api/admin/payments/advance/top-members
  /// Top N des membres avec le plus de mois d'avance.
  Future<List<TopAdvanceMember>> getTopAdvanceMembers({int limit = 10}) async {
    final response = await _api.get(
      '/api/admin/payments/advance/top-members',
      queryParameters: {'limit': limit},
    );

    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as List<dynamic>? ?? [];

    return data
        .map((e) => TopAdvanceMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/admin/payments/advance/month/{month}/year/{year}
  /// Paiements anticipés pour un mois/année donné.
  Future<List<AdvancePayment>> getAdvancePaymentsByMonthAndYear({
    required int month,
    required int year,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _api.get(
      '/api/admin/payments/advance/month/$month/year/$year',
      queryParameters: {'page': page, 'size': size},
    );

    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? {};
    final content = (data['content'] as List<dynamic>?) ?? [];

    return content
        .map((e) => AdvancePayment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔥 NOUVEAU : CYCLE PARFAIT
  // ═══════════════════════════════════════════════════════════════════════════

  /// GET /api/admin/members/perfect-cycle/{year}
  /// Liste des membres ayant un cycle parfait (12 mois payés) pour une année.
  Future<List<PerfectCycleMember>> getPerfectCycleMembers(int year) async {
    final response = await _api.get('/api/admin/members/perfect-cycle/$year');

    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? {};
    final members = (data['members'] as List<dynamic>?) ?? [];

    return members
        .map((e) => PerfectCycleMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/admin/members/{id}/perfect-cycle/{year}
  /// Vérifie si un membre spécifique a un cycle parfait pour une année.
  Future<PerfectCycleCheck> getMemberPerfectCycle({
    required int memberId,
    required int year,
  }) async {
    final response = await _api.get(
      '/api/admin/members/$memberId/perfect-cycle/$year',
    );

    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? {};
    return PerfectCycleCheck.fromJson(data);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔥 NOUVEAU : DASHBOARD COMPLET
  // ═══════════════════════════════════════════════════════════════════════════

  /// GET /api/admin/dashboard/full
  /// Dashboard complet avec cycle parfait + top avances.
  Future<Map<String, dynamic>> getFullDashboard() async {
    final response = await _api.get('/api/admin/dashboard/full');
    final raw = response.data as Map<String, dynamic>;
    return raw['data'] as Map<String, dynamic>? ?? {};
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔥 NOUVEAU : ANALYTIQUE AVANCES (graphiques)
  // ═══════════════════════════════════════════════════════════════════════════

  /// GET /api/admin/advance-payments/distribution
  /// Répartition détaillée des paiements anticipés (par année/mois et membre).
  Future<List<AdvanceDistributionItem>> getAdvanceDistribution() async {
    final response = await _api.get('/api/admin/advance-payments/distribution');

    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? {};
    final payments = (data['payments'] as List<dynamic>?) ?? [];

    return payments
        .map((e) => AdvanceDistributionItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/admin/advance-payments/by-year
  /// Agrégats annuels des paiements anticipés.
  Future<List<AdvanceByYearItem>> getAdvancePaymentsByYear() async {
    final response = await _api.get('/api/admin/advance-payments/by-year');

    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? {};
    final years = (data['years'] as List<dynamic>?) ?? [];

    return years
        .map((e) => AdvanceByYearItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔥 MODÈLES SPÉCIFIQUES AU REPOSITORY
// ═══════════════════════════════════════════════════════════════════════════

/// Page de résultats paginés pour les paiements anticipés.
class AdvancePaymentPage {
  final List<AdvancePayment> payments;
  final int page;
  final int size;
  final int totalElements;
  final int totalAdvancePayments;
  final int totalAdvanceMonths;

  const AdvancePaymentPage({
    required this.payments,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalAdvancePayments,
    required this.totalAdvanceMonths,
  });

  bool get isEmpty => payments.isEmpty;
  bool get isNotEmpty => payments.isNotEmpty;
  int get totalPages => size > 0 ? (totalElements / size).ceil() : 1;
}

/// Item de distribution (pour graphique) — /advance-payments/distribution
class AdvanceDistributionItem {
  final int? year;
  final int? month;
  final int? monthsInAdvance;
  final double? paidAmount;
  final int? memberId;
  final String? memberName;

  const AdvanceDistributionItem({
    this.year,
    this.month,
    this.monthsInAdvance,
    this.paidAmount,
    this.memberId,
    this.memberName,
  });

  factory AdvanceDistributionItem.fromJson(Map<String, dynamic> json) {
    return AdvanceDistributionItem(
      year: (json['year'] as num?)?.toInt(),
      month: (json['month'] as num?)?.toInt(),
      monthsInAdvance: (json['monthsInAdvance'] as num?)?.toInt(),
      paidAmount: (json['paidAmount'] as num?)?.toDouble(),
      memberId: (json['memberId'] as num?)?.toInt(),
      memberName: json['memberName'] as String?,
    );
  }
}

/// Item agrégé par année — /advance-payments/by-year
class AdvanceByYearItem {
  final int year;
  final int paymentsCount;
  final double totalPaidAmount;
  final int totalMonthsInAdvance;

  const AdvanceByYearItem({
    required this.year,
    required this.paymentsCount,
    required this.totalPaidAmount,
    required this.totalMonthsInAdvance,
  });

  factory AdvanceByYearItem.fromJson(Map<String, dynamic> json) {
    return AdvanceByYearItem(
      year: (json['year'] as num?)?.toInt() ?? 0,
      paymentsCount: (json['paymentsCount'] as num?)?.toInt() ?? 0,
      totalPaidAmount: (json['totalPaidAmount'] as num?)?.toDouble() ?? 0.0,
      totalMonthsInAdvance:
          (json['totalMonthsInAdvance'] as num?)?.toInt() ?? 0,
    );
  }
}
