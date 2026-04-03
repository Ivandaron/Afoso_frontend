class ApiEndpoints {
  ApiEndpoints._();

  // 🌐 Base URL — Modifie selon ton environnement
  // Android Emulator: http://10.0.2.2:8083
  // iOS Simulator / Web: http://localhost:8083
  // Réseau local: http://192.168.X.X:8083

  // iOS Simulator ou Web
  static const String baseUrl = 'http://localhost:8083';



  // ── AUTH ──────────────────────────────────────────────
  static const String login = '/api/auth/login';
  static const String me = '/api/auth/me';
  static const String logout = '/api/auth/logout';
  static const String changePassword = '/api/auth/change-password';

  // ── INSCRIPTION ────────────────────────────────────────
  static const String register = '/registration/submit';
  static String paymentStatus(String ref) =>
      '/registration/payment/status/$ref';

  // ── MOT DE PASSE ──────────────────────────────────────
  static const String forgotPassword = '/api/password/forgot';
  static const String verifyResetCode = '/api/password/verify-code';
  static const String resetPassword = '/api/password/reset';

  // ── MEMBRES ────────────────────────────────────────────
  static const String memberProfile = '/api/members/profile';

  // ── DÉPÔTS ────────────────────────────────────────────
  static const String initiateDeposit = '/api/deposits/initiate';
  static String depositStatus(String ref) => '/api/deposits/status/$ref';

  // ── CAGNOTTES ─────────────────────────────────────────
  static const String solidarityFunds = '/api/solidarity-funds';
  static String solidarityContribute(Long id) =>
      '/api/solidarity-funds/$id/contribute';

  // ── ADMIN ─────────────────────────────────────────────
  static const String adminDashboard = '/api/admin/dashboard/stats';
  static const String adminMembers = '/api/admin/members';
  static const String adminTransactions = '/api/admin/transactions';
}

// Ignore: ce typedef permet l'usage de Long en pseudo-Dart
typedef Long = int;
