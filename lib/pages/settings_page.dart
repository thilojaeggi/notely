import 'dart:io';

import 'package:day_night_switcher/day_night_switcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:notely/Globals.dart';
import 'package:notely/helpers/HomeworkDatabase.dart';
import 'package:notely/helpers/api_client.dart';
import 'package:notely/secure_storage.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController targetGradeController = new TextEditingController();

  bool notificationsEnabled = false;

  Future<PackageInfo> _getPackageInfo() {
    return PackageInfo.fromPlatform();
  }

  void openAppSettings() async {
    if (await canLaunch('app-settings:')) {
      await launch('app-settings:');
    } else {
      throw 'Could not launch app settings';
    }
  }

  void toggleNotifications() async {
    print("Toggling notifications");

    // Check if firebase has ios permissions
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request notification permissions
    if (Platform.isIOS) {
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      print(settings.authorizationStatus);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        setState(() {
          notificationsEnabled = !notificationsEnabled;
        });
        if (notificationsEnabled) {
          FirebaseMessaging.instance.subscribeToTopic("all");
        } else {
          FirebaseMessaging.instance.unsubscribeFromTopic("all");
        }
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        // Show dialog message
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Benachrichtigungen deaktiviert"),
              content: Text(
                "Um Benachrichtigungen zu erhalten, musst du die Mitteilungen in den Einstellungen erlauben, danach kannst du es erneut versuchen.",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Später"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: Text("Einstellungen öffnen"),
                )
              ],
            );
          },
        );
      }
    } else {
      setState(() {
        notificationsEnabled = !notificationsEnabled;
      });
      if (notificationsEnabled) {
        FirebaseMessaging.instance.subscribeToTopic("all");
      } else {
        FirebaseMessaging.instance.unsubscribeFromTopic("all");
      }
    }

    // Store value for later use
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("notificationsEnabled", notificationsEnabled);
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> enableDarkMode(bool dark) async {
    Globals().isDark = dark;
    if (dark) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Color(0xFF0d0d0d), // status bar color
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark // this one for iOS
          ));
      ThemeProvider.controllerOf(context).setTheme("dark_theme");
    } else {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.white.withOpacity(0.2), // status bar color
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light // this one for iOS
          ));
      ThemeProvider.controllerOf(context).setTheme("light_theme");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10.0),
              child: Text(
                "Einstellungen",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.start,
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                onTap: () {
                  enableDarkMode(
                      !(ThemeProvider.themeOf(context).id == "dark_theme"));
                },
                visualDensity: VisualDensity(vertical: 2),
                title: const Text(
                  "Light/Dark-Mode",
                  style: TextStyle(
                    fontSize: 23,
                  ),
                ),
                trailing: Padding(
                  padding: EdgeInsets.only(right: 3),
                  child: DayNightSwitcherIcon(
                    cloudsColor: Colors.transparent,
                    isDarkModeEnabled:
                        (ThemeProvider.themeOf(context).id == "dark_theme"),
                    onStateChanged: (isDarkModeEnabled) {
                      enableDarkMode(isDarkModeEnabled);
                    },
                  ),
                ),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                onTap: () {
                  toggleNotifications();
                },
                visualDensity: VisualDensity(vertical: 2),
                title: const Text(
                  "Benachrichtigungen",
                  style: TextStyle(
                    fontSize: 23,
                  ),
                ),
                trailing: (!Platform.isIOS)
                    ? Switch(
                        value: notificationsEnabled,
                        onChanged: (value) {
                          toggleNotifications();
                        },
                      )
                    : CupertinoSwitch(
                        value: notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            toggleNotifications();
                          });
                        }),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                onTap: () {
                  final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'thilo.jaeggi@ksso.ch',
                      query: 'subject=Notely Problem ' +
                          APIClient().school +
                          '&body=Dein Problem: ');
                  launchUrl(emailLaunchUri);
                },
                visualDensity: VisualDensity(vertical: 2),
                title: const Text(
                  "Support",
                  style: TextStyle(
                    fontSize: 23,
                  ),
                ),
                trailing: Icon(
                  Icons.mail,
                  size: 32,
                ),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                onTap: () async {
                  final storage = SecureStorage();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  await storage.deleteAll();
                  Navigator.pushReplacement(
                      context,
                      PageTransition(
                        type: PageTransitionType.fade,
                        duration: const Duration(milliseconds: 450),
                        alignment: Alignment.bottomCenter,
                        child: const LoginPage(),
                      ));
                },
                visualDensity: VisualDensity(vertical: 2),
                title: Text(
                  "Abmelden",
                  style: TextStyle(
                    fontSize: 23,
                  ),
                ),
                trailing: Icon(
                  Icons.logout,
                  size: 32,
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    child: FutureBuilder<PackageInfo>(
                        future: _getPackageInfo(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              (snapshot.data!.version) +
                                  " (" +
                                  snapshot.data!.buildNumber +
                                  ")",
                              style: TextStyle(
                                  color: Color.fromRGBO(158, 158, 158, 1)),
                            );
                          }
                          return Text("0.0.0 (0)");
                        }),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      "${DateTime.now().year.toString()} © Thilo Jaeggi",
                      style: TextStyle(color: Color.fromRGBO(158, 158, 158, 1)),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
