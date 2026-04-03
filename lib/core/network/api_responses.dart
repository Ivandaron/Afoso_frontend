/// Modèle générique qui correspond à ApiResponse<T> du backend Spring Boot
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? error;

  ApiResponse({required this.success, this.message, this.data, this.error});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      error: json['error'] as String?,
      data:
          json['data'] != null && fromJsonT != null
              ? fromJsonT(json['data'])
              : null,
    );
  }

  bool get isSuccess => success;
  bool get hasError => !success || error != null;
  String get errorMessage => error ?? message ?? 'Une erreur est survenue';
}

/// Wrapper pour les erreurs réseau / API
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
