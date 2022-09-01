import 'dart:async';
import 'dart:io';

import 'package:Notely/config/Globals.dart' as Globals;
import 'package:Notely/view_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:http/http.dart' as http;

import 'config/CustomScrollBehavior.dart';
import 'config/style.dart';
import 'pages/login_page.dart';

const storage = FlutterSecureStorage();
const fetchNotifications = "fetchNotifications";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);

    var swAvailable = await AndroidWebViewFeature.isFeatureSupported(
        AndroidWebViewFeature.SERVICE_WORKER_BASIC_USAGE);
    var swInterceptAvailable = await AndroidWebViewFeature.isFeatureSupported(
        AndroidWebViewFeature.SERVICE_WORKER_SHOULD_INTERCEPT_REQUEST);

    if (swAvailable && swInterceptAvailable) {
      AndroidServiceWorkerController serviceWorkerController =
          AndroidServiceWorkerController.instance();

      await serviceWorkerController
          .setServiceWorkerClient(AndroidServiceWorkerClient(
        shouldInterceptRequest: (request) async {
          print(request);
          return null;
        },
      ));
    }
  }

  readSettings();
  runApp(const Notely());
}

Future<void> readSettings() async {
  final prefs = await SharedPreferences.getInstance();
  Globals.gradeList = await prefs.getString("gradeList") ?? "[]";
}

Future<bool> isLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  String school = await prefs.getString("school") ?? "".toLowerCase();
  String username = await storage.read(key: "username") ?? "";
  String password = await storage.read(key: "password") ?? "";
  bool isLoggedIn = false;
  if (username != "" && password != "" && school != "") {
    String url = Globals.apiBase +
        school.toLowerCase() +
        "/authorize.php?response_type=token&client_id=cj79FSz1JQvZKpJY&state=mipeZwvnUtB4bJWCsoXhGi7d8AyQT5698jSa9ixl";
    print(url);
    await http.post(Uri.parse(url), body: {
      "login": username,
      "passwort": password,
    }).then((response) async {
      print(response.statusCode);
      if (response.statusCode == 302 && response.headers['location'] != null) {
        String locationHeader = response.headers['location'].toString();
        var trimmedString =
            locationHeader.substring(0, locationHeader.indexOf('&'));
        trimmedString = trimmedString
            .substring(trimmedString.indexOf("#") + 1)
            .replaceAll("access_token=", "");
        Globals.accessToken = trimmedString;
        isLoggedIn = true;
      } else {
        isLoggedIn = false;
      }
    });
  }
  return isLoggedIn;
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
                    return Container(
                      child: Center(
                        child: Text(
                          "Melde an...\nFalls es länger dauert überprüfe deine Internetverbindung.",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                }),
          ),
        ),
      ),
    );
  }
}
