import 'dart:async';

import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:notely/core/storage/secure_storage.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/navigation/navigation_service.dart';
import '../../pages/login_page.dart';
import 'kaschuso_auth_service.dart';
import 'otp_helper.dart';
import 'widgets/two_factor_sheet.dart';

class InvalidCredentialsException implements Exception {
  final String message;
  InvalidCredentialsException(this.message);
  @override
  String toString() => 'InvalidCredentialsException: $message';
}

class TokenManager {
  TokenManager._internal();

  static final TokenManager _instance = TokenManager._internal();
  static Future<String?>? _ongoingReauth;
  static bool _otpPromptActive = false;
  static DateTime? _lastOtpPrompt;

  final SecureStorage _storage = SecureStorage();
  final KaschusoAuthService _authService = KaschusoAuthService();

  factory TokenManager() => _instance;

  static DateTime? deriveExpiry(dynamic expiresIn) {
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

  Future<String?> getValidAccessToken(String school) async {
    // Read token and expiry in parallel
    final results = await Future.wait([
      _storage.readAccessToken(),
      _storage.readAccessTokenExpiry(),
    ]);
    final token = results[0] as String?;
    final expiry = results[1] as DateTime?;

    if (token == null || token.isEmpty) {
      return _runReauthOnce(school);
    }

    final isFresh = expiry != null && expiry.isAfter(DateTime.now());
    if (isFresh) return token;

    // Expired or missing expiry -> try to refresh, otherwise force re-auth
    final refreshed = await refreshAccessToken(school);
    if (refreshed != null && refreshed.isNotEmpty) {
      return refreshed;
    }
    return _runReauthOnce(school);
  }

  Future<String?> _runReauthOnce(String school) {
    if (_ongoingReauth != null) {
      debugPrint('Reauth already running, joining existing future');
      return _ongoingReauth!;
    }

    final completer = Completer<String?>();
    _ongoingReauth = completer.future;

    _reAuthenticateWithStoredCredentials(school).then((value) {
      completer.complete(value);
    }).catchError((e, s) {
      completer.completeError(e, s);
    }).whenComplete(() {
      _ongoingReauth = null;
    });

    return completer.future;
  }

  Future<void> clearTokens() async {
    await _storage.clearAccessToken();
  }

  Future<String?> refreshAccessToken(String school) async {
    if (school.isEmpty) {
      return null;
    }
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    debugPrint("Attempting token refresh for $school");
    try {
      final tokens = await _authService.refreshToken(
        school: school,
        refreshToken: refreshToken,
      );

      if (tokens != null && tokens.accessToken.isNotEmpty) {
        debugPrint("Successfully refreshed access token");
        await _storage.saveAccessToken(
          tokens.accessToken,
          expiresAt: tokens.expiresAt,
          refreshToken: tokens.refreshToken ?? refreshToken,
        );
        return tokens.accessToken;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }

    // Refresh token expired or rejected
    await clearTokens();
    return null;
  }

  Future<String?> _reAuthenticateWithStoredCredentials(String school) async {
    debugPrint("Reauthenticating with full native flow");
    if (school.isEmpty) {
      return null;
    }
    var targetSchool = school;

    final prefs = await SharedPreferences.getInstance();
    final storedSchool = (prefs.getString("school") ?? school).toLowerCase();
    if (storedSchool != school && storedSchool.isNotEmpty) {
      targetSchool = storedSchool;
    }

    final username = await _storage.read(key: "username") ?? '';
    final password = await _storage.read(key: "password") ?? '';
    if (username.isEmpty || password.isEmpty) {
      return null;
    }

    final otpCode = await _maybeGenerateOtp();

    try {
      KaschusoTokens tokens;
      try {
        tokens = await _authService.login(
          username: username,
          password: password,
          school: targetSchool,
          otpCode: otpCode,
        );
      } on KaschusoOtpRequiredException {
        // Stored OTP secret was missing or didn't pass, prompt user
        debugPrint('Reauth requires manual OTP');
        final manualOtp = await _promptForOtpCode();
        if (manualOtp == null || manualOtp.isEmpty) {
          debugPrint('User cancelled or empty OTP for reauth');
          return null;
        }
        tokens = await _authService.submitOtp(otpCode: manualOtp);
      }

      await _storage.saveAccessToken(
        tokens.accessToken,
        expiresAt: tokens.expiresAt,
        refreshToken: tokens.refreshToken,
      );

      return tokens.accessToken;
    } on KaschusoInvalidCredentialsException catch (e) {
      debugPrint('Reauth invalid credentials: ${e.message}');
      await clearTokens();
      await _storage.delete(key: "password");
      _redirectToLogin(e.message);
      throw InvalidCredentialsException(e.message);
    } catch (e, s) {
      debugPrint('Reauth error: $e\n$s');
      return null;
    }
  }

  void _redirectToLogin(String reason) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = NavigationService.navigatorKey.currentState;
      final context = NavigationService.navigatorKey.currentContext;
      if (nav != null && context != null) {
        nav.pushAndRemoveUntil(
          PageTransition(
            type: PageTransitionType.fade,
            alignment: Alignment.bottomCenter,
            child: const LoginPage(),
          ),
          (route) => false,
        );

        showToast(
          alignment: Alignment.bottomCenter,
          duration: const Duration(seconds: 3),
          child: Container(
            margin: const EdgeInsets.only(bottom: 32.0),
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
            ),
            padding: const EdgeInsets.all(10.0),
            child: Text(
              reason,
              style: const TextStyle(color: Colors.white, fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
          ),
          context: context,
        );
      }
    });
  }

  Future<String?> _maybeGenerateOtp() async {
    String? otpCode;
    try {
      final secret = await _storage.readOtpSecret();
      if (secret != null && secret.isNotEmpty) {
        otpCode = OtpHelper.generateTotp(secret);
        debugPrint(
            'Background reauth: OTP secret found, generated code ${otpCode == null ? 'null' : 'present'}');
      } else {
        debugPrint('Background reauth: No OTP secret stored');
      }
    } catch (e, s) {
      debugPrint('Failed generating OTP for background reauth: $e\n$s');
    }
    return otpCode;
  }

  Future<String?> _promptForOtpCode() async {
    if (_otpPromptActive) {
      debugPrint('Background reauth: OTP sheet already active');
      return null;
    }
    final now = DateTime.now();
    if (_lastOtpPrompt != null &&
        now.difference(_lastOtpPrompt!) < const Duration(seconds: 1)) {
      debugPrint('Background reauth: OTP prompt suppressed (cooldown)');
      return null;
    }

    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) {
      debugPrint('Background reauth: no navigator context for OTP sheet');
      return null;
    }

    _otpPromptActive = true;
    final controller = TextEditingController();
    try {
      final result = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        constraints: const BoxConstraints(
          maxWidth: 700,
        ),
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => TwoFactorSheet(textController: controller),
      );
      return result?.trim();
    } finally {
      controller.dispose();
      _otpPromptActive = false;
      _lastOtpPrompt = DateTime.now();
    }
  }
}
