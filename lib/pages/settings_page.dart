import 'package:day_night_switcher/day_night_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:page_transition/page_transition.dart';
import 'package:schulnetz/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  void enableDarkMode(bool dark) {
    if (dark) {
      ThemeProvider.controllerOf(context).setTheme("dark_theme");
    } else {
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
            GestureDetector(
              onTap: () {
                enableDarkMode(
                    !(ThemeProvider.themeOf(context).id == "dark_theme"));
              },
              child: Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Row(
                    children: [
                      const Text(
                        "Hell/Dark-Mode",
                        style: TextStyle(
                          fontSize: 23,
                        ),
                      ),
                      const Spacer(),
                      DayNightSwitcherIcon(
                        cloudsColor: Colors.transparent,
                        isDarkModeEnabled:
                            (ThemeProvider.themeOf(context).id == "dark_theme"),
                        onStateChanged: (isDarkModeEnabled) {
                          enableDarkMode(isDarkModeEnabled);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                const storage = FlutterSecureStorage();
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
              child: Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: const [
                      Text(
                        "Abmelden",
                        style: TextStyle(
                          fontSize: 23,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.logout,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      _packageInfo.version + " BLD" + _packageInfo.buildNumber,
                      style: TextStyle(color: Color.fromRGBO(158, 158, 158, 1)),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    child: const Text(
                      "2022 © Thilo Jaeggi",
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
