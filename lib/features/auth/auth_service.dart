import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notely/data/api_client.dart';
import 'package:notely/core/storage/secure_storage.dart';
import 'package:notely/features/auth/auth_result.dart';
import 'package:notely/features/auth/token_manager.dart';

class AuthService {
  static final SecureStorage _storage = SecureStorage();

  static Future<AuthResult> login() async {
    final APIClient client = APIClient();

    // Read all stored data in parallel for faster startup
    final results = await Future.wait([
      SharedPreferences.getInstance(),
      _storage.read(key: "username"),
      _storage.read(key: "password"),
      _storage.read(key: "school"),
    ]);

    final prefs = results[0] as SharedPreferences;
    final prefsSchool = prefs.getString("school")?.toLowerCase() ?? '';
    final secureSchool = (results[3] as String?)?.toLowerCase() ?? '';
    final school = prefsSchool.isNotEmpty ? prefsSchool : secureSchool;
    final username = (results[1] as String?) ?? '';
    final password = (results[2] as String?) ?? '';
    final tokenManager = TokenManager();

    // Restore school to SharedPreferences if only found in SecureStorage
    if (prefsSchool.isEmpty && school.isNotEmpty) {
      await prefs.setString("school", school);
    }

    if (username == "demo" && password == "demo") {
      client.fakeData = true;
      client.school = "demo";
      return AuthResult.authenticated;
    }

    if (school.isEmpty || username.isEmpty || password.isEmpty) {
      return AuthResult.unauthenticated;
    }

    try {
      final token = await tokenManager.getValidAccessToken(school);

      if (token != null && token.isNotEmpty) {
        client.accessToken = token;
        client.school = school;
        debugPrint("Logged in via TokenManager");
        return AuthResult.authenticated;
      }

      // Token acquisition failed (network/timeout) but credentials exist.
      // Let APIClient._ensureValidAccessToken() retry lazily.
      client.school = school;
      debugPrint("Credentials stored, deferring token acquisition");
      return AuthResult.deferred;
    } on InvalidCredentialsException {
      debugPrint("Stored credentials are invalid, showing login page");
      return AuthResult.unauthenticated;
    }
  }
}
