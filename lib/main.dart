import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:Notely/config/Globals.dart';
import 'package:Notely/view_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:workmanager/workmanager.dart';

import 'Models/Grade.dart';
import 'config/CustomScrollBehavior.dart';
import 'config/style.dart';
import 'pages/login_page.dart';

const storage = FlutterSecureStorage();
const fetchNotifications = "fetchNotifications";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  if (Platform.isWindows) {
    await Window.initialize();
    await Window.setEffect(
      effect: WindowEffect.mica,
      dark: true,
    );
  }

  readSettings();
  runApp(const Notely());
}

Future<void> readSettings() async {
  if (await isLoggedIn()) {
    final prefs = await SharedPreferences.getInstance();
    gradeList = await prefs.getString("gradeList") ?? "[]";
  }
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
  void initState() {
    super.initState();
  }

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
