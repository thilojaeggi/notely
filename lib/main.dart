import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:notely/Globals.dart' as Globals;
import 'package:notely/view_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:http/http.dart' as http;

import 'config/CustomScrollBehavior.dart';
import 'config/style.dart';
import 'helpers/HomeworkDatabase.dart';
import 'pages/login_page.dart';

const storage = FlutterSecureStorage();
const fetchNotifications = "fetchNotifications";
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HomeworkDatabase.instance.database;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
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
