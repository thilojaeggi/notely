import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:notely/Globals.dart';
import 'package:notely/Models/Grade.dart';
import 'package:notely/helpers/api_client.dart';
import 'package:notely/pages/whatsnew_page.dart';
import 'package:notely/secure_storage.dart';
import 'package:notely/view_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:http/http.dart' as http;
import 'firebase_options.dart';
import 'config/CustomScrollBehavior.dart';
import 'config/style.dart';
import 'helpers/HomeworkDatabase.dart';
import 'pages/login_page.dart';

final storage = SecureStorage();
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final APIClient client = APIClient();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupFlutterNotifications();
  print('Handling a background message ${message.messageId}');
  if (message.contentAvailable ||
      message.from == "/topics/newGradeNotification") {
    final storage = SecureStorage();
    final prefs = await SharedPreferences.getInstance();
    // Get values fromm prefs and securestorage
    final school = prefs.getString("school") ?? "ksso";
    final username = await storage.read(key: "username") ?? '';
    final password = await storage.read(key: "password") ?? '';
    // Check if values are empty and exit if so
    if (username.isEmpty || password.isEmpty || school.isEmpty) return;
    // Get access token first
    final url = Globals.buildUrl("${school.toLowerCase()}/authorize.php");
    final response = await http.post(url, body: {
      'login': username,
      'passwort': password,
      'response_type': 'token',
      'client_id': 'cj79FSz1JQvZKpJY',
      'state': 'mipeZwvnUtB4bJWCsoXhGi7d8AyQT5698jSa9ixl',
    });
    if (response.statusCode == 302) {
      String locationHeader = response.headers['location'].toString().replaceAll(
          "#",
          "?"); // The URL somehow has a # instead of a ? to define get variables, just replacing it to later parse correctly.
      String accessToken =
          Uri.parse(locationHeader).queryParameters["access_token"].toString();
      client.accessToken = accessToken;
      client.school = school;
      try {
        List<Grade> oldGrades = await client.getGrades(true);
        List<Grade> newGrades = await client.getGrades(false);
        oldGrades.removeAt(1);

        if (newGrades.length <= oldGrades.length || oldGrades.isEmpty) return;
        for (Grade grade in newGrades) {
          if (!oldGrades.contains(grade)) {
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
                  iOS: DarwinNotificationDetails(
                    presentAlert: true,
                    presentBadge: true,
                    presentSound: true,
                  )),
            );
          }
        }
      } catch (e) {
        print(e.toString());
      }
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
  isFlutterLocalNotificationsInitialized = true;
}

late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  await HomeworkDatabase.instance.database;
  await checkNotifications(messaging);
  runApp(const Notely());
}

Future<void> checkNotifications(FirebaseMessaging messaging) async {
  print("Checking notifications");
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? notificationsEnabled = await prefs.getBool("notificationsEnabled");
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
      print("Notifications are enabled");
      messaging.subscribeToTopic("all");
      messaging.subscribeToTopic("newGradeNotification");
      await prefs.setBool("notificationsEnabled", true);
    } else if (notificationsEnabled == null ||
        settings.authorizationStatus == AuthorizationStatus.denied) {
      print("Notifications are disabled");
      try {
        messaging.unsubscribeFromTopic("all");
        messaging.unsubscribeFromTopic("newGradeNotification");
      } catch (e) {
        print(e.toString());
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
  if (username == "demo" && password == "demo") {
    client.fakeData = true;
    client.school = "demo";
    return true;
  }

  if (username.isEmpty || password.isEmpty || school.isEmpty) {
    return false;
  }

  print("Found login data");
  final url = Globals.buildUrl("$school/authorize.php");
  final response = await http.post(url, body: {
    'login': username,
    'passwort': password,
    'response_type': 'token',
    'client_id': 'cj79FSz1JQvZKpJY',
    'state': 'mipeZwvnUtB4bJWCsoXhGi7d8AyQT5698jSa9ixl',
  });
  if (response.statusCode == 302 && response.headers['location'] != null) {
    String locationHeader = response.headers['location'].toString().replaceAll(
        "#",
        "?"); // The URL somehow has a # instead of a ? to define get variables, just replacing it to later parse correctly.
    String accessToken =
        Uri.parse(locationHeader).queryParameters["access_token"].toString();
    client.accessToken = accessToken;
    client.school = school;
    print("Logged in");
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
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final InAppReview inAppReview = InAppReview.instance;

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

  Future<void> askForReview(BuildContext context) async {
    // Ask for review when the user has used the app for 5 times
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? appLaunches = prefs.getInt('appLaunches');
    if (appLaunches == null) {
      appLaunches = 0;
    }
    appLaunches++;
    print(appLaunches);

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
      Future.microtask(() => checkForUpdates(navigatorKey.currentContext!));
      Future.microtask(() => askForReview(navigatorKey.currentContext!));
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
            print("Dark theme");
            Globals().isDark = true;
            SystemChrome.setSystemUIOverlayStyle(
                SystemUiOverlayStyle.dark.copyWith(
                    statusBarColor: Color(0xFF0d0d0d), // status bar color
                    statusBarIconBrightness: Brightness.light,
                    statusBarBrightness: Brightness.dark // this one for iOS
                    ));
          } else {
            print("Light theme");
            Globals().isDark = false;
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark
                .copyWith(
                    statusBarColor:
                        Colors.white.withOpacity(0.2), // status bar color
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
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              Locale('de'),
            ],
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
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
                        Text(
                          "Melde an..",
                          style: TextStyle(fontSize: 32.0),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        LoadingAnimationWidget.waveDots(
                            color: Colors.white, size: 48),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Falls es länger Dauert überprüfe deine Internetverbindung.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18.0),
                        )
                      ],
                    )));
                  } else if (snapshot.hasError) {
                    return Material(
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
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
                      ? ScrollConfiguration(
                          child: const ViewContainerWidget(),
                          behavior: CustomScrollBehavior(),
                        )
                      : const LoginPage();
                }),
          ),
        ),
      ),
    );
  }
}
