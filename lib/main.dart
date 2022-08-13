import 'dart:async';
import 'dart:io';

import 'package:Notely/config/Globals.dart' as Globals;
import 'package:Notely/view_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';

import 'config/CustomScrollBehavior.dart';
import 'config/style.dart';
import 'pages/login_page.dart';

const storage = FlutterSecureStorage();
const fetchNotifications = "fetchNotifications";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    /*await Window.initialize();
    await Window.setEffect(
      effect: WindowEffect.mica,
      dark: true,
    );*/
  } else {
    MobileAds.instance.initialize();
  }
  readSettings();
  runApp(const Notely());
}

Future<void> readSettings() async {
  if (await isLoggedIn()) {
    final prefs = await SharedPreferences.getInstance();
    Globals.gradeList = await prefs.getString("gradeList") ?? "[]";
    String school = await prefs.getString("school") ?? "ksso";
    Globals.apiBase = Globals.apiBase + school.toLowerCase() + "/rest/v1";
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
      loadThemeOnInit: false,
      defaultThemeId: "dark_theme",
      onInitCallback: (controller, previouslySavedThemeFuture) async {
        String? savedTheme = await previouslySavedThemeFuture;

        if (savedTheme != null) {
          // If previous theme saved, use saved theme
          controller.setTheme(savedTheme);
          if (controller.theme.data.brightness == Brightness.dark) {
            print("Dark theme");
            SystemChrome.setSystemUIOverlayStyle(
                SystemUiOverlayStyle.dark.copyWith(
                    statusBarColor: Color(0xFF0d0d0d), // status bar color
                    statusBarIconBrightness: Brightness.light,
                    statusBarBrightness: Brightness.dark // this one for iOS
                    ));
          } else {
            print("Light theme");
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
