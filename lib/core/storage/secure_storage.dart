import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyToken = 'afoso_jwt_token';
  static const _keyRole = 'afoso_user_role';
  static const _keyUserId = 'afoso_user_id';
  static const _keyUserName = 'afoso_user_name';
  static const _keyUserPhone = 'afoso_user_phone';
  static const _keyAdminTerms = 'afoso_admin_terms';
  static const _keyAdminPolicy = 'afoso_admin_policy';
  static const _keyAdminAlert = 'afoso_admin_alert';

  // ── TOKEN ──────────────────────────────────────────────
  static Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  static Future<String?> getToken() => _storage.read(key: _keyToken);

  static Future<void> deleteToken() => _storage.delete(key: _keyToken);

  // ── USER INFO ─────────────────────────────────────────
  static Future<void> saveUserInfo({
    required String role,
    required String userId,
    required String name,
    required String phone,
  }) async {
    await Future.wait([
      _storage.write(key: _keyRole, value: role),
      _storage.write(key: _keyUserId, value: userId),
      _storage.write(key: _keyUserName, value: name),
      _storage.write(key: _keyUserPhone, value: phone),
    ]);
  }

  static Future<String?> getRole() => _storage.read(key: _keyRole);
  static Future<String?> getUserId() => _storage.read(key: _keyUserId);
  static Future<String?> getUserName() => _storage.read(key: _keyUserName);
  static Future<String?> getUserPhone() => _storage.read(key: _keyUserPhone);

  static Future<void> saveAdminTerms(String value) =>
      _storage.write(key: _keyAdminTerms, value: value);
  static Future<String?> getAdminTerms() =>
      _storage.read(key: _keyAdminTerms);

  static Future<void> saveAdminPolicy(String value) =>
      _storage.write(key: _keyAdminPolicy, value: value);
  static Future<String?> getAdminPolicy() =>
      _storage.read(key: _keyAdminPolicy);

  static Future<void> saveAdminAlertMessage(String value) =>
      _storage.write(key: _keyAdminAlert, value: value);
  static Future<String?> getAdminAlertMessage() =>
      _storage.read(key: _keyAdminAlert);

  // ── CLEAR ALL ─────────────────────────────────────────
  static Future<void> clearAll() => _storage.deleteAll();

  // ── IS LOGGED IN ──────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
