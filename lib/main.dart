import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:schulnetz/Globals.dart';
import 'package:schulnetz/login_page.dart';
import 'package:schulnetz/style.dart';
import 'package:schulnetz/view_container.dart';
import 'package:theme_provider/theme_provider.dart';

void main() => runApp(const Notely());

class Notely extends StatefulWidget {
  const Notely({Key? key}) : super(key: key);

  @override
  State<Notely> createState() => _NotelyState();
}

class _NotelyState extends State<Notely> {
  static const storage = FlutterSecureStorage();
  bool loggedIn = false;
  void checkIfLoggedIn() async {
    bool newState = (await storage.read(key: "username") != null &&
        (await storage.read(key: "password")) != null);
    setState(() {
      loggedIn = newState;
    });
  }

  //final connector = createPushConnector();

  @override
  initState() {
    super.initState();
    checkIfLoggedIn();
    /* if (Platform.isIOS) {
      connector.configure(
        onMessage: _onMessage,
      );
      connector.requestNotificationPermissions();
    }*/
  }
/*
  Future<void> _onMessage(RemoteMessage message) async {
    print(message.data.toString());
  }*/

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
