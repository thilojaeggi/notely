import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  static const String _accessTokenKey = 'access_token';
  static const String _accessTokenExpiryKey = 'access_token_expires_at';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _otpSecretKey = 'otp_secret';
  final FlutterSecureStorage _storage;

  factory SecureStorage() => _instance;

  SecureStorage._internal()
      : _storage = const FlutterSecureStorage(
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
            accountName: 'notely',
          ),
          aOptions: AndroidOptions(
            sharedPreferencesName: 'notely',
            encryptedSharedPreferences: true,
          ),
        );

  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  Future<void> saveAccessToken(String token,
      {DateTime? expiresAt, String? refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: token);
    if (expiresAt != null) {
      await _storage.write(
          key: _accessTokenExpiryKey, value: expiresAt.toIso8601String());
    } else {
      await _storage.delete(key: _accessTokenExpiryKey);
    }

    if (refreshToken != null) {
      if (refreshToken.isNotEmpty) {
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      } else {
        await _storage.delete(key: _refreshTokenKey);
      }
    } else {
      await _storage.delete(key: _refreshTokenKey);
    }
  }

  Future<String?> readAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<DateTime?> readAccessTokenExpiry() async {
    final raw = await _storage.read(key: _accessTokenExpiryKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<String?> readRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> clearAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _accessTokenExpiryKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> saveOtpSecret(String secret) async {
    await _storage.write(key: _otpSecretKey, value: secret);
  }

  Future<String?> readOtpSecret() async {
    return _storage.read(key: _otpSecretKey);
  }

  Future<void> clearOtpSecret() async {
    await _storage.delete(key: _otpSecretKey);
  }
}
