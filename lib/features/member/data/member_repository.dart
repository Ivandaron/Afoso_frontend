import 'package:afoso1/core/network/api_client.dart';
import 'package:afoso1/core/network/api_responses.dart';
import 'package:afoso1/features/member/data/models/deposit.dart';
import 'package:afoso1/features/member/data/models/solidarity.dart';
import 'package:afoso1/features/member/data/models/alert.dart';

class MemberRepository {
  final ApiClient _api = ApiClient.instance;

  // ── DÉPÔTS ─────────────────────────────────────────────────────────────────

  /// GET /api/me/deposits/summary
  Future<DepositSummary> getDepositSummary() async {
    final response = await _api.get('/api/me/deposits/summary');
    final json = response.data as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    return DepositSummary.fromJson(data);
  }

  /// GET /api/me/deposits
  Future<List<Deposit>> getMyDeposits() async {
    final response = await _api.get('/api/me/deposits');
    final json = response.data as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    final list = data['deposits'] as List<dynamic>? ?? [];
    return list
        .map((e) => Deposit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/me/deposits/current-month
  Future<Map<String, dynamic>> getCurrentMonthStats() async {
    final response = await _api.get('/api/me/deposits/current-month');
    final json = response.data as Map<String, dynamic>;
    return json['data'] as Map<String, dynamic>;
  }

  /// POST /api/me/deposits/initiate
  /// NOTE: legacy single-month `initiateDeposit` endpoint replaced by
  /// `initiateUnifiedDeposit` which supports one or multiple months.
  Future<MultipleDepositTransaction> initiateDeposit(
    UnifiedDepositRequest request,
  ) async {
    return initiateUnifiedDeposit(request);
  }

   /// 🔥 NOUVEAU: Endpoint unifié pour les dépôts (1 mois ou plusieurs)
  Future<MultipleDepositTransaction> initiateUnifiedDeposit(
    UnifiedDepositRequest request,
  ) async {
    final response = await _api.post(
      '/api/me/deposits/initiate',
      data: request.toJson(),
    );

    final json = response.data as Map<String, dynamic>;
    if (json['success'] != true) {
      throw ApiException(message: json['message'] as String? ?? 'Erreur');
    }
    final data = json['data'] as Map<String, dynamic>;
    return MultipleDepositTransaction.fromJson(data);
  }

  // ── CAGNOTTES SOLIDAIRES ────────────────────────────────────────────────────

  /// GET /api/solidarity-funds/active
  Future<SolidarityFund?> getActiveFund() async {
    try {
      final response = await _api.get('/api/solidarity-funds/active');
      final apiResp = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => SolidarityFund.fromJson(data as Map<String, dynamic>),
      );
      return apiResp.data;
    } catch (e) {
      // Log l'erreur pour le debugging
      print('Erreur lors de la récupération de la cagnotte active: $e');
      return null; // Aucune cagnotte active
    }
  }

  /// GET /api/solidarity-funds  (liste paginée)
  Future<List<SolidarityFund>> getAllFunds({
    int page = 0,
    int size = 10,
  }) async {
    final response = await _api.get(
      '/api/solidarity-funds',
      queryParameters: {'page': page, 'size': size},
    );
    final apiResp = response.data as Map<String, dynamic>;
    final content = (apiResp['data']?['content'] as List<dynamic>?) ?? [];
    return content
        .map((e) => SolidarityFund.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/solidarity-funds/member/me/history
  Future<List<SolidarityFund>> getMySolidarityHistory() async {
    final response = await _api.get('/api/solidarity-funds/member/me/history');
    final apiResp = ApiResponse<List<dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => data as List<dynamic>,
    );
    return (apiResp.data ?? [])
        .map((e) => SolidarityFund.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/solidarity-funds/{id}/has-contributed
  Future<bool> hasContributed(int fundId) async {
    final response = await _api.get(
      '/api/solidarity-funds/$fundId/has-contributed',
    );
    final apiResp = response.data as Map<String, dynamic>;
    final data = apiResp['data'] as Map<String, dynamic>?;
    return data?['hasContributed'] as bool? ?? false;
  }

  /// POST /api/solidarity-funds/{id}/contribute
  Future<SolidarityContribution> contribute(
    int fundId,
    ContributeSolidarityRequest request,
  ) async {
    final response = await _api.post(
      '/api/solidarity-funds/$fundId/contribute',
      data: request.toJson(),
    );
    final apiResp = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => SolidarityContribution.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResp.isSuccess || apiResp.data == null) {
      throw ApiException(message: apiResp.errorMessage);
    }
    return apiResp.data!;
  }

  // ── ALERTES ─────────────────────────────────────────────────────────────────

  /// GET /api/members/{id}/alerts/unread
  Future<List<MemberAlert>> getUnreadAlerts(int memberId) async {
    final response = await _api.get(
      '/api/members/$memberId/alerts/unread',
    );
    final json = response.data as Map<String, dynamic>;
    final datalist = json['data'] as List<dynamic>? ?? [];
    return datalist
        .map((e) => MemberAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/members/{id}/alerts
  Future<List<MemberAlert>> getMemberAlerts(int memberId) async {
    final response = await _api.get(
      '/api/members/$memberId/alerts',
    );
    final json = response.data as Map<String, dynamic>;
    final dataList = json['data'] as List<dynamic>? ?? [];
    return dataList
        .map((e) => MemberAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// PUT /api/alerts/{alertId}/read
  Future<void> markAlertAsRead(int alertId) async {
    await _api.put('/api/alerts/$alertId/read');
  }

  /// PUT /api/members/{id}/alerts/read-all
  Future<void> markAllAlertsAsRead(int memberId) async {
    await _api.put('/api/members/$memberId/alerts/read-all');
  }
}
