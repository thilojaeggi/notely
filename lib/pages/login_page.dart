import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_toast/fl_toast.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notely/core/analytics/analytics_constants.dart';
import 'package:notely/core/analytics/analytics_service.dart';
import 'package:notely/core/config/style.dart';
import 'package:notely/core/storage/secure_storage.dart';
import 'package:notely/core/widgets/outlined_box_shadow.dart';
import 'package:notely/data/api_client.dart';
import 'package:notely/features/auth/kaschuso_auth_service.dart';
import 'package:notely/features/auth/otp_helper.dart';
import 'package:notely/features/auth/token_manager.dart';
import 'package:notely/features/auth/widgets/auth_text_field.dart';
import 'package:notely/features/auth/widgets/two_factor_sheet.dart';
import 'package:notely/pages/help_page.dart';
import 'package:notely/shell/initialize_screen.dart';
import 'package:notely/shell/view_container.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loginHasBeenPressed = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    _loadStoredCredentials();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredCredentials() async {
    final storage = SecureStorage();
    final prefs = await SharedPreferences.getInstance();
    final storedUsername = await storage.read(key: "username") ?? '';
    final storedPassword = await storage.read(key: "password") ?? '';
    final prefsSchool = prefs.getString("school") ?? '';
    final secureSchool = await storage.read(key: "school") ?? '';
    final storedSchool = prefsSchool.isNotEmpty ? prefsSchool : secureSchool;
    final normalizedSchool = storedSchool.toUpperCase();
    final hasValidSchool = _schoolOptions.containsValue(normalizedSchool);
    final canAutoLogin = storedUsername.isNotEmpty &&
        storedPassword.isNotEmpty &&
        hasValidSchool;

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

    AnalyticsService().logTwoFactorPrompted(school: dropdownValue);
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
    AnalyticsService().logTwoFactorCompleted(
      school: dropdownValue,
      isSuccess: result != null && result.isNotEmpty,
    );
    return result;
  }

  Future<String?> _getStoredOtp() async {
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
    return null;
  }

  void _showErrorToast(String message) {
    if (!mounted) return;
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
          message,
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

  Future<void> signIn() async {
    final storage = SecureStorage();
    final apiClient = APIClient();
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text;
    final school = dropdownValue.toLowerCase();

    // 1. Check for valid cached token to skip login if possible
    try {
      final cachedToken = await _tokenManager.getValidAccessToken(school);
      if (cachedToken != null &&
          cachedToken.isNotEmpty &&
          await apiClient.isAccessTokenValid(cachedToken, school)) {
        apiClient.accessToken = cachedToken;
        apiClient.school = school;
        AnalyticsService().setSchool(school);
        AnalyticsService().logLoginSuccess(
          method: LoginMethod.cachedToken,
          school: school,
        );
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
    } on InvalidCredentialsException {
      debugPrint('Cached credentials invalid, proceeding with fresh login');
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

    // 3. Native Direct Auth Flow
    final startTime = DateTime.now();
    AnalyticsService().logLoginAttempt(
      method: LoginMethod.manual,
      school: dropdownValue,
    );

    final authService = KaschusoAuthService();

    try {
      final storedOtp = await _getStoredOtp();
      KaschusoTokens tokens;

      try {
        tokens = await authService.login(
          username: username,
          password: password,
          school: school,
          otpCode: storedOtp,
        );
      } on KaschusoOtpRequiredException {
        // Prompt for OTP
        final manualOtp = await _askForOtpCode();
        if (manualOtp == null || manualOtp.trim().isEmpty) {
          if (mounted) {
            setState(() {
              _loginHasBeenPressed = false;
            });
          }
          return;
        }
        tokens = await authService.submitOtp(otpCode: manualOtp.trim());
      } on KaschusoAuthException catch (e) {
        // If stored OTP was rejected, allow manual OTP entry if session is active
        if (authService.hasActiveSession && e.message.toLowerCase().contains('code')) {
          debugPrint('[LoginPage] Stored OTP rejected, falling back to manual entry');
          final manualOtp = await _askForOtpCode();
          if (manualOtp == null || manualOtp.trim().isEmpty) {
            if (mounted) {
              setState(() {
                _loginHasBeenPressed = false;
              });
            }
            return;
          }
          tokens = await authService.submitOtp(otpCode: manualOtp.trim());
        } else {
          rethrow;
        }
      }

      // Save credentials & tokens
      final prefs = await SharedPreferences.getInstance();
      await storage.write(key: "username", value: username);
      await storage.write(key: "password", value: password);
      await storage.write(key: "school", value: school);
      await prefs.setString("school", school);

      await storage.saveAccessToken(
        tokens.accessToken,
        expiresAt: tokens.expiresAt,
        refreshToken: tokens.refreshToken,
      );

      apiClient.accessToken = tokens.accessToken;
      apiClient.school = school;
      AnalyticsService().setSchool(school);
      AnalyticsService().logLoginSuccess(
        method: LoginMethod.manual,
        school: school,
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
      );

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
    } on KaschusoInvalidCredentialsException catch (e) {
      debugPrint('Login credentials error: ${e.message}');
      AnalyticsService().logLoginFailure(
        method: LoginMethod.manual,
        school: dropdownValue,
        reason: e.message,
      );
      if (mounted) {
        setState(() {
          _loginHasBeenPressed = false;
        });
        _showErrorToast(e.message);
      }
    } catch (e, s) {
      debugPrint('Login error: $e\n$s');
      AnalyticsService().logLoginFailure(
        method: LoginMethod.manual,
        school: dropdownValue,
        reason: e.toString(),
      );
      if (mounted) {
        setState(() {
          _loginHasBeenPressed = false;
        });
        final displayMsg = e.toString().replaceFirst('Exception: ', '').replaceFirst('KaschusoAuthException: ', '');
        _showErrorToast(displayMsg);
      }
    }
  }

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
                                        _loginHasBeenPressed
                                            ? "Anmelden..."
                                            : "Anmelden",
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
                                      if (_loginHasBeenPressed)
                                        const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      else
                                        const Icon(
                                          CupertinoIcons.arrow_right,
                                          color: Colors.black,
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
