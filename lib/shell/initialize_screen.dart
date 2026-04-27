import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:notely/features/ads/initialization_helper.dart';
import 'package:notely/features/subscription/subscription_manager.dart';
import 'package:notely/pages/whatsnew_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart';

class InitializeScreen extends StatefulWidget {
  final Widget targetWidget;

  const InitializeScreen({super.key, required this.targetWidget});

  @override
  State<InitializeScreen> createState() => _InitializeScreenState();
}

class _InitializeScreenState extends State<InitializeScreen> {
  final _initializationHelper = InitializationHelper();

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  @override
  Widget build(BuildContext context) => Material(
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

  Future<void> checkForUpdates(BuildContext context) async {
    // Get the current version code of the app
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    int currentVersionCode = int.parse(packageInfo.buildNumber);

    // Get the last version code of the app stored in SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lastVersionCode = prefs.getInt('version_code');

    String school = prefs.getString("school") ?? "";

    if (lastVersionCode == null ||
        lastVersionCode < currentVersionCode ||
        kDebugMode && WhatsNew.updates.isNotEmpty) {
      if (!mounted) return;

      final bool isFirstLaunchOn131 = lastVersionCode == null ||
          lastVersionCode < 33 || kDebugMode && WhatsNew.updates.isNotEmpty; // build number for 1.3.1

      // The app was updated, show a modal popup
      await showModalBottomSheet<void>(
          context: context,
          constraints: const BoxConstraints(
            maxWidth: 700,
          ),
          isScrollControlled: true,
          builder: (BuildContext context) {
            return WhatsNew(school: school);
          });
      prefs.setInt('version_code', currentVersionCode);

      // Show premium paywall on first launch of 1.3.1
      if (isFirstLaunchOn131) {
        SubscriptionManager().presentNotelyPremiumPaywall();
      }
    }
  }

  Future<void> _initialize() async {
    final navigator = Navigator.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!kIsWeb && !Platform.isMacOS) {
        await _initializationHelper.initialize();
      }
      Future.microtask(() => checkForUpdates(context));

      navigator.pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              widget.targetWidget,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }
}
