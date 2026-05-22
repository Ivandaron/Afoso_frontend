import 'dart:developer' as dev;
import 'dart:io';

import 'package:afoso1/core/network/api_client.dart';
import 'package:afoso1/core/network/api_responses.dart';
import 'package:afoso1/features/admin/data/models/admin_model.dart';
import 'package:afoso1/features/member/data/models/solidarity.dart';
import 'package:afoso1/features/member/data/models/alert.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class AdminRepository {
  final ApiClient _api = ApiClient.instance;

  // ── DASHBOARD STATS ────────────────────────────────────────────────────────
  // Appelle /dashboard/stats PUIS /registration-fees/total en parallèle

  Future<DashboardStats> getDashboardStats() async {
    // Appel séquentiel — évite les race conditions sur le token
    final statsResp = await _api.get(
      '/api/admin/dashboard/stats',
      responseType: ResponseType.json,
    );
    final statsRaw = statsResp.data as Map<String, dynamic>;
    var stats = DashboardStats.fromJson(
      statsRaw['data'] as Map<String, dynamic>? ?? statsRaw,
    );

    // Frais d'inscription en 2ème appel indépendant — ne bloque pas si erreur
    try {
      final feesResp = await _api.get(
        '/api/admin/registration-fees/total',
        responseType: ResponseType.json,
      );
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
      responseType: ResponseType.json,
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
      responseType: ResponseType.json,
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
      responseType: ResponseType.json,
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
      responseType: ResponseType.json,
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

  /// Importe un fichier Excel
  Future<ExcelImportResult> importExcelFile(
    String filePath,
    String fileName,
  ) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await _api.post(
      '/api/excel/import',
      data: formData,
    );

    final json = response.data as Map<String, dynamic>;
    if (json['success'] != true) {
      throw ApiException(
        message: json['message'] as String? ?? 'Erreur lors de l\'import',
      );
    }
    return ExcelImportResult.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Récupère les statistiques d'un batch d'import
  Future<ExcelImportStatistics> getImportStatistics(String batchId) async {
    final response = await _api.get(
      '/api/excel/import/$batchId/statistics',
      responseType: ResponseType.json,
    );
    final json = response.data as Map<String, dynamic>;
    return ExcelImportStatistics.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Vérifie le statut de configuration d'un membre importé
  Future<ExcelMemberSetupStatus> getMemberSetupStatus(String phone) async {
    final response = await _api.get('/api/excel/setup/status/$phone', responseType: ResponseType.json);
    final json = response.data as Map<String, dynamic>;
    return ExcelMemberSetupStatus.fromJson(
      json['data'] as Map<String, dynamic>,
    );
  }

  /// Demande un OTP pour changer le mot de passe
  Future<void> requestPasswordChange(String phone) async {
    await _api.post(
      '/api/excel/setup/request-password-change',
      data: {'phone': phone},
    );
  }

  /// Vérifie l'OTP et définit le nouveau mot de passe
  Future<void> verifyAndSetPassword(
    String phone,
    String otp,
    String newPassword,
    String confirmPassword,
  ) async {
    await _api.post(
      '/api/excel/setup/verify-and-set-password',
      data: {
        'phone': phone,
        'otp': otp,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }

  /// Synchronise les données d'un membre importé
  Future<ImportedMemberData?> syncImportedData() async {
    final response = await _api.get(
      '/api/excel/sync-imported-data',
      responseType: ResponseType.json,
    );
    final json = response.data as Map<String, dynamic>;
    if (json['data'] == null) return null;
    return ImportedMemberData.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Télécharge le template Excel pour l'import
  Future<void> downloadExcelTemplate() async {
    final response = await _api.get(
      '/api/excel/template',
      responseType: ResponseType.bytes,
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/template_import_membres.xlsx');
    await file.writeAsBytes(response.data as List<int>);
  }

  /// GET /api/admin/members/{id}/contribution-history
  Future<MemberContributionHistory> getMemberContributionHistory(
    int memberId,
  ) async {
    final response = await _api.get(
      '/api/admin/members/$memberId/contribution-history',
      responseType: ResponseType.json,
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

  // ── ALERTES ────────────────────────────────────────────────────────────────

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
}

// ── MODÈLES POUR L'IMPORT EXCEL ──────────────────────────────────────────────
class ExcelImportResult {
  final String batchId;
  final String fileName;
  final int totalRecords;
  final int successfulImports;
  final int failedImports;
  final List<String> errors;
  final List<MemberImportRecord> importedMembers;
  final DateTime importedAt;

  ExcelImportResult({
    required this.batchId,
    required this.fileName,
    required this.totalRecords,
    required this.successfulImports,
    required this.failedImports,
    required this.errors,
    required this.importedMembers,
    required this.importedAt,
  });

  factory ExcelImportResult.fromJson(Map<String, dynamic> json) {
    return ExcelImportResult(
      batchId: json['batchId'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
      successfulImports: (json['successfulImports'] as num?)?.toInt() ?? 0,
      failedImports: (json['failedImports'] as num?)?.toInt() ?? 0,
      errors:
          (json['errors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      importedMembers:
          (json['importedMembers'] as List<dynamic>?)
              ?.map(
                (e) => MemberImportRecord.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      importedAt:
          DateTime.tryParse(json['importedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class MemberImportRecord {
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String city;
  final int memberId;
  final String matricule;
  final String status;

  MemberImportRecord({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.city,
    required this.memberId,
    required this.matricule,
    required this.status,
  });

  factory MemberImportRecord.fromJson(Map<String, dynamic> json) {
    return MemberImportRecord(
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      city: json['city'] as String? ?? '',
      memberId: (json['memberId'] as num?)?.toInt() ?? 0,
      matricule: json['matricule'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

class ExcelImportStatistics {
  final String batchId;
  final int totalMembers;
  final int pendingPasswordSetup;
  final int otpRequested;
  final int phoneVerified;
  final int setupCompleted;
  final int errors;

  ExcelImportStatistics({
    required this.batchId,
    required this.totalMembers,
    required this.pendingPasswordSetup,
    required this.otpRequested,
    required this.phoneVerified,
    required this.setupCompleted,
    required this.errors,
  });

  factory ExcelImportStatistics.fromJson(Map<String, dynamic> json) {
    return ExcelImportStatistics(
      batchId: json['batchId'] as String? ?? '',
      totalMembers: (json['totalMembers'] as num?)?.toInt() ?? 0,
      pendingPasswordSetup:
          (json['pendingPasswordSetup'] as num?)?.toInt() ?? 0,
      otpRequested: (json['otpRequested'] as num?)?.toInt() ?? 0,
      phoneVerified: (json['phoneVerified'] as num?)?.toInt() ?? 0,
      setupCompleted: (json['setupCompleted'] as num?)?.toInt() ?? 0,
      errors: (json['errors'] as num?)?.toInt() ?? 0,
    );
  }

  int get progressPercentage =>
      totalMembers > 0 ? (setupCompleted * 100 ~/ totalMembers) : 0;
  int get pendingMembers => pendingPasswordSetup + otpRequested + phoneVerified;
}

class ExcelMemberSetupStatus {
  final int memberId;
  final String phone;
  final String firstName;
  final String lastName;
  final String importStatus;
  final bool setupCompleted;
  final DateTime importedAt;
  final DateTime? passwordSetupCompletedAt;
  final DateTime? phoneVerificationCompletedAt;

  ExcelMemberSetupStatus({
    required this.memberId,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.importStatus,
    required this.setupCompleted,
    required this.importedAt,
    this.passwordSetupCompletedAt,
    this.phoneVerificationCompletedAt,
  });

  factory ExcelMemberSetupStatus.fromJson(Map<String, dynamic> json) {
    return ExcelMemberSetupStatus(
      memberId: (json['memberId'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      importStatus: json['importStatus'] as String? ?? 'PENDING_PASSWORD_SETUP',
      setupCompleted: json['setupCompleted'] as bool? ?? false,
      importedAt:
          DateTime.tryParse(json['importedAt'] as String? ?? '') ??
          DateTime.now(),
      passwordSetupCompletedAt:
          json['passwordSetupCompletedAt'] != null
              ? DateTime.tryParse(json['passwordSetupCompletedAt'] as String)
              : null,
      phoneVerificationCompletedAt:
          json['phoneVerificationCompletedAt'] != null
              ? DateTime.tryParse(
                json['phoneVerificationCompletedAt'] as String,
              )
              : null,
    );
  }
}

class ImportedMemberData {
  final int memberId;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final double importedBalance;
  final DateTime importedAt;
  final String? originalAccountNumber;
  final String? originalMemberId;
  final double currentBalance;

  ImportedMemberData({
    required this.memberId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.importedBalance,
    required this.importedAt,
    this.originalAccountNumber,
    this.originalMemberId,
    required this.currentBalance,
  });

  factory ImportedMemberData.fromJson(Map<String, dynamic> json) {
    return ImportedMemberData(
      memberId: (json['memberId'] as num?)?.toInt() ?? 0,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      importedBalance: (json['importedBalance'] as num?)?.toDouble() ?? 0.0,
      importedAt:
          DateTime.tryParse(json['importedAt'] as String? ?? '') ??
          DateTime.now(),
      originalAccountNumber: json['originalAccountNumber'] as String?,
      originalMemberId: json['originalMemberId'] as String?,
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
