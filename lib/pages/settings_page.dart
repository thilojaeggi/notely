import 'dart:async';
import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';
import 'package:notely/Globals.dart';
import 'package:notely/helpers/api_client.dart';
import 'package:notely/helpers/initialization_helper.dart';
import 'package:notely/helpers/otp_helper.dart';
import 'package:notely/helpers/subscription_manager.dart';
import 'package:notely/helpers/token_manager.dart';
import 'package:notely/secure_storage.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_page.dart';
import 'package:app_settings/app_settings.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController targetGradeController = TextEditingController();
  bool notificationsEnabled = false;
  bool _isPresentingPremium = false;
  final _initializationHelper = InitializationHelper();
  late final Future<bool> _future;
  String? _otpSecret;
  bool _loadingOtpSecret = true;

  Future<PackageInfo> _getPackageInfo() {
    return PackageInfo.fromPlatform();
  }

  Future<void> _presentNotelyPremiumPaywall() async {
    if (_isPresentingPremium) return;
    setState(() {
      _isPresentingPremium = true;
    });

    final paywallPresented =
        await SubscriptionManager().presentNotelyPremiumPaywall();

    if (!mounted) {
      return;
    }

    setState(() {
      _isPresentingPremium = false;
    });

    if (!paywallPresented) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Paywall konnte nicht geladen werden. Bitte versuche es später erneut.",
          ),
        ),
      );
    }
  }

  void openAppSettings() async {
    AppSettings.openAppSettings();
  }

  Future<void> _loadOtpSecret() async {
    final storage = SecureStorage();
    final current = await storage.readOtpSecret();
    if (!mounted) return;
    setState(() {
      _otpSecret = current;
      _loadingOtpSecret = false;
    });
  }

  Future<bool> _isUnderGdpr() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt("IABTCF_gdprApplies") ?? 1) == 1;
  }

  Future<void> toggleNotifications(bool value) async {
    debugPrint("Toggling notifications");
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (value) {
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint("Notifications are enabled");
        setState(() {
          notificationsEnabled = true;
        });
        messaging.subscribeToTopic("all");
        messaging.subscribeToTopic("newGradeNotification");
        debugPrint("Subscribed to all topics");
        await prefs.setBool("notificationsEnabled", true);
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint(
            "Tried to enable notifications but they are disabled in system");
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Benachrichtigungen deaktiviert"),
              constraints: const BoxConstraints(
                maxWidth: 700,
              ),
              content: const Text(
                "Um Benachrichtigungen zu erhalten, musst du die Benachrichtigungen in den Einstellungen aktivieren.",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Später"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: const Text("Einstellungen öffnen"),
                )
              ],
            );
          },
        );
        await prefs.setBool("notificationsEnabled", false);
        debugPrint("Notifications are disabled in system");
      }
    } else {
      debugPrint("Notifications were disabled");
      setState(() {
        notificationsEnabled = false;
      });
      messaging.unsubscribeFromTopic("all");
      messaging.unsubscribeFromTopic("newGradeNotification");
      debugPrint("Unsubscribed from all topics");
      await prefs.setBool("notificationsEnabled", false);
    }
    debugPrint("Done toggling notifications");
  }

  Future<void> _openOtpSetup() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OtpSetupSheet(existingSecret: _otpSecret),
    );

    if (result == null) return;

    if (OtpHelper.generateTotp(result) == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Ungültiger 2-Faktor Schlüssel. Bitte erneut scannen.')),
      );
      return;
    }

    final storage = SecureStorage();
    await storage.saveOtpSecret(result);
    if (!mounted) return;
    setState(() {
      _otpSecret = result;
    });
    _setOtpAutofillUserProperty(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              '2-Faktor Schlüssel gespeichert. Notely füllt deinen Code nun automatisch aus.')),
    );
  }

  Future<void> _removeOtpSecret() async {
    final storage = SecureStorage();
    await storage.clearOtpSecret();
    if (!mounted) return;
    setState(() {
      _otpSecret = null;
    });
    _setOtpAutofillUserProperty(false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              '2-Faktor Schlüssel entfernt. Du musst den Code wieder manuell eingeben.')),
    );
  }

  Future<void> _clearAnalyticsUserProperties() async {
    await FirebaseAnalytics.instance.setUserProperty(
      name: 'otp_autofill_enabled',
      value: null,
    );

    await FirebaseAnalytics.instance.setUserProperty(
      name: 'school',
      value: null,
    );

    await FirebaseAnalytics.instance.setUserId(id: null);
  }

  Future<void> _setOtpAutofillUserProperty(bool enabled) async {
    try {
      await FirebaseAnalytics.instance.setUserProperty(
        name: 'otp_autofill_enabled',
        value: enabled ? 'true' : 'false',
      );
    } catch (e) {
      debugPrint('Failed to set otp_autofill_enabled user property: $e');
    }
  }

  void logout() async {
    try {
      await SecureStorage().deleteAll();
    } catch (e) {
      debugPrint('Error clearing storage during logout: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("school");
    await _clearAnalyticsUserProperties();
    if (!mounted) return;

    Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          alignment: Alignment.bottomCenter,
          child: const LoginPage(),
        ));
  }

  void changeAppIcon() {
    if (Platform.isIOS) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ChangeAppIconSheet(),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("App-Icon ändern"),
            content: const Text(
              "Um das App-Icon zu ändern, musst du die App aus dem Homescreen entfernen und neu installieren.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Später"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  launchUrl(Uri.parse(
                      "https://play.google.com/store/apps/details?id=de.notely.app"));
                },
                child: const Text("App öffnen"),
              )
            ],
          );
        },
      );
    }
  }

  @override
  void initState() {
    SharedPreferences.getInstance().then((value) {
      setState(() {
        notificationsEnabled = value.getBool("notificationsEnabled") ?? false;
      });
    });

    _future = _isUnderGdpr();
    _loadOtpSecret();

    super.initState();
  }

  Future<void> enableDarkMode(bool dark) async {
    Globals().isDark = dark;
    if (dark) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: const Color(0xFF0d0d0d), // status bar color
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark // this one for iOS
          ));
      ThemeProvider.controllerOf(context).setTheme("dark_theme");
    } else {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
          statusBarColor:
              Colors.white.withValues(alpha: 0.2), // status bar color
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light // this one for iOS
          ));
      ThemeProvider.controllerOf(context).setTheme("light_theme");
    }
  }

  Future<void> _testTokenRefresh() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headlineStyle = theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyMedium?.color) ??
        const TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w600,
        );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        children: [
          Text(
            "Einstellungen",
            style: headlineStyle,
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: "Darstellung",
            children: [
              _SettingsTile(
                icon: ThemeProvider.themeOf(context).id == "dark_theme"
                    ? CupertinoIcons.moon_stars_fill
                    : CupertinoIcons.sun_max_fill,
                accentColor: ThemeProvider.themeOf(context).id == "dark_theme"
                    ? Colors.blueAccent
                    : Colors.amberAccent,
                title: "Light/Dark-Mode",
                trailing: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchOutCurve: Curves.easeInCubic,
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    key: ValueKey(
                      ThemeProvider.themeOf(context).id == "dark_theme",
                    ),
                    padding: const EdgeInsets.only(right: 4),
                  ),
                ),
                onTap: () {
                  enableDarkMode(
                    !(ThemeProvider.themeOf(context).id == "dark_theme"),
                  );
                },
              ),
              if (Platform.isIOS)
                _SettingsTile(
                  icon: CupertinoIcons.app_fill,
                  accentColor: Colors.indigoAccent,
                  title: "App Icon",
                  trailing: const Icon(
                    CupertinoIcons.chevron_right,
                    size: 20,
                  ),
                  onTap: changeAppIcon,
                ),
            ],
          ),
          !kIsWeb
              ? _buildSection(
                  title: "Mitteilungen",
                  children: [
                    _SettingsTile(
                      icon: CupertinoIcons.bell_fill,
                      accentColor: Colors.pinkAccent,
                      title: "Benachrichtigungen",
                      subtitle: "Bei neuen Noten und Updates",
                      onTap: () {
                        toggleNotifications(!notificationsEnabled);
                      },
                      trailing: Platform.isIOS
                          ? CNSwitch(
                              value: notificationsEnabled,
                              onChanged: (value) {
                                toggleNotifications(value);
                              },
                            )
                          : Theme(
                              data: Theme.of(context).copyWith(
                                // ignore: deprecated_member_use
                                useMaterial3: true,
                              ),
                              child: Switch(
                                value: notificationsEnabled,
                                onChanged: (value) {
                                  toggleNotifications(value);
                                },
                              ),
                            ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
          _buildSection(
            title: "Sicherheit",
            children: [
              _TwoFactorTile(
                loading: _loadingOtpSecret,
                secret: _otpSecret,
                onSetup: _openOtpSetup,
                onRemove: _removeOtpSecret,
              ),
            ],
          ),
          if (false)
            _buildSection(
              title: "Notely Premium",
              children: [
                _SettingsTile(
                  icon: CupertinoIcons.star_fill,
                  accentColor: Colors.orangeAccent,
                  title: "Notely Premium",
                  subtitle: "Keine Werbung & mehr",
                  trailing: _isPresentingPremium
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CupertinoActivityIndicator(),
                        )
                      : const Icon(
                          CupertinoIcons.chevron_right,
                          size: 20,
                        ),
                  onTap: _presentNotelyPremiumPaywall,
                ),
              ],
            ),
          !kIsWeb
              ? FutureBuilder<bool>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data == true) {
                      return _buildSection(
                        title: "Privatsphäre",
                        children: [
                          _SettingsTile(
                            icon: CupertinoIcons.lock_shield_fill,
                            accentColor: Colors.tealAccent[700] ?? Colors.teal,
                            title: "Datenschutzeinstellungen",
                            subtitle: "Werbung und Tracking",
                            trailing: const Icon(
                              CupertinoIcons.chevron_right,
                              size: 20,
                            ),
                            onTap: () async {
                              final scaffoldMessenger =
                                  ScaffoldMessenger.of(context);
                              final didChangePreferences =
                                  await _initializationHelper
                                      .changePrivacyPreferences();
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    didChangePreferences
                                        ? 'Einstellungen aktualisiert'
                                        : 'Ein Fehler ist aufgetreten',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                )
              : const SizedBox.shrink(),
          _buildSection(
            title: "Support",
            children: [
              _SettingsTile(
                icon: CupertinoIcons.envelope_fill,
                accentColor: Colors.lightBlueAccent,
                title: "Support",
                subtitle: "thilo@notely.ch",
                trailing: const Icon(
                  CupertinoIcons.chevron_right,
                  size: 20,
                ),
                onTap: () {
                  final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'thilo@notely.ch',
                      query:
                          'subject=Notely Problem ${APIClient().school}&body=Dein Problem: ');
                  launchUrl(emailLaunchUri);
                },
              ),
              _SettingsTile(
                icon: CupertinoIcons.square_arrow_right_fill,
                accentColor: Colors.redAccent,
                title: "Abmelden",
                trailing: const Icon(
                  CupertinoIcons.chevron_right,
                  size: 20,
                ),
                onTap: logout,
              ),
              if (kDebugMode)
                _SettingsTile(
                  icon: CupertinoIcons.refresh_circled,
                  accentColor: Colors.purpleAccent,
                  title: "Token Refresh Test",
                  trailing: const Icon(
                    CupertinoIcons.chevron_right,
                    size: 20,
                  ),
                  onTap: _testTokenRefresh,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildVersionFooter(),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : theme.colorScheme.surface;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ) ??
                const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionFooter() {
    final mutedColor =
        Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7) ??
            const Color.fromRGBO(158, 158, 158, 1);

    return Center(
      child: Column(
        children: [
          FutureBuilder<PackageInfo>(
              future: _getPackageInfo(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    "${snapshot.data!.version} (${snapshot.data!.buildNumber})",
                    style: TextStyle(color: mutedColor),
                  );
                }
                return Text(
                  "0.0.0 (0)",
                  style: TextStyle(color: mutedColor),
                );
              }),
          const SizedBox(height: 4),
          Text(
            "${DateTime.now().year.toString()} © Thilo Jaeggi",
            style: TextStyle(color: mutedColor),
          ),
        ],
      ),
    );
  }
}

class OtpSetupSheet extends StatefulWidget {
  final String? existingSecret;

  const OtpSetupSheet({super.key, this.existingSecret});

  @override
  State<OtpSetupSheet> createState() => _OtpSetupSheetState();
}

class _OtpSetupSheetState extends State<OtpSetupSheet> {
  final MobileScannerController _controller = MobileScannerController();
  final TextEditingController _manualController = TextEditingController();
  bool _handling = false;
  String? _error;
  static const _twoFactorGuideUrl = 'https://notely.ch/2fa-anleitung';

  @override
  void initState() {
    super.initState();
    if (widget.existingSecret != null) {
      _manualController.text = widget.existingSecret!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _handleRawValue(String? value) async {
    if (_handling) return;

    final secret = value != null ? OtpHelper.extractSecret(value) : null;
    if (secret == null) {
      setState(() {
        _error = "Kein gültiger 2-Faktor Schlüssel erkannt.";
      });
      return;
    }

    setState(() {
      _handling = true;
      _error = null;
    });
    Navigator.of(context).pop(secret);
  }

  Future<void> _openTwoFactorGuide() async {
    final uri = Uri.parse(_twoFactorGuideUrl);
    if (!await launchUrl(uri)) {
      debugPrint('Could not open 2FA guide.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final helperStyle = CupertinoTheme.of(context).textTheme.textStyle.copyWith(
          fontSize: 14,
          color: CupertinoColors.systemGrey.resolveFrom(context),
        );
    final fieldBackground =
        CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoTheme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey4.resolveFrom(context),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "2-Faktor Schlüssel scannen",
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .navTitleTextStyle
                            .copyWith(fontSize: 22),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size.square(32.0),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 24,
                        color: CupertinoColors.systemGrey.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Scanne den QR-Code aus dem Kaschuso im Browser oder gib den geheimen Schlüssel manuell ein. Danach trägt Notely den 2-Faktor Code beim Login für dich ein.",
                  style: helperStyle,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _openTwoFactorGuide,
                    child: Text(
                      "Anleitung zur 2FA-Einrichtung öffnen",
                      style: helperStyle.copyWith(
                        fontSize: 18.0,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.25),
                        ),
                        color: theme.brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.02),
                      ),
                      child: MobileScanner(
                        controller: _controller,
                        onDetect: (capture) {
                          if (capture.barcodes.isEmpty) return;
                          final barcode = capture.barcodes.first;
                          _handleRawValue(barcode.rawValue);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "Oder Schlüssel eingeben",
                  style: helperStyle,
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: _manualController,
                  decoration: BoxDecoration(
                    color: fieldBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  placeholder: "otpauth:// oder geheimer Schlüssel",
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: _handleRawValue,
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      _error!,
                      style: helperStyle.copyWith(color: Colors.redAccent),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: fieldBackground,
                        onPressed: _handling
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(
                          "Abbrechen",
                          style: CupertinoTheme.of(context)
                              .textTheme
                              .textStyle
                              .copyWith(
                                color:
                                    CupertinoColors.label.resolveFrom(context),
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
                        onPressed: _handling
                            ? null
                            : () => _handleRawValue(_manualController.text),
                        child: _handling
                            ? const CupertinoActivityIndicator()
                            : const Text("Speichern"),
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

class _TwoFactorTile extends StatefulWidget {
  final bool loading;
  final String? secret;
  final VoidCallback? onSetup;
  final VoidCallback? onRemove;
  final int intervalSeconds;
  final String invalidLabel;

  const _TwoFactorTile({
    required this.loading,
    required this.secret,
    this.onSetup,
    this.onRemove,
    this.intervalSeconds = 30,
    this.invalidLabel = "Ungültiger Schlüssel",
  });

  @override
  State<_TwoFactorTile> createState() => _TwoFactorTileState();
}

class _TwoFactorTileState extends State<_TwoFactorTile> {
  Timer? _timer;
  String? _currentOtp;
  int _secondsRemaining = 30;
  bool _invalidSecret = false;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant _TwoFactorTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.secret != widget.secret ||
        oldWidget.loading != widget.loading) {
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (widget.loading || widget.secret == null) {
      setState(() {
        _currentOtp = null;
        _invalidSecret = false;
      });
      return;
    }

    void update() {
      if (!mounted || widget.secret == null) return;
      final now = DateTime.now().toUtc();
      final secondsIntoStep = now.second % widget.intervalSeconds;
      final remaining = widget.intervalSeconds - secondsIntoStep;
      final otp = OtpHelper.generateTotp(widget.secret!, now: now);
      if (otp == null) {
        setState(() {
          _invalidSecret = true;
          _currentOtp = null;
          _secondsRemaining = 0;
        });
        _timer?.cancel();
        return;
      }

      setState(() {
        _currentOtp = otp;
        _secondsRemaining = remaining;
        _invalidSecret = false;
      });
    }

    update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => update());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SettingsTile(
          icon: CupertinoIcons.lock_circle_fill,
          accentColor: Colors.tealAccent[700] ?? Colors.teal,
          title: "2-Faktor automatisch ausfüllen",
          subtitle: "QR/Schlüssel scannen – kein Code-Tippen mehr beim Login",
          trailing: widget.loading
              ? const CupertinoActivityIndicator()
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.secret != null) ...[
                      Text(
                        _invalidSecret
                            ? widget.invalidLabel
                            : (_currentOtp ?? "Lädt..."),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _invalidSecret ? "" : "${_secondsRemaining}s",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Icon(
                      CupertinoIcons.chevron_right,
                      size: 20,
                    ),
                  ],
                ),
          onTap: widget.loading ? null : widget.onSetup,
        ),
        if (widget.secret != null)
          _SettingsTile(
            icon: CupertinoIcons.delete_left_fill,
            accentColor: Colors.redAccent,
            title: "2-Faktor Schlüssel entfernen",
            subtitle: "Erneut scannen um ihn wieder zu setzen",
            trailing: const Icon(
              CupertinoIcons.chevron_right,
              size: 20,
            ),
            onTap: widget.onRemove,
          ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.accentColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color;
    final backgroundColor = accentColor.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.25 : 0.15);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: textColor?.withValues(alpha: 0.7),
                          ) ??
                          TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ]
          ],
        ),
      ),
    );
  }
}

class ChangeAppIconSheet extends StatefulWidget {
  const ChangeAppIconSheet({super.key});

  @override
  State<ChangeAppIconSheet> createState() => _ChangeAppIconSheetState();
}

class _ChangeAppIconSheetState extends State<ChangeAppIconSheet> {
  static const List<_IconOption> _iconOptions = [
    _IconOption(
      iconName: 'Classic',
      title: "Klassisch",
      description: "Das ursprüngliche Notely Symbol",
      assetPath: "assets/icons/icon-classic.png",
    ),
    _IconOption(
      iconName: 'Aktuell',
      title: "Modern",
      description: "Die moderne Variante",
      assetPath: "assets/icons/notely.png",
      isDefault: true,
    ),
  ];

  String? _currentIconName;
  String? _changingIcon;
  bool _loadingSelection = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentIcon();
  }

  Future<void> _loadCurrentIcon() async {
    try {
      final current = await FlutterDynamicIconPlus.alternateIconName;
      if (!mounted) return;
      setState(() {
        _currentIconName = current;
        _loadingSelection = false;
      });
    } catch (e) {
      debugPrint("Failed to load current icon: $e");
      if (!mounted) return;
      setState(() {
        _loadingSelection = false;
      });
    }
  }

  Future<void> _handleSelection(_IconOption option) async {
    if (_changingIcon != null) return;
    setState(() {
      _changingIcon = option.iconName;
    });

    final messenger = ScaffoldMessenger.maybeOf(context);
    bool changed = false;
    try {
      final supports = await FlutterDynamicIconPlus.supportsAlternateIcons;
      if (!supports) {
        messenger?.showSnackBar(
          const SnackBar(
            content:
                Text("Das Gerät unterstützt keine alternativen App-Icons."),
          ),
        );
        return;
      }

      await FlutterDynamicIconPlus.setAlternateIconName(
          iconName: option.iconName);
      changed = true;
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint("Exception while changing icon: $e");
      messenger?.showSnackBar(
        const SnackBar(
          content: Text("Icon konnte nicht geändert werden."),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _changingIcon = null;
          if (changed) {
            _currentIconName = option.iconName;
          }
        });
      }
    }
  }

  String _resolvedSelection() {
    final fallback = _iconOptions.firstWhere(
      (element) => element.isDefault,
      orElse: () => _iconOptions.first,
    );
    return _currentIconName ?? fallback.iconName;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = CupertinoTheme.of(context).scaffoldBackgroundColor;
    final fieldBackground =
        CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
    final helperStyle = CupertinoTheme.of(context).textTheme.textStyle.copyWith(
          fontSize: 14,
          color: CupertinoColors.systemGrey.resolveFrom(context),
        );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
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
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, -12),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          bottom: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey4.resolveFrom(context),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "App Icon ändern",
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .navTitleTextStyle
                            .copyWith(fontSize: 22),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size.square(32.0),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 24,
                        color: CupertinoColors.systemGrey.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Wähle dein bevorzugtes App-Icon",
                  style: helperStyle,
                ),
                const SizedBox(height: 18),
                if (_loadingSelection)
                  const Center(child: CupertinoActivityIndicator())
                else
                  ..._iconOptions.map(
                    (option) => _IconOptionTile(
                      option: option,
                      isSelected: _resolvedSelection() == option.iconName,
                      isLoading: _changingIcon == option.iconName,
                      backgroundColor: fieldBackground,
                      helperStyle: helperStyle,
                      onTap: () => _handleSelection(option),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconOption {
  final String iconName;
  final String title;
  final String description;
  final String assetPath;
  final bool isDefault;

  const _IconOption({
    required this.iconName,
    required this.title,
    required this.description,
    required this.assetPath,
    this.isDefault = false,
  });
}

class _IconOptionTile extends StatelessWidget {
  final _IconOption option;
  final bool isSelected;
  final bool isLoading;
  final Color backgroundColor;
  final TextStyle helperStyle;
  final VoidCallback onTap;

  const _IconOptionTile({
    required this.option,
    required this.isSelected,
    required this.isLoading,
    required this.backgroundColor,
    required this.helperStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isSelected
        ? Theme.of(context).primaryColor
        : isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.08);

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                option.assetPath,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.description,
                    style: helperStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isLoading)
              const CupertinoActivityIndicator()
            else if (isSelected)
              Icon(
                CupertinoIcons.check_mark_circled_solid,
                color: Theme.of(context).primaryColor,
              )
            else
              Icon(
                CupertinoIcons.circle,
                color: CupertinoColors.systemGrey3.resolveFrom(context),
              ),
          ],
        ),
      ),
    );
  }
}
