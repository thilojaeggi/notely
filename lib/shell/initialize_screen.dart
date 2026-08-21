import 'package:app_install_date/app_install_date.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:notely/core/analytics/analytics_constants.dart';
import 'package:notely/features/ads/initialization_helper.dart';
import 'package:notely/features/auth/auth_result.dart';
import 'package:notely/features/auth/auth_service.dart';
import 'package:notely/features/subscription/subscription_manager.dart';
import 'package:notely/pages/login_page.dart';
import 'package:notely/pages/whatsnew_page.dart';
import 'package:notely/shell/view_container.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart';

class InitializeScreen extends StatefulWidget {
  final Widget? targetWidget;

  const InitializeScreen({super.key, this.targetWidget});

  @override
  State<InitializeScreen> createState() => _InitializeScreenState();
}

class _InitializeScreenState extends State<InitializeScreen> {
  final _initializationHelper = InitializationHelper();
  static const _deeplinkChannel = MethodChannel('ch.notely.app/deeplink');
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Material(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 96,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Verbindungsfehler",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Versuche es später erneut oder überprüfe deine Internetverbindung.",
                  style: TextStyle(fontSize: 16.0),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _hasError = false);
                    _initialize();
                  },
                  child: const Text("Erneut versuchen"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/notely.png',
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 24),
            LoadingAnimationWidget.waveDots(color: Colors.white, size: 48),
          ],
        ),
      ),
    );
  }

  Future<void> checkForUpdates() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    int currentVersionCode = int.parse(packageInfo.buildNumber);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lastVersionCode = prefs.getInt('version_code');
    String school = prefs.getString("school") ?? "";

    if (lastVersionCode == null ||
        lastVersionCode < currentVersionCode ||
        kDebugMode && WhatsNew.updates.isNotEmpty) {
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        constraints: const BoxConstraints(
          maxWidth: 700,
        ),
        isScrollControlled: true,
        builder: (BuildContext context) {
          return WhatsNew(school: school);
        },
      );
      prefs.setInt('version_code', currentVersionCode);
    }

    // Show paywall once for existing users (installed before today)
    await _showPaywallForExistingUsers(prefs);
  }

  Future<void> _showPaywallForExistingUsers(SharedPreferences prefs) async {
    if (SubscriptionManager().isPremium) return;
    if (prefs.getBool('has_seen_returning_paywall') == true) return;

    try {
      final installDate = await AppInstallDate().installDate;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final installDay =
          DateTime(installDate.year, installDate.month, installDate.day);

      if (installDay.isBefore(today)) {
        await SubscriptionManager().presentNotelyPremiumPaywall(
          source: PaywallSource.returningUser,
        );
      }
    } catch (e) {
      debugPrint('Failed to check install date: $e');
    }

    // Mark as shown regardless of outcome so we don't retry
    await prefs.setBool('has_seen_returning_paywall', true);
  }

  Future<void> _initialize() async {
    final navigator = Navigator.of(context);

    try {
      final authResult = await AuthService.login();

      if (!mounted) return;

      if (authResult == AuthResult.unauthenticated) {
        navigator.pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
          ),
        );
        return;
      }

      // User is authenticated or deferred: initialize app features concurrently
      if (!kIsWeb && !Platform.isMacOS) {
        await _initializationHelper.initialize();
      }
      await SubscriptionManager().initialize();

      // Check pending deep link to determine target tab immediately
      String? pendingDeepLink;
      int initialIndex = 0;
      try {
        pendingDeepLink =
            await _deeplinkChannel.invokeMethod<String?>('getPendingDeepLink');
        if (pendingDeepLink != null) {
          final uri = Uri.tryParse(pendingDeepLink);
          if (uri != null) {
            final target =
                uri.host.isNotEmpty ? uri.host : uri.path.replaceAll('/', '');
            if (target == 'timetable' || target == 'plan') {
              initialIndex = 1;
            } else if (target == 'grades' || target == 'noten') {
              initialIndex = 2;
            } else if (target == 'absences' || target == 'absenzen') {
              initialIndex = 3;
            } else if (target == 'settings' || target == 'einstellungen') {
              initialIndex = 4;
            }
          }
        }
      } catch (e) {
        debugPrint('Failed to fetch pending deep link during init: $e');
      }

      if (mounted) {
        checkForUpdates();
      }

      navigator.pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              widget.targetWidget ??
              ViewContainerWidget(
                initialIndex: initialIndex,
                initialDeepLink: pendingDeepLink,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }
}

