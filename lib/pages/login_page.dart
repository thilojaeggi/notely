import 'dart:convert'; // NEW
import 'dart:developer';
import 'dart:math'; // NEW

import 'package:crypto/crypto.dart' as crypto; // NEW

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:notely/Globals.dart';
import 'package:notely/config/app_config.dart';
import 'package:notely/helpers/api_client.dart';
import 'package:notely/helpers/initialize_screen.dart';
import 'package:notely/outlined_box_shadow.dart';
import 'package:notely/pages/help_page.dart';
import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:notely/secure_storage.dart';
import 'package:notely/widgets/auth_text_field.dart';
import 'package:notely/widgets/two_factor_sheet.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:notely/helpers/otp_helper.dart';
import 'package:notely/helpers/token_manager.dart';
import '../config/style.dart';
import '../view_container.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loginHasBeenPressed = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  HeadlessInAppWebView? headlessWebView;
  String dropdownValue = 'KSSO';
  bool _hasStoredCredentials = false;
  bool _autoSignInTriggered = false;
  final TokenManager _tokenManager = TokenManager();

  static const Map<String, String> _schoolOptions = {
    'Kanti Solothurn': 'KSSO',
    'GIBS Solothurn': 'GIBSSO',
    'KBS Solothurn': 'KBSSO',
    'GIBS Grenchen': 'GIBSGR',
    'GIBS Olten': 'GIBSOL',
    'Kanti Olten': 'KSOL',
    'KBS Olten': 'KBSOL',
  };

  // PKCE + state (NEW)
  String? _codeVerifier;
  String? _codeChallenge;
  String? _oauthState;

  String _base64UrlNoPadding(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  void _generatePkceAndState() {
    final rand = Random.secure();

    // code_verifier: 32 random bytes
    final verifierBytes = List<int>.generate(32, (_) => rand.nextInt(256));
    _codeVerifier = _base64UrlNoPadding(verifierBytes);

    // code_challenge = BASE64URL(SHA256(verifier))
    final verifierUtf8 = utf8.encode(_codeVerifier!);
    final digest = crypto.sha256.convert(verifierUtf8);
    _codeChallenge = _base64UrlNoPadding(digest.bytes);

    // INCREASED SIZE: state & nonce (match their long strings)
    final stateBytes = List<int>.generate(43, (_) => rand.nextInt(256));
    _oauthState = _base64UrlNoPadding(stateBytes);

    debugPrint('PKCE generated with longer state: $_oauthState');
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _createHeadlessWebView();
    }
    _loadStoredCredentials();
  }

  void _createHeadlessWebView() {
    const initialUrl = "https://schulnetz.web.app/";
    final initialUri = Uri.parse(
        kIsWeb ? 'https://proxy.corsfix.com/?$initialUrl' : initialUrl);
    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri.uri(initialUri)),
      onWebViewCreated: (controller) {
        debugPrint('HeadlessInAppWebView created!');
      },
      onConsoleMessage: (controller, consoleMessage) {
        debugPrint("CONSOLE MESSAGE: ${consoleMessage.message}");
      },
      onLoadStart: (controller, url) async {
        debugPrint("onLoadStart $url");
      },
      onLoadStop: (controller, url) async {
        debugPrint("onLoadStop $url");

        if (url
            .toString()
            .contains("https://schulnetz.web.app/login?mandant")) {
          debugPrint("gotologin");
          await headlessWebView!.webViewController
              ?.evaluateJavascript(source: """
      document.querySelectorAll('button').forEach(button => {
        if (button.textContent.trim() === 'Log in') {
          button.click();
          console.log('clicked');
        }
      });
    """);
        }

        if (url.toString().contains("authorize.php")) {
          debugPrint("authorize");

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

          // 1) Detect if this is the OTP page
          final hasPinField = await headlessWebView!.webViewController
              ?.evaluateJavascript(
                  source: "document.querySelector('input#pin') != null;");

          final bool pinPage =
              hasPinField == true || hasPinField?.toString() == 'true';

          if (pinPage) {
            // --- OTP / TOTP PAGE ---
            debugPrint("OTP page detected");

            final otp = await _getOtpCode();
            if (otp == null || otp.isEmpty) {
              debugPrint("User cancelled or empty OTP");
              setState(() {
                _loginHasBeenPressed = false;
              });
              return;
            }

            await headlessWebView!.webViewController
                ?.evaluateJavascript(source: """
        (function() {
          var pinInput = document.getElementById('pin');
          if (pinInput) {
            pinInput.value = '${otp.replaceAll("'", "\\'")}';
          }
          var submitBtn = document.querySelector('.login-submit');
          if (submitBtn) {
            submitBtn.click();
          }
        })();
      """);
          } else {
            // --- USERNAME / PASSWORD PAGE (old behavior) ---
            await headlessWebView!.webViewController
                ?.evaluateJavascript(source: """
        if (document.getElementById("login") && document.getElementById("passwort")) {
          document.getElementById("login").value = "${_usernameController.text}";
          document.getElementById("passwort").value = "${_passwordController.text}";
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
        if (!mounted) return;
        final urlString = url?.toString() ?? '';
        debugPrint("onUpdateVisitedHistory $urlString");

        // NEW: Handle OAuth2 /callback?code=...
        if (urlString.startsWith('https://schulnetz.web.app/callback')) {
          final uri = Uri.parse(urlString);
          final code = uri.queryParameters['code'];
          final state = uri.queryParameters['state'];

          debugPrint(
              'callback code=$code state=$state (expected state=$_oauthState)');

          if (code != null && state != null && state == _oauthState) {
            // We have a valid code – stop headless webview and exchange for token
            await _disposeHeadlessWebView();
            if (!mounted) return;
            setState(() {
              _loginHasBeenPressed = false;
            });
            await _exchangeCodeForToken(code);
            return;
          } else {
            debugPrint('State mismatch or no code – ignoring callback');
          }
        }

        // OLD / LEGACY: original "redirect back to /login" behavior
        if (urlString.contains("/login")) {
          debugPrint("successfully authenticated for the first time");

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _disposeHeadlessWebView();
            if (!mounted) return;
            setState(() {
              _loginHasBeenPressed = false;
            });
            await signIn();
          });
        }
      },
    );
  }

  Future<void> _loadStoredCredentials() async {
    final storage = SecureStorage();
    final prefs = await SharedPreferences.getInstance();
    final storedUsername = await storage.read(key: "username") ?? '';
    final storedPassword = await storage.read(key: "password") ?? '';
    final storedSchool = prefs.getString("school") ?? '';
    final normalizedSchool = storedSchool.toUpperCase();
    final lowerSchool = normalizedSchool.toLowerCase();
    final hasValidSchool = _schoolOptions.containsValue(normalizedSchool);
    final canAutoLogin = storedUsername.isNotEmpty &&
        storedPassword.isNotEmpty &&
        hasValidSchool;

    // Try to reuse a stored token first; falls back to full sign-in (including OTP) when expired.
    if (hasValidSchool) {
      final resumed = await _tryUseStoredToken(lowerSchool);
      if (resumed) return;
    }

    if (!mounted) return;

    setState(() {
      if (storedUsername.isNotEmpty) {
        _usernameController.text = storedUsername;
      }
      if (storedPassword.isNotEmpty) {
        _passwordController.text = storedPassword;
      }
      if (hasValidSchool) {
        dropdownValue = normalizedSchool;
      }
      _hasStoredCredentials = canAutoLogin;
    });

    if (canAutoLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _attemptAutoSignIn();
      });
    }
  }

  Future<bool> _tryUseStoredToken(String schoolCode) async {
    final apiClient = APIClient();
    try {
      final cached = await _tokenManager.getValidAccessToken(schoolCode);
      if (cached == null || cached.isEmpty) {
        return false;
      }
      final isValid = await apiClient.isAccessTokenValid(cached, schoolCode);
      if (!isValid) {
        return false;
      }

      apiClient.accessToken = cached;
      apiClient.school = schoolCode;

      if (!mounted) return true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            duration: const Duration(milliseconds: 450),
            alignment: Alignment.bottomCenter,
            child: const InitializeScreen(targetWidget: ViewContainerWidget()),
          ),
        );
      });
      return true;
    } catch (e, s) {
      debugPrint('Failed to reuse stored token: $e\n$s');
      return false;
    }
  }

  Future<void> _attemptAutoSignIn() async {
    if (!mounted || !_hasStoredCredentials || _autoSignInTriggered) return;
    _autoSignInTriggered = true;
    setState(() {
      _loginHasBeenPressed = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    await signIn();
  }

  Future<String?> _askForOtpCode() async {
    if (!mounted) return null;

    final controller = TextEditingController();

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return TwoFactorSheet(
          textController: controller,
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<String?> _getOtpCode() async {
    try {
      final storage = SecureStorage();
      final storedSecret = await storage.readOtpSecret();
      if (storedSecret != null && storedSecret.isNotEmpty) {
        final generated = OtpHelper.generateTotp(storedSecret);
        if (generated != null) {
          debugPrint('Generated OTP from stored secret');
          return generated;
        }
        debugPrint('Stored OTP secret was invalid');
      }
    } catch (e, s) {
      debugPrint('Failed to generate stored OTP: $e\n$s');
    }

    return _askForOtpCode();
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
        return bodyText.split('\n').map((line) => line.trim()).firstWhere(
              (line) => line.toLowerCase().startsWith('fehler'),
              orElse: () => 'Fehler bei der Anmeldung',
            );
      }
    } catch (e, s) {
      debugPrint('Error parsing authorize.php HTML: $e\n$s');
    }

    return null;
  }

  Future<void> _handleAuthorizeError(String message) async {
    debugPrint('Authorize error detected: $message');
    await _disposeHeadlessWebView();

    if (!mounted) {
      return;
    }

    showToast(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 32.0),
        decoration: const BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
        ),
        padding: const EdgeInsets.all(10.0),
        child: Text(
          message.replaceAll(' Ihre Aktion wurde aufgezeichnet.', ''),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.0,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      context: context,
    );

    setState(() {
      _loginHasBeenPressed = false;
    });
  }

  Future<void> _disposeHeadlessWebView() async {
    if (headlessWebView != null) {
      try {
        await headlessWebView!.dispose();
      } catch (e, s) {
        debugPrint('Error disposing headlessWebView: $e\n$s');
      }
      headlessWebView = null;
    }
  }

  // NEW: exchange code for access_token via token.php
// NEW: exchange code for access_token via token.php
  Future<void> _exchangeCodeForToken(String code) async {
    final storage = SecureStorage();
    final apiClient = APIClient();
    final school = dropdownValue.toLowerCase();

    if (_codeVerifier == null) {
      debugPrint('No code_verifier available, cannot exchange code');
      return;
    }

    // 1. Use the correct URL including /public/ as seen in the working logs
    final tokenUrlString = "https://kaschuso.so.ch/public/$school/token.php";
    final tokenUrl = Uri.parse(
        kIsWeb ? 'https://proxy.corsfix.com/?$tokenUrlString' : tokenUrlString);

    // 2. Extract cookies from the Headless WebView session to maintain context
    final cookieManager = CookieManager.instance();
    final cookies =
        await cookieManager.getCookies(url: WebUri("https://kaschuso.so.ch"));
    String cookieString = cookies.map((e) => "${e.name}=${e.value}").join("; ");

    debugPrint("Sending cookies to token.php: $cookieString");

    // 3. Build the request body with the empty redirect_uri seen in the HAR [cite: 1, 3]
    final body = {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': '',
      'code_verifier': _codeVerifier!,
      'client_id': 'ppyybShnMerHdtBQ',
    };

    try {
      final resp = await http.post(
        tokenUrl,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json, text/plain, */*',
          'Cookie': cookieString, // Attach session ID
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148',
          'Origin': 'https://schulnetz.web.app',
          'Referer': 'https://schulnetz.web.app',
        },
        body: body,
      );

      debugPrint('token.php status: ${resp.statusCode}');
      debugPrint('token.php body: ${resp.body}');

      if (resp.statusCode == 200 && resp.body.trim().isNotEmpty) {
        final jsonData = jsonDecode(resp.body) as Map<String, dynamic>;
        final accessToken = jsonData['access_token'] as String?;
        final refreshToken = jsonData['refresh_token'] as String?;
        final expiresIn = jsonData['expires_in'];
        final expiresAt = TokenManager.deriveExpiry(expiresIn);

        if (accessToken == null) {
          debugPrint('No access_token field in token.php response');
          return;
        }

        final username = _usernameController.text;
        final password = _passwordController.text;

        final prefs = await SharedPreferences.getInstance();
        await storage.write(key: "username", value: username);
        await storage.write(key: "password", value: password);
        await prefs.setString("school", school);
        await storage.saveAccessToken(
          accessToken,
          expiresAt: expiresAt,
          refreshToken: refreshToken,
        );

        apiClient.accessToken = accessToken;
        apiClient.school = school;

        if (!mounted) return;

        showToast(
          alignment: Alignment.bottomCenter,
          duration: const Duration(seconds: 1),
          child: Container(
            margin: const EdgeInsets.only(bottom: 32.0),
            decoration: const BoxDecoration(
              color: Colors.greenAccent,
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
            ),
            padding: const EdgeInsets.all(6.0),
            child: const Text(
              "Erfolgreich angemeldet",
              style: TextStyle(color: Colors.white, fontSize: 16.0),
            ),
          ),
          context: context,
        );

        Navigator.pushReplacement(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            duration: const Duration(milliseconds: 450),
            alignment: Alignment.bottomCenter,
            child: const InitializeScreen(targetWidget: ViewContainerWidget()),
          ),
        );
      } else {
        debugPrint(
            "Token response was empty or failed with status: ${resp.statusCode}");
        throw Exception("Empty response from token.php");
      }
    } catch (e, s) {
      debugPrint('Error during token exchange: $e\n$s');
      if (!mounted) return;
      showToast(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(bottom: 32.0),
          decoration: const BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
          padding: const EdgeInsets.all(6.0),
          child: const Text(
            "2FA-Token konnte nicht geholt werden",
            style: TextStyle(color: Colors.white, fontSize: 16.0),
          ),
        ),
        context: context,
      );
    }
  }

  Future<void> _signInWeb(
      String username, String password, String schoolCode) async {
    final storage = SecureStorage();
    final apiClient = APIClient();
    final prefs = await SharedPreferences.getInstance();
    final apiBase = AppConfig.authProxyUrl;
    print(apiBase);
    try {
      // 1. Send Credentials
      final loginUrl = Uri.parse('$apiBase/auth/login');
      final loginBody = jsonEncode({
        "username": username,
        "password": password,
        "school": schoolCode,
      });

      final loginResp = await http.post(
        loginUrl,
        headers: {'Content-Type': 'application/json'},
        body: loginBody,
      );

      if (loginResp.statusCode != 200 && loginResp.statusCode != 201) {
        throw Exception(
            'Login failed: ${loginResp.statusCode} ${loginResp.body}');
      }

      final loginData = jsonDecode(loginResp.body);
      final status = loginData['status'];

      String? accessToken;
      String? refreshToken;
      dynamic expiresIn;

      // 2. Handle OTP Requirement
      if (status == 'OTP_REQUIRED') {
        final sessionId = loginData['sessionId'];

        // Prompt for OTP (or use stored secret)
        final otp = await _getOtpCode();
        if (otp == null || otp.isEmpty) {
          if (mounted) {
            setState(() {
              _loginHasBeenPressed = false;
            });
          }
          return;
        }

        // 3. Send OTP
        final otpUrl = Uri.parse('$apiBase/auth/otp');
        final otpBody = jsonEncode({
          "sessionId": sessionId,
          "otp": otp,
        });

        final otpResp = await http.post(
          otpUrl,
          headers: {'Content-Type': 'application/json'},
          body: otpBody,
        );

        if (otpResp.statusCode != 200 && otpResp.statusCode != 201) {
          throw Exception('OTP validation failed: ${otpResp.statusCode}');
        }

        final otpData = jsonDecode(otpResp.body);
        if (otpData['status'] == 'SUCCESS') {
          accessToken = otpData['access_token'];
          refreshToken = otpData['refresh_token'];
          expiresIn = otpData['expires_in'];
        } else {
          throw Exception('OTP status not SUCCESS: ${otpData['status']}');
        }
      } else if (status == 'SUCCESS') {
        // Direct success (no OTP)
        accessToken = loginData['access_token'];
        refreshToken = loginData['refresh_token'];
        expiresIn = loginData['expires_in'];
      } else {
        throw Exception('Unknown login status: $status');
      }

      // 4. Save Token and Complete Login
      if (accessToken != null) {
        final schoolLower = schoolCode.toLowerCase();
        final expiresAt = TokenManager.deriveExpiry(expiresIn);

        await storage.write(key: "username", value: username);
        await storage.write(key: "password", value: password);
        await prefs.setString("school", schoolLower);

        await storage.saveAccessToken(
          accessToken,
          expiresAt: expiresAt,
          refreshToken: refreshToken,
        );

        apiClient.accessToken = accessToken;
        apiClient.school = schoolLower;

        if (!mounted) return;

        showToast(
          alignment: Alignment.bottomCenter,
          duration: const Duration(seconds: 1),
          child: Container(
            margin: const EdgeInsets.only(bottom: 32.0),
            decoration: const BoxDecoration(
              color: Colors.greenAccent,
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
            ),
            padding: const EdgeInsets.all(6.0),
            child: const Text(
              "Erfolgreich angemeldet",
              style: TextStyle(color: Colors.white, fontSize: 16.0),
            ),
          ),
          context: context,
        );

        Navigator.pushReplacement(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            duration: const Duration(milliseconds: 450),
            alignment: Alignment.bottomCenter,
            child: const InitializeScreen(targetWidget: ViewContainerWidget()),
          ),
        );
      }
    } catch (e, s) {
      debugPrint('Web login error: $e\n$s');
      if (mounted) {
        setState(() {
          _loginHasBeenPressed = false;
        });
        showToast(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 32.0),
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
            ),
            padding: const EdgeInsets.all(10.0),
            child: Text(
              "Anmeldung fehlgeschlagen: $e",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          context: context,
        );
      }
    }
  }

  Future<void> signIn() async {
    final storage = SecureStorage();
    final apiClient = APIClient();
    final String username = _usernameController.text;
    final String password = _passwordController.text;
    final school = dropdownValue.toLowerCase();

    // 1. Check for valid cached token to skip login if possible
    final cachedToken = await _tokenManager.getValidAccessToken(school);
    if (cachedToken != null &&
        cachedToken.isNotEmpty &&
        await apiClient.isAccessTokenValid(cachedToken, school)) {
      apiClient.accessToken = cachedToken;
      apiClient.school = school;
      if (!mounted) return;
      setState(() {
        _loginHasBeenPressed = false;
      });
      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 450),
          alignment: Alignment.bottomCenter,
          child: const InitializeScreen(targetWidget: ViewContainerWidget()),
        ),
      );
      return;
    }

    // 2. Handle Demo Mode
    if (username == "demo" && password == "demo") {
      apiClient.fakeData = true;
      apiClient.school = "demo";
      await storage.write(key: "username", value: username);
      await storage.write(key: "password", value: password);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 450),
          alignment: Alignment.bottomCenter,
          child: const ViewContainerWidget(),
        ),
      );
      return;
    }

    // 3. Web Login Flow (NEW)
    if (kIsWeb || AppConfig.forceWebFlow) {
      await _signInWeb(username, password, dropdownValue);
      return;
    }

    // 4. Start PKCE flow
    _generatePkceAndState();

    // 5. Dispose and recreate Headless WebView to ensure a clean session
    await _disposeHeadlessWebView();
    _createHeadlessWebView();

    if (headlessWebView == null) {
      debugPrint('Failed to create HeadlessInAppWebView instance');
      if (mounted) setState(() => _loginHasBeenPressed = false);
      return;
    }

    await headlessWebView!.run();

    // 6. Build the Authorization URL exactly as seen in the HAR
    const redirectUri = "https://schulnetz.web.app/callback";
    final authUrlString =
        "https://kaschuso.so.ch/public/$school/authorize.php" // Keep /public/
        "?response_type=code"
        "&client_id=ppyybShnMerHdtBQ"
        "&state=${_oauthState!}"
        "&redirect_uri=" // Must be empty to match the HAR
        "&scope=openid%20"
        "&code_challenge=${_codeChallenge!}"
        "&code_challenge_method=S256"
        "&nonce=${_oauthState!}"
        "&id=";
    final authUrl =
        kIsWeb ? 'https://proxy.corsfix.com/?$authUrlString' : authUrlString;
    debugPrint("Launching Auth Flow: $authUrl");

    // Load the URL. The WebView's onLoadStop will automatically
    // handle entering the username/password and clicking login.
    await headlessWebView!.webViewController?.loadUrl(
      urlRequest: URLRequest(
        url: WebUri.uri(Uri.parse(authUrl)),
      ),
    );
  }

/*
  Future<void> signIn() async {
    final storage = SecureStorage();
    final apiClient = APIClient();
    final String username = _usernameController.text;
    final String password = _passwordController.text;
    final school = dropdownValue.toLowerCase();

    // If we already have a fresh token (or can refresh it), skip the whole re-auth flow.
    final cachedToken = await _tokenManager.getValidAccessToken(school);
    if (cachedToken != null &&
        cachedToken.isNotEmpty &&
        await apiClient.isAccessTokenValid(cachedToken, school)) {
      apiClient.accessToken = cachedToken;
      apiClient.school = school;
      if (!mounted) return;
      setState(() {
        _loginHasBeenPressed = false;
      });
      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 450),
          alignment: Alignment.bottomCenter,
          child: const InitializeScreen(targetWidget: ViewContainerWidget()),
        ),
      );
      return;
    }

    // Generate new PKCE + state (NEW)
    _generatePkceAndState();

final redirectUri = "https://schulnetz.web.app/callback"; // Must match the HAR
final url = Globals.buildUrl(
    "$school/authorize.php?response_type=code"
    "&client_id=ppyybShnMerHdtBQ"
    "&state=${_oauthState!}"
    "&redirect_uri=${Uri.encodeComponent(redirectUri)}" // Added this
    "&scope=openid"
    "&code_challenge=${_codeChallenge!}"
    "&code_challenge_method=S256"
    "&nonce=${_oauthState!}");

    if (username == "demo" && password == "demo") {
      apiClient.fakeData = true;
      apiClient.school = "demo";
      await storage.write(key: "username", value: username);
      await storage.write(key: "password", value: password);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 450),
          alignment: Alignment.bottomCenter,
          child: const ViewContainerWidget(),
        ),
      );
      return;
    } else {
      apiClient.fakeData = false;
    }

    await http.post(url, body: {
      "login": username,
      "passwort": password,
    }, headers: {
      'accept-encoding': 'gzip, deflate',
      'access-control-allow-credentials': 'true',
      'access-control-allow-headers': '*',
      'access-control-allow-methods': '*',
      'access-control-allow-origin': '*',
      'access-control-expose-headers': '*'
    }).then((response) async {
      debugPrint(response.statusCode.toString());
      debugPrint(response.body.toString());
      debugPrint(response.headers.toString());

      if (response.statusCode == 302 && response.headers['location'] != null) {
        String locationHeader = response.headers['location'].toString();
        debugPrint(locationHeader);

        // LEGACY: implicit-flow fragment with access_token
        if (locationHeader.contains('#access_token=')) {
          var trimmedString =
              locationHeader.substring(0, locationHeader.indexOf('&'));
          trimmedString = trimmedString
              .substring(trimmedString.indexOf("#") + 1)
              .replaceAll("access_token=", "");
          final prefs = await SharedPreferences.getInstance();
          await storage.write(key: "username", value: username);
          await storage.write(key: "password", value: password);
          await prefs.setString("school", school);
          await storage.saveAccessToken(trimmedString);

          apiClient.accessToken = trimmedString;
          apiClient.school = school;
          if (!mounted) return;

          showToast(
            alignment: Alignment.bottomCenter,
            duration: const Duration(seconds: 1),
            child: Container(
              margin: const EdgeInsets.only(bottom: 32.0),
              decoration: const BoxDecoration(
                color: Colors.greenAccent,
                borderRadius: BorderRadius.all(
                  Radius.circular(12.0),
                ),
              ),
              padding: const EdgeInsets.all(6.0),
              child: const Text(
                "Erfolgreich angemeldet",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
              ),
            ),
            context: context,
          );
          Navigator.pushReplacement(
            context,
            PageTransition(
              type: PageTransitionType.fade,
              duration: const Duration(milliseconds: 450),
              alignment: Alignment.bottomCenter,
              child:
                  const InitializeScreen(targetWidget: ViewContainerWidget()),
            ),
          );
        } else {
          // If they ever start redirecting directly with ?code=... in Location,
          // you could also parse that here and call _exchangeCodeForToken(code).
          debugPrint('302 without access_token fragment – not handled here');
        }
      } else if (response.statusCode == 200 &&
          response.headers['location'] == null) {

        await _disposeHeadlessWebView();
        _createHeadlessWebView();

        if (headlessWebView == null) {
          debugPrint('Failed to create HeadlessInAppWebView instance');
          setState(() {
            _loginHasBeenPressed = false;
          });
          return;
        }

        await headlessWebView!.run();

        headlessWebView!.webViewController?.loadUrl(
          urlRequest: URLRequest(
            url: WebUri.uri(Uri.parse(
                "https://kaschuso.so.ch/public/$school/authorize.php"
                "?response_type=code"
                "&client_id=ppyybShnMerHdtBQ"
                "&state=${_oauthState!}"
                "&redirect_uri=https://schulnetz.web.app/callback"
                "&scope=openid"
                "&code_challenge=${_codeChallenge!}"
                "&code_challenge_method=S256"
                "&nonce=${_oauthState!}")),
          ),
        );
      } else {
        showToast(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 32.0),
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.all(
                Radius.circular(12.0),
              ),
            ),
            padding: const EdgeInsets.all(6.0),
            child: const Text(
              "Etwas ist schiefgelaufen",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.0,
              ),
            ),
          ),
          context: context,
        );
        setState(() {
          _loginHasBeenPressed = false;
        });
      }
    });
  }*/

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: Theme(
            data: Styles.themeData(true, context),
            child: Container(
              height: double.infinity,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black,
                    Colors.blueAccent,
                  ],
                ),
              ),
              child: Column(
                children: <Widget>[
                  const Spacer(),
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: kIsWeb ? 400 : double.infinity,
                      ),
                      child: Form(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Image.asset(
                                'assets/images/notely_n.png',
                                width: 100,
                                height: 100,
                                isAntiAlias: true,
                                filterQuality: FilterQuality.medium,
                              ),
                            ),
                            Container(
                              clipBehavior: Clip.antiAlias,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                color: Colors.white.withValues(alpha: 0.1),
                                boxShadow: [
                                  OutlinedBoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    offset: const Offset(0, 0),
                                    blurRadius: 10.0,
                                    blurStyle: BlurStyle.outer,
                                  ),
                                ],
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  focusColor: Colors.transparent,
                                  splashColor:
                                      Colors.white.withValues(alpha: 0.15),
                                  highlightColor:
                                      Colors.white.withValues(alpha: 0.05),
                                  hoverColor:
                                      Colors.white.withValues(alpha: 0.08),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: DropdownButtonFormField<String>(
                                    initialValue: dropdownValue,
                                    alignment: Alignment.centerLeft,
                                    focusColor: Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                    decoration: const InputDecoration(
                                      hintStyle: TextStyle(color: Colors.white),
                                      prefixIcon: Padding(
                                        padding: EdgeInsets.only(left: 8.0),
                                        child: Icon(
                                          Icons.school,
                                          color: Colors.white,
                                        ),
                                      ),
                                      focusedBorder: InputBorder.none,
                                      border: InputBorder.none,
                                    ),
                                    dropdownColor: const Color(0xFF1D2E5A),
                                    menuMaxHeight: 300,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        dropdownValue = newValue!;
                                      });
                                    },
                                    items: _schoolOptions.entries
                                        .map(
                                          (entry) => DropdownMenuItem<String>(
                                            alignment: Alignment.centerLeft,
                                            value: entry.value,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 4.0),
                                              child: Text(
                                                entry.key,
                                                textAlign: TextAlign.start,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10.0,
                            ),
                            Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                color: Colors.white.withValues(alpha: 0.1),
                                boxShadow: [
                                  OutlinedBoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      offset: const Offset(0, 0),
                                      blurRadius: 10.0,
                                      blurStyle: BlurStyle.outer)
                                ],
                              ),
                              child: AuthTextField(
                                backgroundColor: Colors.transparent,
                                hintText: 'Benutzername',
                                icon: Icons.person,
                                editingController: _usernameController,
                                passwordField: false,
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(
                              height: 10.0,
                            ),
                            Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                color: Colors.white.withValues(alpha: 0.1),
                                boxShadow: [
                                  OutlinedBoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      offset: const Offset(0, 0),
                                      blurRadius: 10.0,
                                      blurStyle: BlurStyle.outer)
                                ],
                              ),
                              child: AuthTextField(
                                backgroundColor: Colors.transparent,
                                hintText: 'Passwort',
                                icon: Icons.lock,
                                editingController: _passwordController,
                                passwordField: true,
                                textInputAction: TextInputAction.done,
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton(
                                onPressed: () async {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  setState(() {
                                    _loginHasBeenPressed = true;
                                  });
                                  await signIn();
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.all(10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  side: BorderSide(
                                    width: 3.0,
                                    color: _loginHasBeenPressed
                                        ? Colors.white
                                        : Colors.transparent,
                                  ),
                                  backgroundColor: _loginHasBeenPressed
                                      ? Colors.transparent
                                      : Colors.white,
                                  animationDuration: const Duration(
                                    milliseconds: 450,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Anmelden",
                                        style: TextStyle(
                                          color: _loginHasBeenPressed
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 20.0,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Icon(
                                        CupertinoIcons.arrow_right,
                                        color: _loginHasBeenPressed
                                            ? Colors.white
                                            : Colors.black,
                                        size: 30.0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(
                        splashFactory: NoSplash.splashFactory),
                    onPressed: () {
                      showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const HelpPage());
                    },
                    child: const Text(
                      "Hilfe?",
                      style: TextStyle(color: Colors.white, fontSize: 24.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox.shrink(),
      ],
    );
  }
}
