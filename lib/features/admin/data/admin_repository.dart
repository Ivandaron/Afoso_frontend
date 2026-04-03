import 'dart:developer' as dev;
import 'package:afoso1/core/network/api_client.dart';
import 'package:afoso1/core/network/api_responses.dart';
import 'package:afoso1/features/admin/data/models/admin_model.dart';
import 'package:afoso1/features/member/data/models/solidarity.dart';

class AdminRepository {
  final ApiClient _api = ApiClient.instance;

  // ── DASHBOARD STATS ────────────────────────────────────────────────────────
  // Appelle /dashboard/stats PUIS /registration-fees/total en parallèle

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

  // ── RÉSUMÉ FINANCIER PAR PÉRIODE ──────────────────────────────────────────
  // GET /api/admin/financial-overview/period?startDate=YYYY-MM-DD&endDate=YYYY-MM-DD

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

  // ── CLASSEMENT DÉPÔTS PAR MEMBRE ──────────────────────────────────────────
  // GET /api/admin/members/deposits-summary

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

  // ── INSCRIPTIONS EN ATTENTE ────────────────────────────────────────────────

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

  // ── MEMBRES ────────────────────────────────────────────────────────────────

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

  // ── CAGNOTTES ─────────────────────────────────────────────────────────────

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
}
