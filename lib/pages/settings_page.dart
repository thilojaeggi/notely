import 'package:day_night_switcher/day_night_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:notely/helpers/HomeworkDatabase.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Globals.dart' as Globals;
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController targetGradeController = new TextEditingController();

  Future<PackageInfo> _getPackageInfo() {
    return PackageInfo.fromPlatform();
  }

  Future<void> getTargetGrade() async {
    final prefs = await SharedPreferences.getInstance();
    double targetGrade = await prefs.getDouble("targetGrade") ?? 5.0;
    targetGradeController.text = targetGrade.toString();
  }

  Future<void> setTargetGrade(double grade) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("targetGrade", grade);
  }

  int dropdownValue = 5;
  final double maxInputValue = 6;

  @override
  void initState() {
    super.initState();
    getTargetGrade();
  }

  Future<void> enableDarkMode(bool dark) async {
    Globals.isDark = dark;
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
                        "Light/Dark-Mode",
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
              onTap: () {
                final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'thilo.jaeggi@ksso.ch',
                    query: 'subject=Notely Problem ' +
                        Globals.school +
                        '&body=Dein Problem: ');
                launchUrl(emailLaunchUri);
              },
              child: Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        "Support",
                        style: TextStyle(
                          fontSize: 23,
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Icon(Icons.mail),
                      )
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
                await HomeworkDatabase.instance.deleteAll();
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
                          return Text("");
                        }),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
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
