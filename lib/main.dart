import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:schulnetz/config/CustomScrollBehavior.dart';
import 'package:schulnetz/pages/login_page.dart';
import 'package:schulnetz/config/style.dart';
import 'package:schulnetz/view_container.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:workmanager/workmanager.dart';

const storage = FlutterSecureStorage();
const fetchNotifications = "fetchNotifications";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    Workmanager().registerPeriodicTask(
      "getNewGradesTask",
      "simplePeriodicTask",
      frequency: Duration(minutes: 15),
    );
  }
  runApp(const Notely());
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    FlutterLocalNotificationsPlugin flip =
        new FlutterLocalNotificationsPlugin();
    var android = new AndroidInitializationSettings('ic_stat_school');
    var IOS = new IOSInitializationSettings();
    var settings = new InitializationSettings(android: android, iOS: IOS);
    flip.initialize(settings);
    const storage = FlutterSecureStorage();

    if ((await storage.read(key: "username") != null &&
        (await storage.read(key: "password")) != null)) {
      _showNotificationWithDefaultSound(flip);
    }

    return Future.value(true);
  });
}

Future _showNotificationWithDefaultSound(
    FlutterLocalNotificationsPlugin flip) async {
  // Show a notification after every 15 minute with the first
  // appearance happening a minute after invoking the method
  var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      'Neue Noten', 'Benachrichtigung bei einer neuen Note',
      importance: Importance.max, priority: Priority.high);
  var iOSPlatformChannelSpecifics = new IOSNotificationDetails();

  // initialise channel platform for both Android and iOS device.
  var platformChannelSpecifics = new NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics);
  await flip.show(Random.secure().nextInt(10), 'Neue Note',
      'Es gibt eine neue Note', platformChannelSpecifics,
      payload: 'Default_Sound');
}

Future<bool> isLoggedIn() async {
  return (await storage.read(key: "username") != null &&
      (await storage.read(key: "password")) != null);
}

class Notely extends StatefulWidget {
  const Notely({Key? key}) : super(key: key);

  @override
  State<Notely> createState() => _NotelyState();
}

class _NotelyState extends State<Notely> {
  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      saveThemesOnChange: true,
      loadThemeOnInit: true,
      defaultThemeId: "dark_theme",
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
                future: isLoggedIn(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return snapshot.data ?? false
                        ? ScrollConfiguration(
                            child: const ViewContainerWidget(),
                            behavior: CustomScrollBehavior(),
                          )
                        : const LoginPage();
                  } else {
                    return SizedBox.shrink();
                  }
                }),
          ),
        ),
      ),
    );
  }
}
