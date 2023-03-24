import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:notely/Globals.dart';
import 'package:notely/pages/whatsnew_page.dart';
import 'package:notely/secure_storage.dart';
import 'package:notely/view_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupFlutterNotifications();
  print('Handling a background message ${message.messageId}');
  RemoteNotification? notification = message.notification;
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
    await http.post(
        Uri.parse(Globals().apiBase +
            school.toLowerCase() +
            "/authorize.php?response_type=token&client_id=cj79FSz1JQvZKpJY&state=Yr9Q5dODCujQtTDCZyyYq9MbyECVTNgFha276guJ&redirect_uri=https://www.schul-netz.com/mobile/oauth-callback.html&id="),
        body: {
          "login": username,
          "passwort": password,
        }).then((response) async {
      if (response.statusCode == 302) {
        String locationHeader = response.headers['location'].toString();
        var accessToken =
            locationHeader.substring(0, locationHeader.indexOf('&'));
        accessToken = accessToken
            .substring(accessToken.indexOf("#") + 1)
            .replaceAll("access_token=", "");
        // Get grades from api
        String url =
            "${Globals().apiBase}${school.toLowerCase()}/rest/v1/me/grades";

        try {
          // If we got the access token get the grades from the api
          await http.get(Uri.parse(url), headers: {
            'Authorization': 'Bearer ' + accessToken,
          }).then((response) async {
            // If new grades are more than the old ones send a notification
            if (jsonDecode(response.body).length <=
                jsonDecode(prefs.getString("grades") ?? "[]").length) return;
            print("trying to send notif");
            flutterLocalNotificationsPlugin.show(
              notification.hashCode,
              "Notely",
              "Neue Note!",
              NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  channelDescription: channel.description,
                  icon: 'ic_stat_school',
                ),
              ),
            );
            // Store the new grade list as string in prefs for the next time we check
            await prefs.setString("grades", response.body);
          });
        } catch (e) {
          print(e.toString());
        }
      }
    });
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
  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // Print the Firebase Messaging token

  if (!kIsWeb) {
    await setupFlutterNotifications();
  }
  try {
    await messaging.subscribeToTopic("all");
  } catch (e) {
    print("Failed to subscribe to topic all with error: $e");
  }
  runApp(const Notely());
}

Future<bool> login() async {
  final prefs = await SharedPreferences.getInstance();
  final school = prefs.getString("school")?.toLowerCase() ?? '';
  final username = await storage.read(key: "username") ?? '';
  final password = await storage.read(key: "password") ?? '';

  if (username.isEmpty || password.isEmpty || school.isEmpty) {
    return false;
  }
  print("Found login data");

  final url = '${Globals().apiBase}$school/authorize.php';
  final response = await http.post(Uri.parse(url), body: {
    'login': username,
    'passwort': password,
    'response_type': 'token',
    'client_id': 'cj79FSz1JQvZKpJY',
    'state': 'mipeZwvnUtB4bJWCsoXhGi7d8AyQT5698jSa9ixl',
  });
  if (response.statusCode == 302 && response.headers['location'] != null) {
    String locationHeader = response.headers['location'].toString().replaceAll("#", "?"); // The URL somehow has a # instead of a ? to define get variables, just replacing it to later parse correctly.
    Globals().accessToken = Uri.parse(locationHeader).queryParameters["access_token"].toString();
    print(Globals().accessToken);
    Globals().school = school;
    print("Logged in");
    try {
     
        await FirebaseMessaging.instance
            .subscribeToTopic("newGradeNotification");
    } catch (e) {
      print("Error while subscribing to topic newGradeNotification: $e");
    }
    return true;
  }
 
    await FirebaseMessaging.instance
        .unsubscribeFromTopic("newGradeNotification");

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

  @override
  void initState() {
    super.initState();
    isLoggedIn = login();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() => checkForUpdates(navigatorKey.currentContext!));
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
                      child: const Center(
                        child: Text("Error, versuche es später erneut!"),
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
