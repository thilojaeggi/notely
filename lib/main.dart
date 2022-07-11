import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:schulnetz/login_page.dart';
import 'package:schulnetz/style.dart';
import 'package:schulnetz/view_container.dart';
import 'package:theme_provider/theme_provider.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const storage = FlutterSecureStorage();
  bool loggedIn = false;
  void checkIfLoggedIn() async {
    bool newState = (await storage.read(key: "username") != null &&
        (await storage.read(key: "password")) != null);
    setState(() {
      loggedIn = newState;
    });
  }

  @override
  initState() {
    super.initState();
    checkIfLoggedIn();
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
            home: loggedIn ? const ViewContainerWidget() : const LoginPage(),
          ),
        ),
      ),
    );
  }
}
