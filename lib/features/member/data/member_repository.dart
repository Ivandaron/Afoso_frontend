import 'package:afoso1/core/network/api_client.dart';
import 'package:afoso1/core/network/api_responses.dart';
import 'package:afoso1/features/member/data/models/deposit.dart';
import 'package:afoso1/features/member/data/models/solidarity.dart';
import 'package:afoso1/features/member/data/models/alert.dart';

class MemberRepository {
  final ApiClient _api = ApiClient.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // DÉPÔTS
  // ═══════════════════════════════════════════════════════════════════════════

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
  /// Initie un paiement pour N mois explicites.
  Future<MultiMonthDepositTransaction> initiateMultiMonthDeposit(
    MultiMonthDepositRequest request,
  ) async {
    final response = await _api.post(
      '/api/me/deposits/initiate',
      data: request.toJson(),
    );

    final json = response.data as Map<String, dynamic>;
    if (json['success'] != true) {
      throw ApiException(
        message: json['message'] as String? ?? 'Erreur lors du paiement',
      );
    }
    final data = json['data'] as Map<String, dynamic>;
    return MultiMonthDepositTransaction.fromJson(data);
  }

  /// GET /api/me/deposits/calendar?year=2026
  Future<DepositCalendar> getDepositCalendar({int? year}) async {
    final response = await _api.get(
      '/api/me/deposits/calendar',
      queryParameters: {if (year != null) 'year': year},
    );

    final json = response.data as Map<String, dynamic>;
    if (json['success'] != true) {
      throw ApiException(
        message: json['message'] as String? ?? 'Erreur de chargement',
      );
    }
    final data = json['data'] as Map<String, dynamic>;
    return DepositCalendar.fromJson(data);
  }

  /// GET /api/me/deposits/situation
  Future<MemberSituation> getMemberSituation() async {
    final response = await _api.get('/api/me/deposits/situation');

    final json = response.data as Map<String, dynamic>;
    if (json['success'] != true) {
      throw ApiException(
        message: json['message'] as String? ?? 'Erreur de chargement',
      );
    }
    final data = json['data'] as Map<String, dynamic>;
    return MemberSituation.fromJson(data);
  }

  Future<PaymentVerifyResult> verifyPayment(String reference) async {
    final response = await _api.post('/api/me/deposits/$reference/verify');
    final json = response.data as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return PaymentVerifyResult(
      reference: data['reference'] as String? ?? reference,
      status: data['status'] as String? ?? 'PENDING',
      isCompleted: data['isCompleted'] as bool? ?? false,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CAGNOTTES SOLIDAIRES
  // ═══════════════════════════════════════════════════════════════════════════

  Future<SolidarityFund?> getActiveFund() async {
    try {
      final response = await _api.get('/api/solidarity-funds/active');
      final apiResp = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => SolidarityFund.fromJson(data as Map<String, dynamic>),
      );
      return apiResp.data;
    } catch (e) {
      print('Erreur lors de la récupération de la cagnotte active: $e');
      return null;
    }
  }

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

  Future<bool> hasContributed(int fundId) async {
    final response = await _api.get(
      '/api/solidarity-funds/$fundId/has-contributed',
    );
    final apiResp = response.data as Map<String, dynamic>;
    final data = apiResp['data'] as Map<String, dynamic>?;
    return data?['hasContributed'] as bool? ?? false;
  }

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

  // ═══════════════════════════════════════════════════════════════════════════
  // ALERTES
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<MemberAlert>> getUnreadAlerts(int memberId) async {
    final response = await _api.get('/api/members/$memberId/alerts/unread');
    final json = response.data as Map<String, dynamic>;
    final datalist = json['data'] as List<dynamic>? ?? [];
    return datalist
        .map((e) => MemberAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MemberAlert>> getMemberAlerts(int memberId) async {
    final response = await _api.get('/api/members/$memberId/alerts');
    final json = response.data as Map<String, dynamic>;
    final dataList = json['data'] as List<dynamic>? ?? [];
    return dataList
        .map((e) => MemberAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAlertAsRead(int alertId) async {
    await _api.put('/api/alerts/$alertId/read');
  }

  Future<void> markAllAlertsAsRead(int memberId) async {
    await _api.put('/api/members/$memberId/alerts/read-all');
  }
}
