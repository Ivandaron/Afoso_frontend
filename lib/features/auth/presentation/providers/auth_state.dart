enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? role;
  final String? userName;
  final String? userPhone;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.role,
    this.userName,
    this.userPhone,
    this.errorMessage,
    this.isLoading = false,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isAdmin => role == 'ADMIN';
  bool get isMember => role == 'MEMBER';

  AuthState copyWith({
    AuthStatus? status,
    String? role,
    String? userName,
    String? userPhone,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      role: role ?? this.role,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
