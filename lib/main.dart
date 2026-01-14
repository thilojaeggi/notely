import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:notely/Globals.dart';
import 'package:notely/helpers/initialize_screen.dart';
import 'package:notely/helpers/subscription_manager.dart';
import 'package:notely/models/grade.dart';
import 'package:notely/helpers/api_client.dart';
import 'package:notely/secure_storage.dart';
import 'package:notely/helpers/token_manager.dart';
import 'package:notely/view_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';

import 'firebase_options.dart';
import 'config/style.dart';
import 'helpers/homework_database.dart';
import 'pages/login_page.dart';
import 'helpers/navigation_service.dart';
import 'package:universal_io/universal_io.dart' show Platform;

final storage = SecureStorage();
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final APIClient client = APIClient();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  !kIsWeb ? await setupFlutterNotifications() : null;
  debugPrint('Handling a background message ${message.messageId}');
  if (message.contentAvailable ||
      message.from == "/topics/newGradeNotification") {
    final prefs = await SharedPreferences.getInstance();
    final school = (prefs.getString("school") ?? "ksso").toLowerCase();
    if (school.isEmpty) return;

    bool hasValidToken = false;
    final tokenManager = TokenManager();
    final accessToken = await tokenManager.getValidAccessToken(school);
    if (accessToken != null && accessToken.isNotEmpty) {
      client.accessToken = accessToken;
      hasValidToken = true;
    }

    if (!hasValidToken) return;
    client.school = school;
    try {
      List<Grade> oldGrades = await client.getGrades(true);
      List<Grade> newGrades = await client.getGrades(false);

      if (newGrades.length <= oldGrades.length || oldGrades.isEmpty) return;

      // Get grades that are in newGrades but not in oldGrades, not using contains cause it doesn't work -.-
      newGrades = newGrades.where((element) {
        return !oldGrades.any((oldGrade) => oldGrade.id == element.id);
      }).toList();

      for (Grade grade in newGrades) {
        // send notification
        flutterLocalNotificationsPlugin.show(
          grade.id.hashCode,
          "Notely",
          "Du hast eine neue ${grade.subject} Note.",
          NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: 'ic_stat_school',
                playSound: true,
                enableVibration: true,
                importance: Importance.high,
                priority: Priority.high,
                visibility: NotificationVisibility.public,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              )),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}

/// Create a [AndroidNotificationChannel] for heads up notifications
late AndroidNotificationChannel channel;

bool isFlutterLocalNotificationsInitialized = false;

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'newGradeNotification', // id
    'Benachrichtigung bei neuer Note.', // title
    description:
        'Wenn eine neue Note eingetragen wird, erhältst du eine Benachrichtigung.', // description
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Create an Android Notification Channel.
  ///
  /// We use this channel in the `AndroidManifest.xml` file to override the
  /// default FCM channel to enable heads up notifications.
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  FirebaseMessaging.instance.getToken().then((value) {
    debugPrint(value);
  });
  isFlutterLocalNotificationsInitialized = true;
}

late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isIOS) {
    HomeWidget.setAppGroupId('group.ch.thilojaeggi.notely');
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  if (!kIsWeb) {
    await HomeworkDatabase.instance.database;
    await checkNotifications(messaging);
  }

  await SubscriptionManager().initialize();
  await analytics.setAnalyticsCollectionEnabled(true);
  runApp(const Notely());
}

Future<void> initializeRevenueCat() async {
  // Platform-specific API keys
  String apiKey;
  if (Platform.isIOS) {
    apiKey = 'test_hszPmfjKYpnwtuEtEsgjXPyszkv';
  } else if (Platform.isAndroid) {
    apiKey = 'test_hszPmfjKYpnwtuEtEsgjXPyszkv';
  } else {
    throw UnsupportedError('Platform not supported');
  }

  await Purchases.configure(PurchasesConfiguration(apiKey));
}

Future<void> checkNotifications(FirebaseMessaging messaging) async {
  debugPrint("Checking notifications");
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? notificationsEnabled = prefs.getBool("notificationsEnabled");
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  if (!kIsWeb) {
    await setupFlutterNotifications();
  }
  if (notificationsEnabled == null || notificationsEnabled) {
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
      messaging.subscribeToTopic("all");
      messaging.subscribeToTopic("newGradeNotification");
      await prefs.setBool("notificationsEnabled", true);
    } else if (notificationsEnabled == null ||
        settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint("Notifications are disabled");
      try {
        messaging.unsubscribeFromTopic("all");
        messaging.unsubscribeFromTopic("newGradeNotification");
      } catch (e) {
        debugPrint(e.toString());
      }
      await prefs.setBool("notificationsEnabled", false);
    }
  }
}

Future<bool> login() async {
  final APIClient client = APIClient();
  final prefs = await SharedPreferences.getInstance();
  final school = prefs.getString("school")?.toLowerCase() ?? '';
  final username = await storage.read(key: "username") ?? '';
  final password = await storage.read(key: "password") ?? '';
  final tokenManager = TokenManager();

  if (username == "demo" && password == "demo") {
    client.fakeData = true;
    client.school = "demo";
    return true;
  }

  if (school.isEmpty) {
    return false;
  }

  // Use TokenManager to handle everything (cache, refresh, re-auth)
  final token = await tokenManager.getValidAccessToken(school);

  if (token != null && token.isNotEmpty) {
    client.accessToken = token;
    client.school = school;
    debugPrint("Logged in via TokenManager");
    return true;
  }

  return false;
}

class Notely extends StatefulWidget {
  const Notely({Key? key}) : super(key: key);

  @override
  State<Notely> createState() => _NotelyState();
}

class _NotelyState extends State<Notely> {
  late Future<bool> isLoggedIn;
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
    isLoggedIn = login();
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
            Globals().isDark = true;
            SystemChrome.setSystemUIOverlayStyle(
                SystemUiOverlayStyle.dark.copyWith(
                    statusBarColor: const Color(0xFF0d0d0d), // status bar color
                    statusBarIconBrightness: Brightness.light,
                    statusBarBrightness: Brightness.dark // this one for iOS
                    ));
          } else {
            debugPrint("Light theme");
            Globals().isDark = false;
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
            home: FutureBuilder<bool>(
                future: isLoggedIn,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Material(
                        child: Center(
                            child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Melde an..",
                          style: TextStyle(fontSize: 32.0),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        LoadingAnimationWidget.waveDots(
                            color: Colors.white, size: 48),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text(
                          "Falls es länger Dauert überprüfe deine Internetverbindung.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18.0),
                        )
                      ],
                    )));
                  } else if (snapshot.hasError) {
                    return const Material(
                      child: SafeArea(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error,
                                  size: 128,
                                ),
                                Text(
                                  "Error",
                                  style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "Versuche es später erneut oder überprüfe deine Internetverbindung.",
                                  style: TextStyle(fontSize: 18.0),
                                  textAlign: TextAlign.center,
                                ),
                              ]),
                        ),
                      ),
                    );
                  }
                  bool loggedIn = snapshot.data ?? false;

                  return loggedIn
                      ? const InitializeScreen(
                          targetWidget: ViewContainerWidget(),
                        )
                      : const LoginPage();
                }),
          ),
        ),
      ),
    );
  }
}
