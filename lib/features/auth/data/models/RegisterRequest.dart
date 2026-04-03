/// POST /registration/submit
class RegisterRequest {
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String birthDate; // Format: yyyy-MM-dd
  final String city;
  final String address;
  final String password;
  final String paymentMethod; // ORANGE_MONEY | MTN_MONEY | MOOV_MONEY
  final String paymentPhone;

  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.birthDate,
    required this.city,
    required this.address,
    required this.password,
    required this.paymentMethod,
    required this.paymentPhone,
  });

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'email': email,
    'birthDate': birthDate,
    'city': city,
    'address': address,
    'password': password,
    'paymentMethod': paymentMethod,
    'paymentPhone': paymentPhone,
  };
}
