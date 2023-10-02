import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notely/helpers/initialization_helper.dart';
import 'package:notely/pages/whatsnew_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InitializeScreen extends StatefulWidget {
  final Widget targetWidget;

  const InitializeScreen({required this.targetWidget});

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
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
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
        kDebugMode) {
      if (!mounted) return;

      // The app was updated, show a modal popup
      showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (BuildContext context) {
            return WhatsNew(school: school);
          });
      prefs.setInt('version_code', currentVersionCode);
    }
  }

  Future<void> _initialize() async {
    final navigator = Navigator.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializationHelper.initialize();
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
