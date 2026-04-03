class AuthResponse {
  final String token; // accessToken
  final String refreshToken;
  final String role; // extrait depuis userInfoDTO.roles
  final String? fullName;
  final String? phone;
  final String? email;
  final int? memberId;
  final String? matricule;

  AuthResponse({
    required this.token,
    required this.refreshToken,
    required this.role,
    this.fullName,
    this.phone,
    this.email,
    this.memberId,
    this.matricule,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final userInfo = json['userInfoDTO'] as Map<String, dynamic>? ?? {};

    // roles peut être ["ROLE_ADMIN","ADMIN"] ou ["MEMBER","ROLE_MEMBER"]
    // On extrait le rôle propre (sans préfixe ROLE_)
    String role = 'MEMBER';
    final roles = userInfo['roles'];
    if (roles is List && roles.isNotEmpty) {
      for (final r in roles) {
        final s = r.toString();
        if (s == 'ADMIN' || s == 'ROLE_ADMIN') {
          role = 'ADMIN';
          break;
        }
        if (s == 'MEMBER' || s == 'ROLE_MEMBER') {
          role = 'MEMBER';
        }
      }
    }
    // fallback : champ role direct s'il existe
    final directRole = json['role'] as String?;
    if (directRole != null && directRole.isNotEmpty) {
      role = directRole.replaceAll('ROLE_', '');
    }

    return AuthResponse(
      token: json['accessToken'] as String? ?? json['token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      role: role,
      fullName: userInfo['fullName'] as String?,
      phone: userInfo['phone'] as String?,
      email: userInfo['email'] as String?,
      memberId: (userInfo['id'] as num?)?.toInt(),
      matricule: userInfo['matricule'] as String?,
    );
  }

  bool get isAdmin => role == 'ADMIN';
}
