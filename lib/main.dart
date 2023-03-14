import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notely/Globals.dart' as Globals;
import 'package:notely/secure_storage.dart';
import 'package:notely/view_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'Models/Grade.dart';
import 'firebase_options.dart';
import 'config/CustomScrollBehavior.dart';
import 'config/style.dart';
import 'helpers/HomeworkDatabase.dart';
import 'pages/login_page.dart';

const oldStorage = FlutterSecureStorage();
final storage = SecureStorage();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HomeworkDatabase.instance.database;

  setUpNotifications();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  runApp(const Notely());
}

void migrateSecureStorage() async {
  final oldData = await oldStorage.readAll();
  if (oldData.isNotEmpty) {
    for (final entry in oldData.entries) {
      await storage.write(key: entry.key, value: entry.value);
    }
  }
}

void setUpNotifications() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: true,
    sound: true,
  );

  print('User granted permission: ${settings.authorizationStatus}');
  // Initialize the local notifications plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.initialize(
    InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_school')),
  );

  FirebaseMessaging.onBackgroundMessage(handleBackgroundNotifications);
}

@pragma('vm:entry-point')
Future<void> handleBackgroundNotifications(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  print(message.data["type"]);
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'generalNotification',
    'Generell',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );
  const DarwinNotificationDetails darwinPlatformChannelSpecifics =
      DarwinNotificationDetails(
    sound: 'default',
  );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(0, "Background triggered",
      "Background notif was triggered", platformChannelSpecifics);
  if (message.data["type"] == "general") {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'generalNotification',
      'Generell',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails(
      sound: 'default',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: darwinPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, message.notification!.title,
        message.notification!.body, platformChannelSpecifics);
  } else if (message.data["type"] == "getGrades") {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'newGradeNotification', 'Benachrichtigung bei neuer Note',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false);
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
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
        Uri.parse(Globals.apiBase +
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
            "${Globals.apiBase}${school.toLowerCase()}/rest/v1/me/grades";

        try {
          // If we got the access token get the grades from the api
          await http.get(Uri.parse(url), headers: {
            'Authorization': 'Bearer ' + accessToken,
          }).then((response) async {
            // If new grades are more than the old ones send a notification
            if (jsonDecode(response.body).length <=
                jsonDecode(prefs.getString("grades") ?? "[]").length) return;
            print("trying to send notif");
            await flutterLocalNotificationsPlugin.show(0, "Neue Note",
                "Es ist eine neue Note verfügbar!", platformChannelSpecifics);
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

Future<bool> login() async {
  final prefs = await SharedPreferences.getInstance();
  final school = prefs.getString("school")?.toLowerCase() ?? '';
  final username = await storage.read(key: "username") ?? '';
  final password = await storage.read(key: "password") ?? '';

  if (username.isEmpty || password.isEmpty || school.isEmpty) {
    return false;
  }
  print("Found login data");

  final url = '${Globals.apiBase}$school/authorize.php';
  final response = await http.post(Uri.parse(url), body: {
    'login': username,
    'passwort': password,
    'response_type': 'token',
    'client_id': 'cj79FSz1JQvZKpJY',
    'state': 'mipeZwvnUtB4bJWCsoXhGi7d8AyQT5698jSa9ixl',
  });

  if (response.statusCode == 302 && response.headers['location'] != null) {
    final locationHeader = response.headers['location'].toString();
    final trimmedString = locationHeader
        .substring(locationHeader.indexOf('#') + 1)
        .split('&')
        .firstWhere(
          (element) => element.startsWith('access_token='),
          orElse: () => '',
        )
        .replaceAll('access_token=', '');

    Globals.accessToken = trimmedString;
    Globals.school = school;
    print("Logged in");
    await FirebaseMessaging.instance.subscribeToTopic("newGradeNotification");
    return true;
  }

  await FirebaseMessaging.instance.unsubscribeFromTopic("newGradeNotification");
  return false;
}

class Notely extends StatefulWidget {
  const Notely({Key? key}) : super(key: key);

  @override
  State<Notely> createState() => _NotelyState();
}

class _NotelyState extends State<Notely> {
  late Future<bool> isLoggedIn;
  @override
  void initState() {
    super.initState();
    isLoggedIn = login();
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
            Globals.isDark = true;
            SystemChrome.setSystemUIOverlayStyle(
                SystemUiOverlayStyle.dark.copyWith(
                    statusBarColor: Color(0xFF0d0d0d), // status bar color
                    statusBarIconBrightness: Brightness.light,
                    statusBarBrightness: Brightness.dark // this one for iOS
                    ));
          } else {
            print("Light theme");
            Globals.isDark = false;
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
                        SpinKitDoubleBounce(
                          size: 50,
                          color: Colors.white,
                        ),
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
                    return const Center(
                      child: Text("Error, versuche es spter erneut!"),
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
