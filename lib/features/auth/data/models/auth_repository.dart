import 'package:afoso1/core/constants/api_endpoints.dart';
import 'package:afoso1/core/network/api_client.dart';
import 'package:afoso1/core/network/api_responses.dart';
import 'package:afoso1/core/storage/secure_storage.dart';
import 'package:afoso1/features/auth/data/models/PaymentStatusResponse.dart';
import 'package:afoso1/features/auth/data/models/RegisterRequest.dart';
import 'package:afoso1/features/auth/data/models/RegistrationResponse.dart';
import 'package:afoso1/features/auth/data/models/auth_responses.dart';
import 'package:afoso1/features/auth/data/models/login_request.dart';

class AuthRepository {
  final ApiClient _api = ApiClient.instance;

  /// 🔐 Connexion — POST /api/auth/login
  Future<AuthResponse> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.login,
        data: LoginRequest(phone: phone, password: password).toJson(),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
      );

      if (!apiResponse.isSuccess || apiResponse.data == null) {
        throw ApiException(
          message: apiResponse.errorMessage ?? 'Identifiants incorrects',
          statusCode: response.statusCode ?? 401,
        );
      }

      final authData = apiResponse.data!;

      await SecureStorageService.saveToken(authData.token);
      ApiClient.setToken(authData.token);
      await SecureStorageService.saveUserInfo(
        role: authData.role,
        userId: authData.memberId?.toString() ?? '',
        name: authData.fullName ?? '',
        phone: authData.phone ?? phone,
      );

      return authData;
    } on ApiException {
      rethrow;
    } on Exception catch (e) {
      throw ApiException(message: e.toString(), statusCode: 0);
    }
  }

  /// 📝 Inscription — POST /registration/submit
  Future<RegistrationResponse> register(RegisterRequest request) async {
    final response = await _api.post(
      ApiEndpoints.register,
      data: request.toJson(),
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => RegistrationResponse.fromJson(data as Map<String, dynamic>),
    );

    if (!apiResponse.isSuccess || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.errorMessage,
        statusCode: response.statusCode,
      );
    }

    return apiResponse.data!;
  }

  /// 🔍 Vérifier statut paiement — GET /registration/payment/status/{ref}
  Future<PaymentStatusResponse> checkPaymentStatus(String externalRef) async {
    final response = await _api.get(ApiEndpoints.paymentStatus(externalRef));

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => PaymentStatusResponse.fromJson(data as Map<String, dynamic>),
    );

    if (!apiResponse.isSuccess || apiResponse.data == null) {
      throw ApiException(message: apiResponse.errorMessage);
    }

    return apiResponse.data!;
  }

  /// 🚪 Déconnexion — POST /api/auth/logout
  Future<void> logout() async {
    try {
      await _api.post(ApiEndpoints.logout);
    } catch (_) {
      // On efface localement même si l'API échoue
    } finally {
      await SecureStorageService.clearAll();
    }
  }

  /// 🔑 Mot de passe oublié — POST /api/password/forgot
  Future<void> forgotPassword(String phone) async {
    final response = await _api.post(
      ApiEndpoints.forgotPassword,
      data: {'phone': phone},
    );

    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      null,
    );

    if (!apiResponse.isSuccess) {
      throw ApiException(message: apiResponse.errorMessage);
    }
  }
}
