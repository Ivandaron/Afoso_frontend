import 'package:afoso1/core/network/api_responses.dart';

/// Traduit une exception technique en message utilisateur clair.
class ErrorMapper {
  ErrorMapper._();

  /// Convertit n'importe quelle erreur en message lisible par un humain.
  static String toUserMessage(Object? error) {
    if (error == null) return 'Une erreur est survenue. Réessayez.';

    if (error is ApiException) {
      final backendMessage = error.message;
      final statusCode = error.statusCode;

      if (_isUsefulMessage(backendMessage)) {
        return backendMessage!.trim();
      }

      return _mapByStatusCode(statusCode);
    }

    final raw = error.toString().toLowerCase();

    if (raw.contains('socketexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('network is unreachable') ||
        raw.contains('connection refused') ||
        raw.contains('connexion')) {
      return 'Pas de connexion internet. Vérifiez votre réseau.';
    }

    if (raw.contains('timeout') || raw.contains('timed out')) {
      return 'La connexion a expiré. Réessayez.';
    }

    if (raw.contains('formatexception') || raw.contains('parsing')) {
      return 'Réponse serveur invalide. Réessayez plus tard.';
    }

    return _cleanRawMessage(error.toString());
  }

  static bool _isUsefulMessage(String? msg) {
    if (msg == null) return false;
    final trimmed = msg.trim();
    if (trimmed.isEmpty) return false;

    final lower = trimmed.toLowerCase();
    const uselessPatterns = [
      'error',
      'erreur',
      'unknown',
      'null',
      'undefined',
      'internal server error',
      'an error occurred',
    ];

    return !uselessPatterns.contains(lower);
  }

  static String _mapByStatusCode(int? code) {
    switch (code) {
      case 400:
        return 'Informations incorrectes. Vérifiez et réessayez.';
      case 401:
        return 'Numéro ou mot de passe incorrect.';
      case 403:
        return 'Votre compte est désactivé. Contactez un administrateur.';
      case 404:
        return 'Aucun compte trouvé avec ce numéro.';
      case 409:
        return 'Ce numéro est déjà utilisé.';
      case 422:
        return 'Données invalides. Vérifiez votre saisie.';
      case 429:
        return 'Trop de tentatives. Réessayez dans quelques minutes.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Serveur temporairement indisponible. Réessayez plus tard.';
      default:
        return 'Une erreur est survenue. Réessayez.';
    }
  }

  static String _cleanRawMessage(String raw) {
    return raw
        .replaceFirst('ApiException: ', '')
        .replaceFirst('Exception: ', '')
        .replaceFirst('DioException [', 'Erreur réseau [')
        .replaceFirst('SocketException: ', 'Pas de connexion : ')
        .trim();
  }
}
