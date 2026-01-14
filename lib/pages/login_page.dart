import 'dart:convert'; // NEW
import 'dart:math'; // NEW

import 'package:crypto/crypto.dart' as crypto; // NEW

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:notely/Globals.dart';
import 'package:notely/helpers/api_client.dart';
import 'package:notely/helpers/initialize_screen.dart';
import 'package:notely/outlined_box_shadow.dart';
import 'package:notely/pages/help_page.dart';
import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:notely/secure_storage.dart';
import 'package:notely/widgets/auth_text_field.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import '../config/style.dart';
import '../view_container.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _TwoFactorSheet extends StatefulWidget {
  final TextEditingController textController;

  const _TwoFactorSheet({required this.textController});

  @override
  State<_TwoFactorSheet> createState() => _TwoFactorSheetState();
}

class _TwoFactorSheetState extends State<_TwoFactorSheet> {
  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_handleChange);
  }

  @override
  void dispose() {
    widget.textController.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    final hasText = widget.textController.text.trim().isNotEmpty;
    if (hasText != _hasInput) {
      setState(() {
        _hasInput = hasText;
      });
    }
  }

  void _submit() {
    Navigator.of(context).pop(widget.textController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final cupertinoTheme = CupertinoTheme.of(context);
    final backgroundColor = cupertinoTheme.scaffoldBackgroundColor;
    final helperStyle = cupertinoTheme.textTheme.textStyle.copyWith(
          fontSize: 15,
          color: CupertinoColors.systemGrey.resolveFrom(context),
        );
    final fieldBackground =
        CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(0, -12),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color:
                          CupertinoColors.systemGrey4.resolveFrom(context),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '2-Faktor-Code',
                        style: cupertinoTheme.textTheme.navTitleTextStyle
                            .copyWith(fontSize: 22),
                      ),
                    ),
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      padding: const EdgeInsets.all(8),
                      minSize: 32,
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 24,
                        color:
                            CupertinoColors.systemGrey.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Bitte gib den aktuellen Code aus deiner Authentifizierungs-App ein.',
                  style: helperStyle,
                ),
                const SizedBox(height: 18),
                CupertinoTextField(
                  controller: widget.textController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: Theme.of(context).colorScheme.primary,
                  decoration: BoxDecoration(
                    color: fieldBackground,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Der Code läuft nach kurzer Zeit ab und wird automatisch aktualisiert.',
                  style: helperStyle,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: fieldBackground,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Abbrechen',
                          style: cupertinoTheme.textTheme.textStyle.copyWith(
                            color: CupertinoColors.label.resolveFrom(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        onPressed: _hasInput ? _submit : null,
                        child: const Text('Senden'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginPageState extends State<LoginPage> {
  bool _loginHasBeenPressed = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  HeadlessInAppWebView? headlessWebView;
  bool _headlessRunning = false;
  String dropdownValue = 'KSSO';
  bool _hasStoredCredentials = false;
  bool _autoSignInTriggered = false;

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

    // state & nonce: also random
    final stateBytes = List<int>.generate(16, (_) => rand.nextInt(256));
    _oauthState = _base64UrlNoPadding(stateBytes);

    debugPrint('PKCE generated: verifier=${_codeVerifier!.substring(0, 8)}..., '
        'challenge=${_codeChallenge!.substring(0, 8)}..., '
        'state=$_oauthState');
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
    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest:
          URLRequest(url: WebUri.uri(Uri.parse("https://schulnetz.web.app/"))),
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

            final otp = await _askForOtpCode();
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

          debugPrint('callback code=$code state=$state (expected state=$_oauthState)');

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
    final hasValidSchool = _schoolOptions.containsValue(normalizedSchool);
    final canAutoLogin =
        storedUsername.isNotEmpty && storedPassword.isNotEmpty && hasValidSchool;

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
        return _TwoFactorSheet(
          textController: controller,
        );
      },
    );

    controller.dispose();
    return result;
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

  Future<void> _safeEvaluateJS(
      InAppWebViewController controller, String source) async {
    try {
      await controller.evaluateJavascript(source: source);
    } catch (e, s) {
      debugPrint('evaluateJavascript error: $e\n$s');
    }
  }

  String _escapeForJS(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r');
  }

  Future<void> _disposeHeadlessWebView() async {
    if (headlessWebView != null) {
      try {
        await headlessWebView!.dispose();
      } catch (e, s) {
        debugPrint('Error disposing headlessWebView: $e\n$s');
      }
      headlessWebView = null;
      _headlessRunning = false;
    }
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

  // NEW: exchange code for access_token via token.php
  Future<void> _exchangeCodeForToken(String code) async {
    final storage = SecureStorage();
    final apiClient = APIClient();
    final school = dropdownValue.toLowerCase();

    if (_codeVerifier == null) {
      debugPrint('No code_verifier available, cannot exchange code');
      return;
    }

    final tokenUrl =
        Uri.parse("https://kaschuso.so.ch/public/$school/token.php");

    final body = {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': '',
      'code_verifier': _codeVerifier!,
      'client_id': 'ppyybShnMerHdtBQ',
    };

    final resp = await http.post(
      tokenUrl,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json, text/plain, */*',
      },
      body: body,
    );

    debugPrint('token.php status: ${resp.statusCode}');
    debugPrint('token.php body: ${resp.body}');

    if (resp.statusCode == 200) {
      final jsonData = jsonDecode(resp.body) as Map<String, dynamic>;
      final accessToken = jsonData['access_token'] as String?;
      final expiresAt = _deriveExpiry(jsonData['expires_in']);

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
      await storage.saveAccessToken(accessToken, expiresAt: expiresAt);

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
          child: const InitializeScreen(targetWidget: ViewContainerWidget()),
        ),
      );
    } else {
      if (!mounted) return;
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
            "2FA-Token konnte nicht geholt werden",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.0,
            ),
          ),
        ),
        context: context,
      );
    }
  }

  Future<void> signIn() async {
    final storage = SecureStorage();
    final apiClient = APIClient();
    final String username = _usernameController.text;
    final String password = _passwordController.text;

    // Generate new PKCE + state (NEW)
    _generatePkceAndState();

    final school = dropdownValue.toLowerCase();

    final url = Globals.buildUrl(
        "$school/authorize.php?response_type=code"
        "&client_id=ppyybShnMerHdtBQ"
        "&state=${_oauthState!}"
        "&redirect_uri="
        "&scope=openid%20"
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
        debugPrint("Hasn't authenticated for the first time – start headless PKCE flow");

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
                "&redirect_uri="
                "&scope=openid%20"
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
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: Theme(
            data: Styles.themeData(true, context),
            child: Container(
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
                  Form(
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
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            color: Colors.white.withOpacity(0.1),
                            boxShadow: [
                              OutlinedBoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                offset: const Offset(0, 0),
                                blurRadius: 10.0,
                                blurStyle: BlurStyle.outer,
                              ),
                            ],
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              focusColor: Colors.transparent,
                              splashColor: Colors.white.withOpacity(0.15),
                              highlightColor: Colors.white.withOpacity(0.05),
                              hoverColor: Colors.white.withOpacity(0.08),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: DropdownButtonFormField<String>(
                                value: dropdownValue,
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
                            color: Colors.white.withOpacity(0.1),
                            boxShadow: [
                              OutlinedBoxShadow(
                                  color: Colors.black.withOpacity(0.1),
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
                            color: Colors.white.withOpacity(0.1),
                            boxShadow: [
                              OutlinedBoxShadow(
                                  color: Colors.black.withOpacity(0.1),
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
