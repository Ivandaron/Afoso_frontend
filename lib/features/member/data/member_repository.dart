import 'package:afoso1/core/network/api_client.dart';
import 'package:afoso1/core/network/api_responses.dart';
import 'package:afoso1/features/member/data/models/deposit.dart';
import 'package:afoso1/features/member/data/models/solidarity.dart';

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
  Future<DepositTransaction> initiateDeposit(
    InitiateDepositRequest request,
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
    return DepositTransaction.fromJson(data);
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
}
