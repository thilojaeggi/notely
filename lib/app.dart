import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:notely/core/config/style.dart';
import 'package:notely/core/navigation/navigation_service.dart';
import 'package:notely/shell/initialize_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';

class NotelyApp extends StatefulWidget {
  const NotelyApp({Key? key}) : super(key: key);

  @override
  State<NotelyApp> createState() => _NotelyAppState();
}

class _NotelyAppState extends State<NotelyApp> {
  final InAppReview inAppReview = InAppReview.instance;

  Future<void> askForReview(BuildContext context) async {
    // Ask for review when the user has used the app for 5 times
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? appLaunches = prefs.getInt('appLaunches');
    appLaunches ??= 0;
    appLaunches++;
    debugPrint(appLaunches.toString());

    prefs.setInt('appLaunches', appLaunches);
    if (appLaunches == 10 && appLaunches != 0) {
      if (await inAppReview.isAvailable()) {
        inAppReview.requestReview();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(
          () => askForReview(NavigationService.navigatorKey.currentContext!));
    });
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      saveThemesOnChange: true,
      loadThemeOnInit: false,
      defaultThemeId: "dark_theme",
      onInitCallback: (controller, previouslySavedThemeFuture) async {
        String? savedTheme = await previouslySavedThemeFuture;

        if (savedTheme != null) {
          // If previous theme saved, use saved theme
          controller.setTheme(savedTheme);
          if (controller.theme.data.brightness == Brightness.dark) {
            debugPrint("Dark theme");
            SystemChrome.setSystemUIOverlayStyle(
                SystemUiOverlayStyle.dark.copyWith(
                    statusBarColor: const Color(0xFF0d0d0d), // status bar color
                    statusBarIconBrightness: Brightness.light,
                    statusBarBrightness: Brightness.dark // this one for iOS
                    ));
          } else {
            debugPrint("Light theme");
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark
                .copyWith(
                    statusBarColor:
                        Colors.white.withValues(alpha: 0.2), // status bar color
                    statusBarIconBrightness: Brightness.dark,
                    statusBarBrightness: Brightness.light // this one for iOS
                    ));
          }
        }
      },
      themes: [
        AppTheme(
            id: "dark_theme",
            data: Styles.themeData(true, context),
            description: "Dark"),
        AppTheme(
            id: "light_theme",
            data: Styles.themeData(false, context),
            description: "Light"),
      ],
      child: ThemeConsumer(
        child: Builder(
          builder: (themeContext) => MaterialApp(
            title: 'Notely',
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('de'),
            ],
            navigatorKey: NavigationService.navigatorKey,
            debugShowCheckedModeBanner: false,
            navigatorObservers: [
              FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
            ],
            theme: ThemeProvider.themeOf(themeContext).data,
            home: const InitializeScreen(),
            onUnknownRoute: (settings) => MaterialPageRoute(
              builder: (_) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
