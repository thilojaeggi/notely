import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:notely/secure_storage.dart';

class TokenManager {
  TokenManager._internal();

  static final TokenManager _instance = TokenManager._internal();
  static const Duration _expiryLeeway = Duration(minutes: 1);
  static const String _clientId = 'ppyybShnMerHdtBQ';

  final SecureStorage _storage = SecureStorage();

  factory TokenManager() => _instance;

  Future<String?> getValidAccessToken(String school) async {
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    final expiry = await _storage.readAccessTokenExpiry();
    if (expiry == null ||
        expiry.isAfter(DateTime.now().add(_expiryLeeway))) {
      return token;
    }
    return _refreshAccessToken(school);
  }

  Future<void> clearTokens() async {
    await _storage.clearAccessToken();
  }

  Future<String?> _refreshAccessToken(String school) async {
    if (school.isEmpty) {
      return null;
    }
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final tokenUrl =
        Uri.parse('https://kaschuso.so.ch/public/$school/token.php');

    final response = await http.post(
      tokenUrl,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json, text/plain, */*',
      },
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': _clientId,
      },
    );

    if (response.statusCode != 200) {
      await clearTokens();
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final newAccessToken = data['access_token'] as String?;
    if (newAccessToken == null || newAccessToken.isEmpty) {
      await clearTokens();
      return null;
    }

    final expiresAt = _deriveExpiry(data['expires_in']);
    final newRefreshToken =
        (data['refresh_token'] as String?) ?? refreshToken;
    await _storage.saveAccessToken(newAccessToken,
        expiresAt: expiresAt, refreshToken: newRefreshToken);
    return newAccessToken;
  }

  DateTime? _deriveExpiry(dynamic expiresIn) {
    if (expiresIn == null) {
      return null;
    }
    int? seconds;
    if (expiresIn is num) {
      seconds = expiresIn.toInt();
    } else if (expiresIn is String) {
      seconds = int.tryParse(expiresIn);
    }
    if (seconds == null || seconds <= 0) {
      return null;
    }
    return DateTime.now().add(Duration(seconds: seconds));
  }
}