import 'dart:io';

import 'package:day_night_switcher/day_night_switcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dynamic_icon/flutter_dynamic_icon.dart';
import 'package:notely/Globals.dart';
import 'package:notely/helpers/api_client.dart';
import 'package:notely/secure_storage.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_page.dart';
import 'package:app_settings/app_settings.dart';

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
    AppSettings.openNotificationSettings();
  }

  Future<void> toggleNotifications(bool value) async {
    debugPrint("Toggling notifications");
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (value) {
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
        setState(() {
          notificationsEnabled = true;
        });
        messaging.subscribeToTopic("all");
        messaging.subscribeToTopic("newGradeNotification");
        print("Subscribed to all topics");
        await prefs.setBool("notificationsEnabled", true);
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print("Tried to enable notifications but they are disabled in system");
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Benachrichtigungen deaktiviert"),
              content: Text(
                "Um Benachrichtigungen zu erhalten, musst du die Benachrichtigungen in den Einstellungen aktivieren.",
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
        await prefs.setBool("notificationsEnabled", false);
        print("Notifications are disabled in system");
      }
    } else {
      print("Notifications were disabled");
      setState(() {
        notificationsEnabled = false;
      });
      messaging.unsubscribeFromTopic("all");
      messaging.unsubscribeFromTopic("newGradeNotification");
      print("Unsubscribed from all topics");
      await prefs.setBool("notificationsEnabled", false);
    }
    print("Done toggling notifications");
  }

  void logout() async {
    SecureStorage().deleteAll();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("school");
    Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          alignment: Alignment.bottomCenter,
          child: const LoginPage(),
        ));
  }

  void changeAppIcon() {
    if (Platform.isIOS) {
      showDialog(
        context: context,
        builder: (context) {
          return ChangeAppIconDialog();
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("App-Icon ändern"),
            content: Text(
              "Um das App-Icon zu ändern, musst du die App aus dem Homescreen entfernen und neu installieren.",
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
                  launch(
                      "https://play.google.com/store/apps/details?id=de.notely.app");
                },
                child: Text("App öffnen"),
              )
            ],
          );
        },
      );
    }
  }

  @override
  void initState() {
    SharedPreferences.getInstance().then((value) {
      setState(() {
        notificationsEnabled = value.getBool("notificationsEnabled") ?? false;
      });
    });

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
            Expanded(
              child: ListView(
                shrinkWrap: false,
                children: [
                  Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      onTap: () {
                        enableDarkMode(!(ThemeProvider.themeOf(context).id ==
                            "dark_theme"));
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
                              (ThemeProvider.themeOf(context).id ==
                                  "dark_theme"),
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
                        toggleNotifications(!notificationsEnabled);
                      },
                      visualDensity: VisualDensity(vertical: 2),
                      title: const Text(
                        "Benachrichtigungen",
                        style: TextStyle(
                          fontSize: 23,
                        ),
                      ),
                      subtitle: Text("Bei neuen Noten und Updates"),
                      trailing: (!Platform.isIOS)
                          ? Switch(
                              value: notificationsEnabled,
                              onChanged: (value) {
                                toggleNotifications(value);
                              },
                            )
                          : CupertinoSwitch(
                              value: notificationsEnabled,
                              onChanged: (value) {
                                toggleNotifications(value);
                              }),
                    ),
                  ),
                  (Platform.isIOS)
                      ? Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            onTap: changeAppIcon,
                            visualDensity: VisualDensity(vertical: 2),
                            title: const Text(
                              "App Icon ändern",
                              style: TextStyle(
                                fontSize: 23,
                              ),
                            ),
                            trailing: Icon(
                              Icons.image,
                              size: 32,
                            ),
                          ))
                      : SizedBox.shrink(),
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
                      onTap: logout,
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
                ],
              ),
            ),
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

class ChangeAppIconDialog extends StatefulWidget {
  const ChangeAppIconDialog({super.key});

  @override
  State<ChangeAppIconDialog> createState() => _ChangeAppIconDialogState();
}

class _ChangeAppIconDialogState extends State<ChangeAppIconDialog> {
  List iconName = <String>['Classic', 'Aktuell'];

  void changeAppIconCallback(int index) async {
    try {
      if (await FlutterDynamicIcon.supportsAlternateIcons) {
        await FlutterDynamicIcon.setAlternateIconName(iconName[index]);
        print("App icon change successful");
        Navigator.pop(context);
        return;
      }
    } catch (e) {
      print("Exception: ${e.toString()}");
    }
    print("Failed to change app icon ");
  }

  Widget buildIconTile(int index, String themeTxt, String imageName) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
      child: ListTile(
          onTap: () {
            changeAppIconCallback(index);
          },
          contentPadding: const EdgeInsets.only(left: 0.0, right: 0.0),
          leading: SizedBox(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.asset(
                imageName,
              ),
            ),
          ),
          title: Text(themeTxt, style: const TextStyle(fontSize: 25)),
        ),
      
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.only(left: 4.0, right: 4.0),
      buttonPadding: EdgeInsets.zero,
      actionsPadding: EdgeInsets.zero,
    
      titlePadding: EdgeInsets.only(left: 8.0, top: 8.0),
      insetPadding: EdgeInsets.zero,
      title: Text("App Icon ändern"),
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          
          children: [
            buildIconTile(0, "Klassisch", "assets/icons/icon-classic.png"),

            buildIconTile(1, "Aktuell", "assets/icons/notely.png"),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("Schliessen"),
        ),
      ],
    );
  }
}
