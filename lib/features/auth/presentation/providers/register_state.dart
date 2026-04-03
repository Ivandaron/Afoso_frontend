import 'package:afoso1/features/auth/data/models/PaymentStatusResponse.dart';
import 'package:afoso1/features/auth/data/models/RegisterRequest.dart';
import 'package:afoso1/features/auth/data/models/RegistrationResponse.dart';
import 'package:afoso1/features/auth/data/models/auth_repository.dart';
import 'package:afoso1/features/auth/presentation/providers/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RegisterStatus { idle, loading, waitingPayment, success, error }

class RegisterState {
  final RegisterStatus status;
  final RegistrationResponse? registration;
  final String? errorMessage;

  const RegisterState({
    this.status = RegisterStatus.idle,
    this.registration,
    this.errorMessage,
  });

  RegisterState copyWith({
    RegisterStatus? status,
    RegistrationResponse? registration,
    String? errorMessage,
  }) {
    return RegisterState(
      status: status ?? this.status,
      registration: registration ?? this.registration,
      errorMessage: errorMessage,
    );
  }
}

class RegisterNotifier extends StateNotifier<RegisterState> {
  final AuthRepository _repository;

  RegisterNotifier(this._repository) : super(const RegisterState());

  Future<void> register(RegisterRequest request) async {
    state = const RegisterState(status: RegisterStatus.loading);

    try {
      final response = await _repository.register(request);
      state = RegisterState(
        status: RegisterStatus.waitingPayment,
        registration: response,
      );
    } catch (e) {
      state = RegisterState(
        status: RegisterStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<PaymentStatusResponse?> checkPaymentStatus(String ref) async {
    try {
      return await _repository.checkPaymentStatus(ref);
    } catch (_) {
      return null;
    }
  }

  void reset() {
    state = const RegisterState();
  }
}

final registerProvider = StateNotifierProvider<RegisterNotifier, RegisterState>(
  (ref) {
    return RegisterNotifier(ref.read(authRepositoryProvider));
  },
);
