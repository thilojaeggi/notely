import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:notely/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'navigation_service.dart';
import 'otp_helper.dart';
import '../widgets/two_factor_sheet.dart';
import 'package:notely/config/app_config.dart';

class TokenManager {
  TokenManager._internal();

  static final TokenManager _instance = TokenManager._internal();
  static const String _clientId = 'ppyybShnMerHdtBQ';
  static Future<String?>? _ongoingReauth;
  static bool _otpPromptActive = false;
  static DateTime? _lastOtpPrompt;

  final SecureStorage _storage = SecureStorage();

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
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) {
      return _runReauthOnce(school);
    }
    final expiry = await _storage.readAccessTokenExpiry();
    final now = DateTime.now();
    final isFresh = expiry != null && expiry.isAfter(now);
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
    debugPrint("Refreshing access token");
    return null; // Currently broken since school uses PHP session id garbage for some reason
    if (kIsWeb) {
      return null;
    }
    if (school.isEmpty) {
      return null;
    }
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final tokenUrlString = 'https://kaschuso.so.ch/public/$school/token.php';
    final tokenUrl = Uri.parse(
        kIsWeb ? 'https://lite.corsfix.com/?$tokenUrlString' : tokenUrlString);

    // NEW: Get cookies (PHPSESSID) to send with refresh request
    final cookieManager = CookieManager.instance();
    final cookies =
        await cookieManager.getCookies(url: WebUri("https://kaschuso.so.ch"));
    final cookieString = cookies.map((e) => "${e.name}=${e.value}").join("; ");

    final response = await http.post(
      tokenUrl,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json, text/plain, */*',
        'Cookie': cookieString,
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

    print("Refreshed access token: ${response.body}");
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final newAccessToken = data['access_token'] as String?;
    if (newAccessToken == null || newAccessToken.isEmpty) {
      await clearTokens();
      return null;
    }

    final expiresAt = deriveExpiry(data['expires_in']);
    final newRefreshToken = (data['refresh_token'] as String?) ?? refreshToken;
    await _storage.saveAccessToken(
      newAccessToken,
      expiresAt: expiresAt,
      refreshToken: newRefreshToken,
    );
    return newAccessToken;
  }

  Future<String?> _reAuthenticateWithStoredCredentials(String school) async {
    debugPrint("Reauthenticating with full flow");
    if (school.isEmpty) {
      return null;
    }
    var targetSchool = school;

    final prefs = await SharedPreferences.getInstance();
    final storedSchool = (prefs.getString("school") ?? school).toLowerCase();
    if (storedSchool != school) {
      // Keep school in sync with what was used during login
      targetSchool = storedSchool;
    }

    final username = await _storage.read(key: "username") ?? '';
    final password = await _storage.read(key: "password") ?? '';
    if (username.isEmpty || password.isEmpty) {
      return null;
    }

    final otpCode = await _maybeGenerateOtp();

    // Headless browser path: handles OTP pages and redirects.
    if (kIsWeb || AppConfig.forceWebFlow) {
      return _attemptWebReauth(targetSchool, username, password, otpCode);
    }
    return _attemptHeadlessReauth(targetSchool, username, password, otpCode);
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

  Future<String?> _attemptHeadlessReauth(
    String school,
    String username,
    String password,
    String? otpCode,
  ) async {
    if (kIsWeb) {
      return null;
    }

    final pkce = _generatePkce();
    final authUrlString = 'https://kaschuso.so.ch/public/$school/authorize.php'
        '?response_type=code'
        '&client_id=$_clientId'
        '&state=${pkce.state}'
        '&redirect_uri='
        '&scope=openid%20offline_access%20'
        '&code_challenge=${pkce.challenge}'
        '&code_challenge_method=S256'
        '&nonce=${pkce.state}';
    final authorizeUrl = Uri.parse(
        kIsWeb ? 'https://lite.corsfix.com/?$authUrlString' : authUrlString);

    final completer = Completer<String?>();
    HeadlessInAppWebView? headless;

    headless = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri.uri(authorizeUrl)),
        onLoadStop: (controller, url) async {
          final urlString = url?.toString() ?? '';
          if (urlString.contains('authorize.php')) {
            debugPrint("Reached authorize.php");
            try {
              final hasPinField = await controller.evaluateJavascript(
                  source: "document.querySelector('input#pin') != null;");
              final isPinPage =
                  hasPinField == true || hasPinField?.toString() == 'true';

              if (isPinPage) {
                final otp = otpCode ?? await _promptForOtpCode();
                if (otp == null || otp.isEmpty) {
                  debugPrint(
                      'Background reauth headless: OTP required but missing');
                  if (!completer.isCompleted) completer.complete(null);
                  return;
                }
                await controller.evaluateJavascript(source: """
                (function() {
                  var pinInput = document.getElementById('pin');
                  if (pinInput) { pinInput.value = '${otp.replaceAll("'", "\\'")}'; }
                  var submitBtn = document.querySelector('.login-submit');
                  if (submitBtn) { submitBtn.click(); }
                })();
              """);
              } else {
                await controller.evaluateJavascript(source: """
                (function() {
                  if (document.getElementById("login") && document.getElementById("passwort")) {
                    document.getElementById("login").value = "${_escapeForJS(username)}";
                    document.getElementById("passwort").value = "${_escapeForJS(password)}";
                    var submitBtn = document.querySelector('.login-submit');
                    if (submitBtn) { submitBtn.click(); }
                  }
                })();
              """);
              }
            } catch (e, s) {
              debugPrint('Headless reauth loadStop error: $e\n$s');
            }
          }
        },
        onUpdateVisitedHistory: (controller, url, _) async {
          final urlString = url?.toString() ?? '';
          if (urlString.startsWith('https://schulnetz.web.app/callback')) {
            final uri = Uri.parse(urlString);
            final code = uri.queryParameters['code'];
            final state = uri.queryParameters['state'];

            if (code != null && state == pkce.state) {
              // --- NEW: Extract Cookies ---
              final cookieManager = CookieManager.instance();
              final cookies = await cookieManager.getCookies(
                  url: WebUri("https://kaschuso.so.ch"));
              final cookieString =
                  cookies.map((e) => "${e.name}=${e.value}").join("; ");

              // Pass the cookieString to the exchange method
              final token = await _exchangeCodeForToken(
                  code, pkce.verifier, school, cookieString);
              if (!completer.isCompleted) completer.complete(token);
            }
          }
        });

    try {
      await headless?.run();
      await headless?.webViewController
          ?.loadUrl(urlRequest: URLRequest(url: WebUri.uri(authorizeUrl)));
      final result = await completer.future
          .timeout(const Duration(seconds: 20), onTimeout: () => null);
      return result;
    } catch (e, s) {
      debugPrint('Headless reauth error: $e\n$s');
      return null;
    } finally {
      try {
        await headless?.dispose();
      } catch (_) {}
    }
  }

  Future<String?> _promptForOtpCode() async {
    if (_otpPromptActive) {
      debugPrint('Background reauth headless: OTP sheet already active');
      return null;
    }
    final now = DateTime.now();
    if (_lastOtpPrompt != null &&
        now.difference(_lastOtpPrompt!) < const Duration(seconds: 1)) {
      debugPrint(
          'Background reauth headless: OTP prompt suppressed (cooldown)');
      return null;
    }

    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) {
      debugPrint(
          'Background reauth headless: no navigator context for OTP sheet');
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

  String _escapeForJS(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r');
  }

  _PkceBundle _generatePkce() {
    final rand = Random.secure();
    final verifierBytes = List<int>.generate(32, (_) => rand.nextInt(256));
    final verifier = _base64UrlNoPadding(verifierBytes);
    final digest = crypto.sha256.convert(utf8.encode(verifier));
    final challenge = _base64UrlNoPadding(digest.bytes);
    final stateBytes = List<int>.generate(16, (_) => rand.nextInt(256));
    final state = _base64UrlNoPadding(stateBytes);
    return _PkceBundle(
      verifier: verifier,
      challenge: challenge,
      state: state,
    );
  }

  String _base64UrlNoPadding(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  Future<String?> _exchangeCodeForToken(
    String code,
    String verifier,
    String school,
    String cookieString, // Add this parameter
  ) async {
    final tokenUrlString = "https://kaschuso.so.ch/public/$school/token.php";
    final tokenUrl = Uri.parse(
        kIsWeb ? 'https://lite.corsfix.com/?$tokenUrlString' : tokenUrlString);

    final resp = await http.post(
      tokenUrl,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json, text/plain, */*',
        'Cookie': cookieString, // Required to match the session
        'User-Agent':
            'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148',
        'Origin': 'https://schulnetz.web.app',
        'Referer': 'https://schulnetz.web.app',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': '',
        'code_verifier': verifier,
        'client_id': _clientId,
      },
    );

    if (resp.statusCode != 200 || resp.body.trim().isEmpty) {
      debugPrint(
          'Headless reauth: token exchange failed status=${resp.statusCode} body=${resp.body}');
      return null;
    }

    final jsonData = jsonDecode(resp.body) as Map<String, dynamic>;
    final accessToken = jsonData['access_token'] as String?;
    final refreshToken = jsonData['refresh_token'] as String?;
    final expiresAt = deriveExpiry(jsonData['expires_in']);

    if (accessToken == null || accessToken.isEmpty) return null;

    await _storage.saveAccessToken(
      accessToken,
      expiresAt: expiresAt,
      refreshToken: refreshToken,
    );

    return accessToken;
  }

  Future<String?> _attemptWebReauth(
    String school,
    String username,
    String password,
    String? otpCode,
  ) async {
    final apiBase = AppConfig.authProxyUrl;
    try {
      // 1. Send Credentials
      final loginUrl = Uri.parse('$apiBase/auth/login');
      final loginBody = jsonEncode({
        "username": username,
        "password": password,
        "school": school,
      });

      final loginResp = await http.post(
        loginUrl,
        headers: {'Content-Type': 'application/json'},
        body: loginBody,
      );

      if (loginResp.statusCode != 200 && loginResp.statusCode != 201) {
        debugPrint(
            'Web reauth login failed: ${loginResp.statusCode} ${loginResp.body}');
        return null; // Login failed
      }

      final loginData = jsonDecode(loginResp.body);
      final status = loginData['status'];

      String? accessToken;
      String? refreshToken;
      dynamic expiresIn;

      // 2. Handle OTP Requirement
      if (status == 'OTP_REQUIRED') {
        final sessionId = loginData['sessionId'];

        // Try provided OTP first (from secret), if not available or failed we might want to prompt
        // But here we'll keep it simple: use provided if available, else prompt.
        String? codeToUse = otpCode;
        bool usingAutoCode = codeToUse != null;

        codeToUse ??= await _promptForOtpCode();

        if (codeToUse == null || codeToUse.isEmpty) {
          debugPrint('Web reauth: OTP required but missing');
          return null;
        }

        // Helper to attempt OTP verification
        Future<Map<String, dynamic>?> verifyOtp(String code) async {
          final otpUrl = Uri.parse('$apiBase/auth/otp');
          final otpBody = jsonEncode({
            "sessionId": sessionId,
            "otp": code,
          });

          final otpResp = await http.post(
            otpUrl,
            headers: {'Content-Type': 'application/json'},
            body: otpBody,
          );

          if (otpResp.statusCode != 200 && otpResp.statusCode != 201) {
            return null;
          }
          return jsonDecode(otpResp.body);
        }

        var otpData = await verifyOtp(codeToUse);

        // If auto-generated code failed, give the user a chance to enter one manually
        if ((otpData == null || otpData['status'] != 'SUCCESS') &&
            usingAutoCode) {
          debugPrint('Web reauth: Auto OTP failed, prompting user...');
          codeToUse = await _promptForOtpCode();
          if (codeToUse != null && codeToUse.isNotEmpty) {
            otpData = await verifyOtp(codeToUse);
          }
        }

        if (otpData != null && otpData['status'] == 'SUCCESS') {
          accessToken = otpData['access_token'];
          refreshToken = otpData['refresh_token'];
          expiresIn = otpData['expires_in'];
        } else {
          debugPrint('Web reauth OTP failed or status not SUCCESS');
          return null;
        }
      } else if (status == 'SUCCESS') {
        // Direct success (no OTP)
        accessToken = loginData['access_token'];
        refreshToken = loginData['refresh_token'];
        expiresIn = loginData['expires_in'];
      } else {
        debugPrint('Web reauth: Unknown login status: $status');
        return null;
      }

      // 4. Save Token if we got one
      if (accessToken != null) {
        final expiresAt = deriveExpiry(expiresIn);
        final newRefreshToken =
            refreshToken ?? await _storage.readRefreshToken();

        await _storage.saveAccessToken(
          accessToken,
          expiresAt: expiresAt,
          refreshToken: newRefreshToken,
        );

        return accessToken;
      }
    } catch (e, s) {
      debugPrint('Web reauth error: $e\n$s');
    }
    return null;
  }
}

class _PkceBundle {
  final String verifier;
  final String challenge;
  final String state;

  _PkceBundle({
    required this.verifier,
    required this.challenge,
    required this.state,
  });
}
