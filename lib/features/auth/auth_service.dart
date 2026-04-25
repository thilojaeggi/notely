import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notely/data/api_client.dart';
import 'package:notely/core/storage/secure_storage.dart';
import 'package:notely/features/auth/token_manager.dart';

class AuthService {
  static final SecureStorage _storage = SecureStorage();

  static Future<bool> login() async {
    final APIClient client = APIClient();
    final prefs = await SharedPreferences.getInstance();
    final school = prefs.getString("school")?.toLowerCase() ?? '';
    final username = await _storage.read(key: "username") ?? '';
    final password = await _storage.read(key: "password") ?? '';
    final tokenManager = TokenManager();

    if (username == "demo" && password == "demo") {
      client.fakeData = true;
      client.school = "demo";
      return true;
    }

    if (school.isEmpty) {
      return false;
    }

    // Use TokenManager to handle everything (cache, refresh, re-auth)
    final token = await tokenManager.getValidAccessToken(school);

    if (token != null && token.isNotEmpty) {
      client.accessToken = token;
      client.school = school;
      debugPrint("Logged in via TokenManager");
      return true;
    }

    return false;
  }
}
