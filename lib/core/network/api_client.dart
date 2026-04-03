import 'dart:developer' as dev;
import 'package:afoso1/core/network/api_responses.dart';

import '../storage/secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_endpoints.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;

  // ── Cache mémoire du token ─────────────────────────────────────────────────
  // Évite les lectures SecureStorage concurrentes et le risque qu'un 401
  // sur un endpoint secondaire efface le token pour tous les appels suivants.
  static String? _cachedToken;

  /// Appeler après login pour mettre le token en cache immédiatement.
  static void setToken(String token) {
    _cachedToken = token.replaceAll('"', '').trim();
    dev.log(
      'ApiClient: token cached (${_cachedToken!.length} chars)',
      name: 'ApiClient',
    );
  }

  /// Appeler au logout pour vider le cache ET le stockage.
  static Future<void> logout() async {
    _cachedToken = null;
    await SecureStorageService.clearAll();
    dev.log('ApiClient: token cleared (logout)', name: 'ApiClient');
  }

  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // ── Intercepteur JWT ─────────────────────────────────────────────────────
    // Injecte le token depuis le cache mémoire (prioritaire) ou SecureStorage.
    // NE JAMAIS effacer le token ici — c'est le rôle de logout() uniquement.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 1. Essaie le cache mémoire
          String? token = _cachedToken;

          // 2. Si pas en cache, lit SecureStorage et met en cache
          if (token == null || token.isEmpty) {
            final raw = await SecureStorageService.getToken();
            token = raw?.replaceAll('"', '').trim();
            if (token != null && token.isNotEmpty) {
              _cachedToken = token;
            }
          }

          final present = token != null && token.isNotEmpty;
          dev.log(
            'ApiClient → ${options.method} ${options.path} | token=${present ? "✓ ${token!.substring(0, 8)}…" : "✗ ABSENT"}',
            name: 'ApiClient',
          );

          if (present) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, handler) {
          // ⚠️ NE PAS effacer le token sur 401 ici.
          // Un 401 peut venir d'un endpoint secondaire (ex: registration-fees/total)
          // et ne doit pas déconnecter l'utilisateur ni effacer sa session.
          // La redirection vers /login est gérée par le GoRouter via un listener.
          if (error.response?.statusCode == 401) {
            dev.log(
              'ApiClient: 401 sur ${error.requestOptions.path} — token NON effacé',
              name: 'ApiClient',
            );
          }
          handler.next(error);
        },
      ),
    );

    // ── Logger (après intercepteur auth pour voir le header Authorization) ───
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        error: true,
        compact: true,
      ),
    );
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  Dio get dio => _dio;

  // ── Méthodes HTTP ─────────────────────────────────────────────────────────

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ApiException _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      String message = 'Erreur serveur ($statusCode)';

      if (data is Map<String, dynamic>) {
        message = data['message'] ?? data['error'] ?? data['detail'] ?? message;
      } else if (data is String && data.isNotEmpty) {
        message = data;
      }

      // Log pour debug
      dev.log(
        'ApiClient: HTTP $statusCode sur ${e.requestOptions.path} → $message',
        name: 'ApiClient',
      );

      return ApiException(message: message, statusCode: statusCode);
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        message: 'Délai de connexion dépassé. Vérifiez votre réseau.',
      );
    }
    if (e.type == DioExceptionType.connectionError) {
      return ApiException(
        message: 'Impossible de joindre le serveur. Vérifiez votre connexion.',
      );
    }
    return ApiException(message: e.message ?? 'Erreur réseau inconnue');
  }
}
