import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:notely/Globals.dart';
import 'package:notely/helpers/api_client.dart';
import 'package:notely/helpers/token_manager.dart';
import 'package:notely/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { unknown, checking, unauthenticated, authenticating, authenticated }

class SavedCredentials {
  final String username;
  final String password;
  final String schoolCode;

  const SavedCredentials({
    required this.username,
    required this.password,
    required this.schoolCode,
  });

  bool get hasCredentials =>
      username.isNotEmpty && password.isNotEmpty && schoolCode.isNotEmpty;

  bool get isDemo =>
      username.trim().toLowerCase() == 'demo' &&
      password.trim().toLowerCase() == 'demo';
}

class AuthManager extends ChangeNotifier {
  AuthManager._internal();

  static final AuthManager _instance = AuthManager._internal();
  static const String _clientId = 'ppyybShnMerHdtBQ';

  final SecureStorage _storage = SecureStorage();
  final APIClient _apiClient = APIClient();
  final TokenManager _tokenManager = TokenManager();

  AuthStatus _status = AuthStatus.unknown;
  bool _initializing = false;

  HeadlessInAppWebView? _headlessWebView;
  bool _headlessRunning = false;

  String? _codeVerifier;
  String? _codeChallenge;
  String? _oauthState;

  String? _pendingUsername;
  String? _pendingPassword;
  String? _pendingSchool;
  BuildContext? _activeContext;
  Future<String?> Function()? _otpRequest;

  factory AuthManager() => _instance;

  AuthStatus get status => _status;
  bool get isAuthenticating => _status == AuthStatus.authenticating;

  Future<void> initialize() async {
    if (_initializing) return;
    _initializing = true;
    _setStatus(AuthStatus.checking);

    try {
      final saved = await loadSavedCredentials();
      if (saved.isDemo) {
        _apiClient.fakeData = true;
        _apiClient.school = 'demo';
        _setStatus(AuthStatus.authenticated);
        return;
      }

      final school = saved.schoolCode.toLowerCase();
      if (school.isEmpty) {
        return;
      }

      final token = await _tokenManager.getValidAccessToken(school);
      if (token != null && token.isNotEmpty) {
        _apiClient.fakeData = false;
        _apiClient.accessToken = token;
        _apiClient.school = school;
        _setStatus(AuthStatus.authenticated);
        return;
      }
    } catch (e, s) {
      debugPrint('Auth initialization failed: $e\n$s');
    } finally {
      if (_status == AuthStatus.checking) {
        _setStatus(AuthStatus.unauthenticated);
      }
      _initializing = false;
    }
  }

  Future<SavedCredentials> loadSavedCredentials() async {
    final username = await _storage.read(key: "username") ?? '';
    final password = await _storage.read(key: "password") ?? '';
    final prefs = await SharedPreferences.getInstance();
    final school = (prefs.getString("school") ?? '').toUpperCase();
    return SavedCredentials(
      username: username,
      password: password,
      schoolCode: school,
    );
  }

  Future<void> signIn({
    required BuildContext context,
    required String username,
    required String password,
    required String schoolCode,
    required Future<String?> Function() requestOtpCode,
  }) async {
    if (isAuthenticating) return;

    final trimmedUsername = username.trim();
    final trimmedPassword = password.trim();
    final normalizedSchool = schoolCode.trim().toLowerCase();

    if (trimmedUsername.isEmpty || trimmedPassword.isEmpty) {
      _showToast(
        context,
        message: "Bitte Benutzername und Passwort eingeben",
        isError: true,
      );
      return;
    }

    if (normalizedSchool.isEmpty) {
      _showToast(
        context,
        message: "Bitte Schule auswählen",
        isError: true,
      );
      return;
    }

    _activeContext = context;
    _otpRequest = requestOtpCode;
    _pendingUsername = trimmedUsername;
    _pendingPassword = trimmedPassword;
    _pendingSchool = normalizedSchool;

    _setStatus(AuthStatus.authenticating);

    try {
      if (_isDemoLogin(trimmedUsername, trimmedPassword)) {
        await _handleDemoLogin(context);
        return;
      }

      await _disposeHeadlessWebView();
      await _performAuthorizeRequest();
    } catch (e, s) {
      debugPrint('Login failed: $e\n$s');
      _showToast(
        context,
        message: "Etwas ist schiefgelaufen",
        isError: true,
      );
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  Future<void> logout() async {
    await _disposeHeadlessWebView();
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("school");
    _apiClient.fakeData = false;
    try {
      _apiClient.accessToken = '';
    } catch (_) {
      // Ignore if accessToken was never set.
    }
    _setStatus(AuthStatus.unauthenticated);
  }

  Future<void> _performAuthorizeRequest() async {
    if (_pendingUsername == null ||
        _pendingPassword == null ||
        _pendingSchool == null) {
      _setStatus(AuthStatus.unauthenticated);
      return;
    }

    _generatePkceAndState();

    final authorizeUrl = Globals.buildUrl(
        "${_pendingSchool!}/authorize.php?response_type=code"
        "&client_id=$_clientId"
        "&state=${_oauthState!}"
        "&redirect_uri="
        "&scope=openid%20offline_access"
        "&code_challenge=${_codeChallenge!}"
        "&code_challenge_method=S256"
        "&nonce=${_oauthState!}");

    final response = await http.post(
      authorizeUrl,
      body: {
        "login": _pendingUsername!,
        "passwort": _pendingPassword!,
      },
      headers: {
        'accept-encoding': 'gzip, deflate',
        'access-control-allow-credentials': 'true',
        'access-control-allow-headers': '*',
        'access-control-allow-methods': '*',
        'access-control-allow-origin': '*',
        'access-control-expose-headers': '*'
      },
    );

    final location = response.headers['location'];

    if (response.statusCode == 302 && location != null) {
      if (location.contains('#access_token=')) {
        await _handleLegacyTokenResponse(location);
        return;
      }

      final uri = Uri.tryParse(location);
      final code = uri?.queryParameters['code'];
      if (code != null) {
        await _exchangeCodeForToken(code);
        return;
      }
    } else if (response.statusCode == 200 && location == null) {
      await _startHeadlessFlow();
      return;
    }

    _showToast(
      _activeContext,
      message: "Etwas ist schiefgelaufen",
      isError: true,
    );
    _setStatus(AuthStatus.unauthenticated);
  }

  Future<void> _handleLegacyTokenResponse(String locationHeader) async {
    if (_pendingSchool == null) {
      _setStatus(AuthStatus.unauthenticated);
      return;
    }

    var trimmed = locationHeader.substring(0, locationHeader.indexOf('&'));
    trimmed = trimmed
        .substring(trimmed.indexOf("#") + 1)
        .replaceAll("access_token=", "");

    await _saveCredentials(
      username: _pendingUsername!,
      password: _pendingPassword!,
      school: _pendingSchool!,
    );

    await _storage.saveAccessToken(trimmed);
    _apiClient.fakeData = false;
    _apiClient.accessToken = trimmed;
    _apiClient.school = _pendingSchool!;

    _showToast(
      _activeContext,
      message: "Erfolgreich angemeldet",
    );
    _setStatus(AuthStatus.authenticated);
  }

  Future<void> _exchangeCodeForToken(String code) async {
    if (_pendingSchool == null || _codeVerifier == null) {
      _setStatus(AuthStatus.unauthenticated);
      return;
    }

    final tokenUrl =
        Uri.parse("https://kaschuso.so.ch/public/${_pendingSchool!}/token.php");

    final response = await http.post(
      tokenUrl,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json, text/plain, */*',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': '',
        'code_verifier': _codeVerifier!,
        'client_id': _clientId,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = data['access_token'] as String?;
      if (accessToken == null || accessToken.isEmpty) {
        _showToast(
          _activeContext,
          message: "Kein Zugriffstoken erhalten",
          isError: true,
        );
        _setStatus(AuthStatus.unauthenticated);
        return;
      }

      final expiresAt = _deriveExpiry(data['expires_in']);
      final refreshToken = data['refresh_token'] as String?;

      await _saveCredentials(
        username: _pendingUsername!,
        password: _pendingPassword!,
        school: _pendingSchool!,
      );

      await _storage.saveAccessToken(
        accessToken,
        expiresAt: expiresAt,
        refreshToken: refreshToken,
      );

      _apiClient.fakeData = false;
      _apiClient.accessToken = accessToken;
      _apiClient.school = _pendingSchool!;

      _showToast(
        _activeContext,
        message: "Erfolgreich angemeldet",
      );
      _setStatus(AuthStatus.authenticated);
    } else {
      _showToast(
        _activeContext,
        message: "2FA-Token konnte nicht geholt werden",
        isError: true,
      );
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  Future<void> _startHeadlessFlow() async {
    if (kIsWeb) {
      _showToast(
        _activeContext,
        message: "Headless Login wird nicht unterstützt",
        isError: true,
      );
      _setStatus(AuthStatus.unauthenticated);
      return;
    }

    _createHeadlessWebView();
    if (_headlessWebView == null) {
      _showToast(
        _activeContext,
        message: "Headless Login konnte nicht gestartet werden",
        isError: true,
      );
      _setStatus(AuthStatus.unauthenticated);
      return;
    }

    if (!_headlessRunning) {
      await _headlessWebView!.run();
      _headlessRunning = true;
    }

    final url = Uri.parse(
        "https://kaschuso.so.ch/public/${_pendingSchool!}/authorize.php"
        "?response_type=code"
        "&client_id=$_clientId"
        "&state=${_oauthState!}"
        "&redirect_uri="
        "&scope=openid%20"
        "&code_challenge=${_codeChallenge!}"
        "&code_challenge_method=S256"
        "&nonce=${_oauthState!}");

    await _headlessWebView!.webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri.uri(url)),
    );
  }

  void _createHeadlessWebView() {
    final context = _activeContext;
    final otpRequest = _otpRequest;
    if (context == null || otpRequest == null) {
      return;
    }

    _headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri.uri(Uri.parse("https://schulnetz.web.app/")),
      ),
      onWebViewCreated: (controller) {
        debugPrint('HeadlessInAppWebView created');
      },
      onConsoleMessage: (controller, consoleMessage) {
        debugPrint("CONSOLE MESSAGE: ${consoleMessage.message}");
      },
      onLoadStop: (controller, url) async {
        final target = url?.toString() ?? '';
        if (target.contains("login?mandant")) {
          await controller.evaluateJavascript(source: """
            document.querySelectorAll('button').forEach(button => {
              if (button.textContent.trim() === 'Log in') {
                button.click();
              }
            });
          """);
        }

        if (target.contains("authorize.php")) {
          try {
            final pageHtml = await controller.getHtml();
            if (pageHtml != null) {
              final errorMessage = _extractAuthorizeError(pageHtml);
              if (errorMessage != null) {
                await _handleAuthorizeError(errorMessage);
                return;
              }
            }
          } catch (e, s) {
            debugPrint('Failed to fetch authorize HTML: $e\n$s');
          }

          final hasPinField = await controller.evaluateJavascript(
              source: "document.querySelector('input#pin') != null;");

          final bool pinPage =
              hasPinField == true || hasPinField?.toString() == 'true';

          if (pinPage) {
            final otp = await otpRequest();
            if (otp == null || otp.isEmpty) {
              _setStatus(AuthStatus.unauthenticated);
              return;
            }

            final otpLiteral = jsonEncode(otp);
            await controller.evaluateJavascript(source: """
              (function() {
                var pinInput = document.getElementById('pin');
                if (pinInput) {
                  pinInput.value = $otpLiteral;
                }
                var submitBtn = document.querySelector('.login-submit');
                if (submitBtn) {
                  submitBtn.click();
                }
              })();
            """);
          } else {
            final usernameLiteral = jsonEncode(_pendingUsername ?? '');
            final passwordLiteral = jsonEncode(_pendingPassword ?? '');
            await controller.evaluateJavascript(source: """
              if (document.getElementById("login") && document.getElementById("passwort")) {
                document.getElementById("login").value = $usernameLiteral;
                document.getElementById("passwort").value = $passwordLiteral;
                var submitBtn = document.querySelector('.login-submit');
                if (submitBtn) {
                  submitBtn.click();
                }
              }
            """);
          }
        }
      },
      onUpdateVisitedHistory: (controller, url, androidIsReload) async {
        final urlString = url?.toString() ?? '';
        if (urlString.startsWith('https://schulnetz.web.app/callback')) {
          final uri = Uri.parse(urlString);
          final code = uri.queryParameters['code'];
          final state = uri.queryParameters['state'];

          if (code != null && state != null && state == _oauthState) {
            await _disposeHeadlessWebView();
            await _exchangeCodeForToken(code);
            return;
          }
        }

        if (urlString.contains("/login")) {
          debugPrint("successfully authenticated for the first time");
          await _disposeHeadlessWebView();
          await _performAuthorizeRequest();
        }
      },
    );
  }

  Future<void> _handleAuthorizeError(String message) async {
    await _disposeHeadlessWebView();
    _showToast(
      _activeContext,
      message: message,
      isError: true,
      duration: const Duration(seconds: 2),
    );
    _setStatus(AuthStatus.unauthenticated);
  }

  String? _extractAuthorizeError(String html) {
    try {
      final dom.Document document = parser.parse(html);
      final errorNode = document
          .querySelector('.mdl-cell.mdl-cell--12-col[style*="#ffb138"]');

      if (errorNode != null) {
        final text = errorNode.text.trim();
        if (text.isNotEmpty && text.toLowerCase().startsWith('fehler')) {
          return text;
        }
      }

      final bodyText = document.body?.text ?? '';
      if (bodyText.toLowerCase().contains('fehler:')) {
        return bodyText
            .split('\n')
            .map((line) => line.trim())
            .firstWhere(
              (line) => line.toLowerCase().startsWith('fehler'),
              orElse: () => 'Fehler bei der Anmeldung',
            );
      }
    } catch (e, s) {
      debugPrint('Error parsing authorize.php HTML: $e\n$s');
    }

    return null;
  }

  Future<void> _handleDemoLogin(BuildContext context) async {
    await _storage.write(key: "username", value: "demo");
    await _storage.write(key: "password", value: "demo");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("school");

    _apiClient.fakeData = true;
    _apiClient.school = "demo";

    _showToast(
      context,
      message: "Demo-Modus aktiviert",
    );
    _setStatus(AuthStatus.authenticated);
  }

  bool _isDemoLogin(String username, String password) {
    return username.toLowerCase() == 'demo' && password.toLowerCase() == 'demo';
  }

  Future<void> _saveCredentials({
    required String username,
    required String password,
    required String school,
  }) async {
    await _storage.write(key: "username", value: username);
    await _storage.write(key: "password", value: password);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("school", school.toUpperCase());
  }

  void _showToast(
    BuildContext? context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 1),
  }) {
    final ctx = context ?? _activeContext;
    if (ctx == null) return;
    if (!ctx.mounted) return;

    showToast(
      alignment: Alignment.bottomCenter,
      duration: duration,
      child: Container(
        margin: const EdgeInsets.only(bottom: 32.0),
        decoration: BoxDecoration(
          color: isError ? Colors.redAccent : Colors.greenAccent,
          borderRadius: const BorderRadius.all(Radius.circular(12.0)),
        ),
        padding: const EdgeInsets.all(6.0),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.0,
          ),
        ),
      ),
      context: ctx,
    );
  }

  void _generatePkceAndState() {
    final rand = Random.secure();
    final verifierBytes = List<int>.generate(32, (_) => rand.nextInt(256));
    _codeVerifier = _base64UrlNoPadding(verifierBytes);

    final verifierUtf8 = utf8.encode(_codeVerifier!);
    final digest = crypto.sha256.convert(verifierUtf8);
    _codeChallenge = _base64UrlNoPadding(digest.bytes);

    final stateBytes = List<int>.generate(16, (_) => rand.nextInt(256));
    _oauthState = _base64UrlNoPadding(stateBytes);
  }

  String _base64UrlNoPadding(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
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

  Future<void> _disposeHeadlessWebView() async {
    if (_headlessWebView != null) {
      try {
        await _headlessWebView!.dispose();
      } catch (e, s) {
        debugPrint('Error disposing headlessWebView: $e\n$s');
      }
      _headlessWebView = null;
      _headlessRunning = false;
    }
  }

  void _setStatus(AuthStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    notifyListeners();
  }
}