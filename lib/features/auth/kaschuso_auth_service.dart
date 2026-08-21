import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

import 'token_manager.dart' show InvalidCredentialsException;

class KaschusoAuthException implements Exception {
  final String message;
  const KaschusoAuthException(this.message);

  @override
  String toString() => 'KaschusoAuthException: $message';
}

class KaschusoInvalidCredentialsException extends KaschusoAuthException
    implements InvalidCredentialsException {
  const KaschusoInvalidCredentialsException(String message) : super(message);

  @override
  String toString() => 'KaschusoInvalidCredentialsException: $message';
}

class KaschusoOtpRequiredException extends KaschusoAuthException {
  const KaschusoOtpRequiredException(
      [String message = 'Zwei-Faktor-Authentifizierung erforderlich'])
      : super(message);

  @override
  String toString() => 'KaschusoOtpRequiredException: $message';
}

class KaschusoTokens {
  final String accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final DateTime? expiresAt;
  final String? tokenType;

  KaschusoTokens({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.expiresAt,
    this.tokenType,
  });

  factory KaschusoTokens.fromJson(Map<String, dynamic> json) {
    final accessToken = json['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw const KaschusoAuthException('Ungültige Server-Antwort: Kein access_token vorhanden');
    }

    final refreshToken = json['refresh_token'] as String?;
    final expiresInRaw = json['expires_in'];
    int? expiresIn;
    if (expiresInRaw is num) {
      expiresIn = expiresInRaw.toInt();
    } else if (expiresInRaw is String) {
      expiresIn = int.tryParse(expiresInRaw);
    }

    DateTime? expiresAt;
    if (expiresIn != null && expiresIn > 0) {
      expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    }

    return KaschusoTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
      expiresAt: expiresAt,
      tokenType: json['token_type'] as String?,
    );
  }
}

class PkceBundle {
  final String verifier;
  final String challenge;
  final String state;
  final String nonce;

  const PkceBundle({
    required this.verifier,
    required this.challenge,
    required this.state,
    required this.nonce,
  });
}

class KaschusoAuthService {
  static const String clientId = 'ppyybShnMerHdtBQ';
  static const String _userAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148';

  final http.Client _client;

  // State maintained for 2FA continuation
  PkceBundle? _activePkce;
  String? _activeSchool;
  String? _activeAuthUrl;
  String? _activeOtpActionUrl;
  Map<String, String> _activeOtpHiddenFields = {};
  final Map<String, String> _cookies = {};

  KaschusoAuthService({http.Client? client}) : _client = client ?? http.Client();

  /// Public getter to check if an OTP session is currently waiting
  bool get hasActiveSession => _activePkce != null && _activeSchool != null;

  /// Helper to base64url encode without padding
  static String base64UrlNoPad(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Generates a new PKCE bundle and random state/nonce
  static PkceBundle generatePkce() {
    final rand = Random.secure();
    final verifierBytes = List<int>.generate(32, (_) => rand.nextInt(256));
    final verifier = base64UrlNoPad(verifierBytes);

    final digest = crypto.sha256.convert(utf8.encode(verifier));
    final challenge = base64UrlNoPad(digest.bytes);

    final state = base64UrlNoPad(List<int>.generate(16, (_) => rand.nextInt(256)));
    final nonce = base64UrlNoPad(List<int>.generate(16, (_) => rand.nextInt(256)));

    return PkceBundle(
      verifier: verifier,
      challenge: challenge,
      state: state,
      nonce: nonce,
    );
  }

  /// Executes full login flow. If 2FA is needed and [otpCode] is null,
  /// throws [KaschusoOtpRequiredException] and retains session for [submitOtp].
  Future<KaschusoTokens> login({
    required String username,
    required String password,
    required String school,
    String? otpCode,
  }) async {
    final normalizedSchool = school.trim().toLowerCase();
    _activeSchool = normalizedSchool;
    _activePkce = generatePkce();
    _cookies.clear();
    _activeOtpHiddenFields.clear();

    final authUrlString = 'https://kaschuso.so.ch/public/$normalizedSchool/authorize.php'
        '?response_type=code'
        '&client_id=$clientId'
        '&state=${_activePkce!.state}'
        '&redirect_uri='
        '&scope=openid%20offline_access'
        '&code_challenge=${_activePkce!.challenge}'
        '&code_challenge_method=S256'
        '&nonce=${_activePkce!.nonce}'
        '&id=';

    _activeAuthUrl = authUrlString;
    final authUri = Uri.parse(authUrlString);

    debugPrint('[KaschusoAuth] Starting login for $normalizedSchool ($username)');

    // Step 1: Initial GET to initialize PHP session and retrieve cookies / hidden fields
    final initResp = await _sendRequest(
      http.Request('GET', authUri)..followRedirects = false,
      referer: authUrlString,
    );

    _recordCookies(initResp.headers);
    debugPrint('[KaschusoAuth] GET authorize.php -> ${initResp.statusCode}, cookies: ${_cookies.keys.join(", ")}');

    // Parse hidden fields (e.g. loginhash) and form action from initial form
    final hiddenFields = _extractHiddenInputs(initResp.body);
    final postUrl = _resolveFormAction(initResp.body, authUrlString, normalizedSchool);
    final postUri = Uri.parse(postUrl);

    // Step 2: POST credentials
    final formBody = <String, String>{
      ...hiddenFields,
      'login': username,
      'passwort': password,
    };

    final postRequest = http.Request('POST', postUri)
      ..followRedirects = false
      ..headers['Content-Type'] = 'application/x-www-form-urlencoded'
      ..bodyFields = formBody;

    final postResp = await _sendRequest(
      postRequest,
      referer: authUrlString,
    );

    _recordCookies(postResp.headers);
    debugPrint('[KaschusoAuth] POST login -> ${postResp.statusCode}, location: ${postResp.headers["location"]}');

    // Check if code was returned directly (e.g. 302 Found)
    final code = _extractCodeFromResponse(postResp);
    if (code != null && code.isNotEmpty) {
      debugPrint('[KaschusoAuth] Direct login success with code: $code');
      final tokens = await exchangeCodeForToken(
        code: code,
        verifier: _activePkce!.verifier,
        school: normalizedSchool,
      );
      _clearActiveSession();
      return tokens;
    }

    // Check for 2FA requirement (#pin)
    if (_isOtpRequiredPage(postResp.body)) {
      debugPrint('[KaschusoAuth] 2FA page detected');
      _activeOtpActionUrl = _resolveFormAction(postResp.body, authUrlString, normalizedSchool);
      _activeOtpHiddenFields = _extractHiddenInputs(postResp.body);

      if (otpCode != null && otpCode.trim().isNotEmpty) {
        debugPrint('[KaschusoAuth] Submitting pre-provided OTP');
        return submitOtp(otpCode: otpCode.trim());
      }
      throw const KaschusoOtpRequiredException();
    }

    // Check for error in HTML
    final errorMsg = _extractErrorMessage(postResp.body);
    _clearActiveSession();
    if (errorMsg != null) {
      debugPrint('[KaschusoAuth] Login rejected: $errorMsg');
      throw KaschusoInvalidCredentialsException(errorMsg);
    }

    throw const KaschusoAuthException('Anmeldung fehlgeschlagen. Bitte Zugangsdaten prüfen.');
  }

  /// Submits OTP/2FA PIN for the ongoing session.
  Future<KaschusoTokens> submitOtp({required String otpCode}) async {
    if (!hasActiveSession) {
      throw const KaschusoAuthException('Keine aktive Login-Sitzung. Bitte erneut anmelden.');
    }

    final school = _activeSchool!;
    final verifier = _activePkce!.verifier;
    final targetUrl = _activeOtpActionUrl ?? _activeAuthUrl!;
    final targetUri = Uri.parse(targetUrl);

    debugPrint('[KaschusoAuth] Submitting OTP to $targetUrl');

    final formBody = <String, String>{
      ..._activeOtpHiddenFields,
      'pin': otpCode.trim(),
    };

    final otpRequest = http.Request('POST', targetUri)
      ..followRedirects = false
      ..headers['Content-Type'] = 'application/x-www-form-urlencoded'
      ..bodyFields = formBody;

    final otpResp = await _sendRequest(
      otpRequest,
      referer: _activeAuthUrl ?? targetUrl,
    );

    _recordCookies(otpResp.headers);
    debugPrint('[KaschusoAuth] POST submitOtp -> ${otpResp.statusCode}, location: ${otpResp.headers["location"]}');

    final code = _extractCodeFromResponse(otpResp);
    if (code != null && code.isNotEmpty) {
      debugPrint('[KaschusoAuth] OTP verified, code received: $code');
      final tokens = await exchangeCodeForToken(
        code: code,
        verifier: verifier,
        school: school,
      );
      _clearActiveSession();
      return tokens;
    }

    // Check if error message present
    final errorMsg = _extractErrorMessage(otpResp.body);
    if (errorMsg != null) {
      debugPrint('[KaschusoAuth] OTP error message: $errorMsg');
      throw KaschusoAuthException(errorMsg);
    }

    if (_isOtpRequiredPage(otpResp.body)) {
      debugPrint('[KaschusoAuth] PIN field still visible (OTP invalid)');
      _activeOtpActionUrl = _resolveFormAction(otpResp.body, targetUrl, school);
      _activeOtpHiddenFields = _extractHiddenInputs(otpResp.body);
      throw const KaschusoAuthException('Ungültiger Bestätigungscode. Bitte erneut eingeben.');
    }

    _clearActiveSession();
    throw const KaschusoAuthException('2FA-Verifizierung fehlgeschlagen.');
  }

  /// Exchanges authorization code for tokens via token.php
  Future<KaschusoTokens> exchangeCodeForToken({
    required String code,
    required String verifier,
    required String school,
  }) async {
    final normalizedSchool = school.trim().toLowerCase();
    final tokenUrl = Uri.parse('https://kaschuso.so.ch/public/$normalizedSchool/token.php');

    final headers = <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json, text/plain, */*',
      'User-Agent': _userAgent,
      'Origin': 'https://schulnetz.web.app',
      'Referer': 'https://schulnetz.web.app',
      if (_cookies.isNotEmpty) 'Cookie': _buildCookieHeader(),
    };

    final body = <String, String>{
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': '',
      'code_verifier': verifier,
      'client_id': clientId,
    };

    final resp = await _client.post(tokenUrl, headers: headers, body: body);

    if (resp.statusCode != 200 || resp.body.trim().isEmpty) {
      debugPrint('[KaschusoAuth] token.php error [${resp.statusCode}]: ${resp.body}');
      throw KaschusoAuthException(
          'Token-Austausch fehlgeschlagen (Status: ${resp.statusCode})');
    }

    debugPrint('[KaschusoAuth] Token exchange successful');
    final jsonData = jsonDecode(resp.body) as Map<String, dynamic>;
    return KaschusoTokens.fromJson(jsonData);
  }

  /// Refreshes access token via token.php using refresh_token grant
  Future<KaschusoTokens?> refreshToken({
    required String school,
    required String refreshToken,
  }) async {
    final normalizedSchool = school.trim().toLowerCase();
    final tokenUrl = Uri.parse('https://kaschuso.so.ch/public/$normalizedSchool/token.php');

    final headers = <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json, text/plain, */*',
      'User-Agent': _userAgent,
      if (_cookies.isNotEmpty) 'Cookie': _buildCookieHeader(),
    };

    final body = <String, String>{
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
      'client_id': clientId,
    };

    try {
      final resp = await _client.post(tokenUrl, headers: headers, body: body);
      if (resp.statusCode != 200 || resp.body.trim().isEmpty) {
        return null;
      }

      final jsonData = jsonDecode(resp.body) as Map<String, dynamic>;
      return KaschusoTokens.fromJson(jsonData);
    } catch (e) {
      debugPrint('[KaschusoAuth] refreshToken error: $e');
      return null;
    }
  }

  // --- Internal Helpers ---

  Future<http.Response> _sendRequest(
    http.Request request, {
    required String referer,
  }) async {
    request.headers['User-Agent'] = _userAgent;
    request.headers['Referer'] = referer;
    request.headers['Origin'] = 'https://kaschuso.so.ch';
    if (_cookies.isNotEmpty) {
      request.headers['Cookie'] = _buildCookieHeader();
    }

    final streamedResponse = await _client.send(request);
    return http.Response.fromStream(streamedResponse);
  }

  void _recordCookies(Map<String, String> headers) {
    final setCookie = headers['set-cookie'] ?? headers['Set-Cookie'];
    if (setCookie == null || setCookie.isEmpty) return;

    // Use regex to find key=value pairs while ignoring cookie attributes like expires, path, etc.
    final cookieRegex = RegExp(r'(?:^|,\s*)([a-zA-Z0-9_\-\.]+)=([^;,\s]+)');
    for (final match in cookieRegex.allMatches(setCookie)) {
      final key = match.group(1);
      final val = match.group(2);
      if (key != null && val != null) {
        final lowerKey = key.toLowerCase();
        if (lowerKey != 'expires' &&
            lowerKey != 'max-age' &&
            lowerKey != 'path' &&
            lowerKey != 'domain' &&
            lowerKey != 'samesite' &&
            lowerKey != 'secure' &&
            lowerKey != 'httponly') {
          _cookies[key] = val;
        }
      }
    }
  }

  String _buildCookieHeader() {
    return _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  void _clearActiveSession() {
    _activePkce = null;
    _activeSchool = null;
    _activeAuthUrl = null;
    _activeOtpActionUrl = null;
    _activeOtpHiddenFields.clear();
  }

  String _resolveFormAction(String html, String defaultUrl, String school) {
    try {
      final doc = parser.parse(html);
      final form = doc.querySelector('form');
      final action = form?.attributes['action'];
      if (action != null && action.trim().isNotEmpty) {
        final cleanAction = action.trim().replaceAll('&amp;', '&');
        if (cleanAction.startsWith('http://') || cleanAction.startsWith('https://')) {
          return cleanAction;
        }
        if (cleanAction.startsWith('/')) {
          return 'https://kaschuso.so.ch$cleanAction';
        }
        if (cleanAction.startsWith('authorize.php') || cleanAction.startsWith('?')) {
          final query = cleanAction.contains('?')
              ? cleanAction.substring(cleanAction.indexOf('?'))
              : '';
          return 'https://kaschuso.so.ch/public/$school/authorize.php$query';
        }
      }
    } catch (_) {}
    return defaultUrl;
  }

  Map<String, String> _extractHiddenInputs(String html) {
    final hiddenFields = <String, String>{};
    try {
      final doc = parser.parse(html);
      final inputs = doc.querySelectorAll('input[type="hidden"]');
      for (final input in inputs) {
        final name = input.attributes['name'];
        final value = input.attributes['value'] ?? '';
        if (name != null && name.isNotEmpty) {
          hiddenFields[name] = value;
        }
      }
    } catch (_) {}
    return hiddenFields;
  }

  bool _isOtpRequiredPage(String html) {
    try {
      final doc = parser.parse(html);
      if (doc.querySelector('input#pin') != null ||
          doc.querySelector('input[name="pin"]') != null) {
        return true;
      }
      if (html.contains('id="pin"') || html.contains('name="pin"')) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  String? _extractCodeFromResponse(http.Response response) {
    // 1. Check Location header (302 redirect)
    final location = response.headers['location'];
    if (location != null && location.isNotEmpty) {
      final parsed = Uri.tryParse(location);
      if (parsed != null && parsed.queryParameters.containsKey('code')) {
        return parsed.queryParameters['code'];
      }
      final regexMatch = RegExp(r'[?&]code=([a-zA-Z0-9_\-\.]+)').firstMatch(location);
      if (regexMatch != null) {
        return regexMatch.group(1);
      }
    }

    // 2. Check response body for embedded redirect code or query param
    final bodyMatch = RegExp(r'[?&]code=([a-zA-Z0-9_\-\.]+)').firstMatch(response.body);
    if (bodyMatch != null) {
      return bodyMatch.group(1);
    }

    return null;
  }

  String? _extractErrorMessage(String html) {
    try {
      final doc = parser.parse(html);
      final errorNode =
          doc.querySelector('.mdl-cell.mdl-cell--12-col[style*="#ffb138"]');
      if (errorNode != null) {
        final text = errorNode.text.trim();
        if (text.isNotEmpty) {
          return text.replaceAll(' Ihre Aktion wurde aufgezeichnet.', '');
        }
      }

      final bodyText = doc.body?.text ?? '';
      if (bodyText.toLowerCase().contains('fehler:')) {
        final lines = bodyText.split('\n').map((l) => l.trim());
        for (final line in lines) {
          if (line.toLowerCase().startsWith('fehler')) {
            return line.replaceAll(' Ihre Aktion wurde aufgezeichnet.', '');
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
